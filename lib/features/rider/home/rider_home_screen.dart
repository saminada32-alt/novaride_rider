import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import '../../../core/services/rider_socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:novaride_rider/core/services/rider_socket_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/default_location.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/widgets/legal_consent_dialog.dart';
import '../../../core/widgets/a11y.dart';
import '../../../core/utils/map_icons.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';
import '../rides/schedule_ride_screen.dart';
import '../surge_map/surge_map_screen.dart';
import '../account/upcoming_trips/upcoming_trips_screen.dart';
import '../payments/sham_cash_sheet.dart';
import '../widgets/ride_rating_sheet.dart';
import '../chat/ride_chat_screen.dart';
import '../services/ride_safety_service.dart';
import 'ride_safety_sheet.dart';
import 'rider_request_sheet.dart';
import 'rider_menu_sheet.dart';
import 'rider_vehicle_options.dart';
import 'rider_catalog_service.dart';
import 'widgets/active_ride_bottom_sheet.dart';
import 'widgets/active_ride_ui.dart';
import 'widgets/retry_ride_banner.dart';
import 'widgets/rider_bottom_panel.dart';
import 'widgets/rider_map_top_button.dart';
import 'widgets/scheduled_ride_bar.dart';

// ─────────────────────────────────────────────────────────────
class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});
  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? _mapController;

  LatLng? _currentPosition;
  LatLng? _driverPosition;

  String _selectedVehicle = 'car';
  List<VehicleOption> _vehicles = riderHomeVehicleOptions;
  RideModel? _activeRide;
  RideModel? _scheduledRide;
  RideModel? _retryableRide;
  bool _retryingSearch = false;
  bool _mapReady = false;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routeCoords = [];
  Timer? _directionsTimer;
  Timer? _nearbyTimer;
  Timer? _safetyTimer;
  int _safetyTicks = 0;
  double _localSurge = 1.0;
  String? _localSurgeLabel;
  bool _fetchingDirections = false;
  BitmapDescriptor? _carIcon;
  double _driverBearing = 0;
  List<Map<String, dynamic>> _nearbyDrivers = [];
  int? _joinedTripId;
  bool _audioRecording = false;
  final DraggableScrollableController _activeSheetController =
      DraggableScrollableController();
  final DraggableScrollableController _homeSheetController =
      DraggableScrollableController();
  double _homeSheetSize = 0.22;

  // Poll active ride
  Timer? _pollTimer;
  Timer? _scheduledPollTimer;
  final Set<int> _ratingShownFor = {};

  // Animations
  late AnimationController _bottomCtrl;
  late Animation<Offset> _bottomSlide;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (AppDefaultLocation.pinToDamascus) {
      _currentPosition = AppDefaultLocation.damascus;
    }
    _initLocation();
    _checkActiveRide();
    Future.microtask(_checkRetryableRides);
    _loadMapIcons();
    _refreshLocalSurge();
    RiderCatalogService.instance.ensureLoaded().then((_) {
      if (!mounted) return;
      setState(() => _vehicles = RiderCatalogService.instance.vehicles);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showLegalConsentDialogIfNeeded(context);
    });
    _nearbyTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_activeRide == null) _loadNearbyDrivers();
      _refreshLocalSurge();
    });

    _homeSheetController.addListener(_onHomeSheetSizeChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_activeRide == null) _loadNearbyDrivers();
    });

    RiderSocketService.instance.connect();
    RiderSocketService.instance.onTripEvent = (data) {
      if (!mounted) return;

      // Direct payload from ride_assigned
      if (data['id'] != null && data['status'] != null) {
        try {
          final ride = RideModel.fromJson(data);
          if (ride.isUpcomingScheduled) {
            setState(() => _scheduledRide = ride);
            _startScheduledWatch();
            return;
          }
          if (!ride.isLiveTrip) return;
          _joinedTripId = ride.id;
          RiderSocketService.instance.joinTrip(ride.id);
          setState(() => _activeRide = ride);
          _rebuildMapOverlays(refitCamera: true);
          _startPolling();
          _startSafetyTracking();
          return;
        } catch (e) {
          debugPrint('WS ride parse error: $e');
        }
      }

      // ride_status_changed / ride_cancelled
      if (data['_type'] == 'status_change') {
        final status = data['status']?.toString().toUpperCase() ?? '';
        final rideId = (data['id'] ?? data['rideId']) as int?;

        if (status == 'COMPLETED' && rideId != null) {
          _resetAfterRide(rideId: rideId);
          _onRideCompleted(rideId);
          _checkActiveRide();
        } else if (status == 'CANCELLED') {
          _resetAfterRide(rideId: rideId);
          final local = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(local.rideNoLongerActive),
              backgroundColor: Colors.orange,
            ),
          );
          _checkActiveRide();
        } else if (status == 'SEARCHING' && rideId != null) {
          _joinedTripId = rideId;
          RiderSocketService.instance.joinTrip(rideId);
          _refreshActiveRide();
          final local = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(local.scheduledRideActivated)),
          );
        } else {
          _refreshActiveRide();
        }
      }
    };

    // تحديث موقع السائق — فقط أثناء رحلة نشطة
    RiderSocketService.instance.onDriverMoved = (lat, lng) {
      if (!mounted || _activeRide == null) return;
      final next = LatLng(lat, lng);
      if (_driverPosition != null) {
        _driverBearing = MapIcons.bearing(_driverPosition!, next);
      }
      setState(() => _driverPosition = next);
      _rebuildMapOverlays();
      _scheduleDirectionsFetch();
    };

    _bottomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _bottomSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bottomCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // _initLocation();
    //_checkActiveRide();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveRide();
    }
  }

  void _onHomeSheetSizeChanged() {
    if (!_homeSheetController.isAttached || !mounted) return;
    final next = _homeSheetController.size;
    if ((next - _homeSheetSize).abs() < 0.01) return;
    setState(() => _homeSheetSize = next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    RiderSocketService.instance.disconnect();
    RiderSocketService.instance.onTripEvent = null;
    RiderSocketService.instance.onDriverMoved = null;

    _bottomCtrl.dispose();
    _pulseCtrl.dispose();
    _pollTimer?.cancel();
    _scheduledPollTimer?.cancel();
    _directionsTimer?.cancel();
    _nearbyTimer?.cancel();
    _safetyTimer?.cancel();
    _homeSheetController.removeListener(_onHomeSheetSizeChanged);
    _homeSheetController.dispose();
    _activeSheetController.dispose();
    super.dispose();
  }

  void _startSafetyTracking() {
    _safetyTimer?.cancel();
    _safetyTicks = 0;
    _safetyTimer = Timer.periodic(const Duration(seconds: 25), (_) async {
      if (!mounted || _activeRide == null) return;
      final rideId = _activeRide!.id;
      final pos = await RideSafetyService.instance.currentPosition();
      if (pos == null) return;

      await RideSafetyService.instance.appendTrail(
        rideId,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      _safetyTicks++;
      if (_safetyTicks % 3 == 0) {
        await RideSafetyService.instance.pingShareLocation(
          rideId,
          lat: pos.latitude,
          lng: pos.longitude,
        );
      }
    });
  }

  void _stopSafetyTracking() {
    _safetyTimer?.cancel();
    _safetyTicks = 0;
  }

  void _startScheduledWatch() {
    _scheduledPollTimer?.cancel();
    if (_scheduledRide == null) return;
    _scheduledPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || _activeRide != null) {
        _scheduledPollTimer?.cancel();
        return;
      }
      _checkActiveRide();
    });
  }

  String _fmtScheduledAt(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}  ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _loadMapIcons() async {
    try {
      final icon = await MapIcons.car();
      if (!mounted) return;
      setState(() => _carIcon = icon);
      if (_activeRide == null) _applyIdleMapMarkers();
    } catch (_) {}
  }

  /// تنظيف كامل بعد انتهاء/إلغاء الرحلة — يمنع تعليق الخريطة
  void _resetAfterRide({int? rideId}) {
    final tripId = rideId ?? _joinedTripId ?? _activeRide?.id;

    _pollTimer?.cancel();
    _directionsTimer?.cancel();
    _stopSafetyTracking();
    _fetchingDirections = false;

    if (tripId != null) {
      RiderSocketService.instance.leaveTrip(tripId);
    }
    _joinedTripId = null;

    if (!mounted) return;

    setState(() {
      _activeRide = null;
      _driverPosition = null;
      _driverBearing = 0;
      _routeCoords = [];
      _polylines = {};
      _markers = {};
    });

    _loadNearbyDrivers();
    _recenter();
    if (!_bottomCtrl.isCompleted) {
      _bottomCtrl.forward(from: 0);
    }
  }

  /// مزامنة حالة الرحلة من الـ API (مصدر واحد للحقيقة).
  void _applyRidesFromServer(List<RideModel> rides, {bool refitOnNewLive = false}) {
    final live = rides.where((r) => r.isLiveTrip).toList();
    final upcoming = rides.where((r) => r.isUpcomingScheduled).toList()
      ..sort(
        (a, b) => (a.scheduledAt ?? a.createdAt ?? DateTime(0)).compareTo(
          b.scheduledAt ?? b.createdAt ?? DateTime(0),
        ),
      );
    final nextScheduled = upcoming.isNotEmpty ? upcoming.first : null;

    if (live.isNotEmpty) {
      final ride = live.first;
      final changed = _activeRide?.id != ride.id;
      _syncDriverPositionFromRide(ride);
      _joinActiveTrip(ride.id);
      setState(() {
        _activeRide = ride;
        _scheduledRide = nextScheduled;
      });
      _rebuildMapOverlays(refitCamera: refitOnNewLive && changed);
      if (changed) _scheduleDirectionsFetch();
      _startPolling();
      _startSafetyTracking();
      _scheduledPollTimer?.cancel();
      return;
    }

    if (_activeRide != null) {
      _resetAfterRide();
    }

    setState(() => _scheduledRide = nextScheduled);

    if (nextScheduled != null) {
      _startScheduledWatch();
    } else {
      _scheduledPollTimer?.cancel();
    }
  }

  void _joinActiveTrip(int tripId) {
    _joinedTripId = tripId;
    RiderSocketService.instance.joinTrip(tripId);
  }

  void _syncDriverPositionFromRide(RideModel ride) {
    final d = ride.driver;
    if (d == null) return;
    final lat = double.tryParse(d['currentLat']?.toString() ?? '');
    final lng = double.tryParse(d['currentLng']?.toString() ?? '');
    if (lat == null || lng == null) return;
    final next = LatLng(lat, lng);
    if (_driverPosition != null) {
      _driverBearing = MapIcons.bearing(_driverPosition!, next);
    }
    _driverPosition = next;
  }

  Polyline _buildRoutePolyline(List<LatLng> points, {required bool toDropoff}) {
    return Polyline(
      polylineId: PolylineId(toDropoff ? 'rider_route_drop' : 'rider_route_pickup'),
      points: points,
      color: toDropoff ? const Color(0xFF1a1a2e) : const Color(0xFF2B2B2B),
      width: toDropoff ? 5 : 4,
      geodesic: true,
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  Future<void> _loadNearbyDrivers() async {
    if (_activeRide != null || _currentPosition == null) return;
    try {
      final list = await RiderService.instance.getNearbyDrivers(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        radiusKm: 8,
      );
      if (!mounted || _activeRide != null) return;
      final icon = _carIcon ?? BitmapDescriptor.defaultMarker;
      setState(() {
        _nearbyDrivers = list;
        _markers = {
          for (final d in list)
            Marker(
              markerId: MarkerId('nearby_${d['id']}'),
              position: LatLng(
                (d['lat'] as num).toDouble(),
                (d['lng'] as num).toDouble(),
              ),
              icon: icon,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              zIndex: 2,
              rotation: ((d['id'] as num).toInt() * 47) % 360,
            ),
        };
        _polylines = {};
        _routeCoords = [];
      });
    } catch (e) {
      debugPrint('nearby drivers: $e');
    }
  }

  void _applyIdleMapMarkers() {
    if (_activeRide != null || !mounted) return;
    final icon = _carIcon ?? BitmapDescriptor.defaultMarker;
    setState(() {
      _markers = {
        for (final d in _nearbyDrivers)
          Marker(
            markerId: MarkerId('nearby_${d['id']}'),
            position: LatLng(
              (d['lat'] as num).toDouble(),
              (d['lng'] as num).toDouble(),
            ),
            icon: icon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: ((d['id'] as num).toInt() * 47) % 360,
          ),
      };
      _polylines = {};
      _routeCoords = [];
    });
  }

  Future<void> _refreshLocalSurge() async {
    if (_currentPosition == null) return;
    try {
      final s = await RiderService.instance.getSurgeAt(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
      if (!mounted) return;
      setState(() {
        _localSurge = (s['surgeMultiplier'] as num?)?.toDouble() ?? 1.0;
        _localSurgeLabel = s['zone']?['labelAr']?.toString();
      });
    } catch (_) {}
  }

  void _rebuildMapOverlays({bool refitCamera = false}) {
    if (_activeRide == null) {
      _applyIdleMapMarkers();
      return;
    }

    final ride = _activeRide!;
    final pickup = LatLng(ride.pickupLat, ride.pickupLng);
    final dropoff = LatLng(ride.dropoffLat, ride.dropoffLng);
    final toDropoff = ride.headingToDropoff;
    final carIcon = _carIcon ?? BitmapDescriptor.defaultMarker;

    final markers = <Marker>{
      if (!toDropoff)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      if (toDropoff)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      if (_driverPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon: carIcon,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: _driverBearing,
          zIndex: 3,
        ),
    };

    final destination = toDropoff ? dropoff : pickup;
    final routePoints = _routeCoords.length >= 2
        ? _routeCoords
        : [
            ?_driverPosition,
            destination,
          ];

    setState(() {
      _markers = markers;
      _polylines = routePoints.length >= 2
          ? {_buildRoutePolyline(routePoints, toDropoff: toDropoff)}
          : {};
    });

    if (refitCamera) _fitCameraToActiveRide();
  }

  void _scheduleDirectionsFetch({bool immediate = false}) {
    if (_activeRide == null) return;
    _directionsTimer?.cancel();
    _directionsTimer = Timer(
      immediate ? Duration.zero : const Duration(seconds: 2),
      _fetchDirections,
    );
  }

  Future<void> _fetchDirections() async {
    if (_fetchingDirections || !mounted || _activeRide == null) return;

    final ride = _activeRide!;
    final pickup = LatLng(ride.pickupLat, ride.pickupLng);
    final dropoff = LatLng(ride.dropoffLat, ride.dropoffLng);
    final toDropoff = ride.headingToDropoff;
    final destination = toDropoff ? dropoff : pickup;

    if (_driverPosition == null) return;

    _fetchingDirections = true;
    try {
      final points = await DirectionsService.instance.routeBetween(
        _driverPosition!,
        destination,
      );
      if (!mounted) return;
      setState(() => _routeCoords = points);
      _rebuildMapOverlaysWithoutFetch();
    } finally {
      _fetchingDirections = false;
    }
  }

  void _fitCameraToActiveRide() {
    if (_mapController == null || _activeRide == null) return;
    final ride = _activeRide!;
    final pickup = LatLng(ride.pickupLat, ride.pickupLng);
    final dropoff = LatLng(ride.dropoffLat, ride.dropoffLng);
    final toDropoff = ride.headingToDropoff;
    final points = <LatLng>[
      ?_driverPosition,
      toDropoff ? dropoff : pickup,
    ];
    if (points.length < 2) return;
    try {
      var minLat = points.first.latitude;
      var maxLat = points.first.latitude;
      var minLng = points.first.longitude;
      var maxLng = points.first.longitude;
      for (final p in points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          100,
        ),
      );
    } catch (_) {}
  }

  void _rebuildMapOverlaysWithoutFetch() {
    if (_activeRide == null) return;
    final ride = _activeRide!;
    final pickup = LatLng(ride.pickupLat, ride.pickupLng);
    final dropoff = LatLng(ride.dropoffLat, ride.dropoffLng);
    final toDropoff = ride.headingToDropoff;
    final carIcon = _carIcon ?? BitmapDescriptor.defaultMarker;

    setState(() {
      _markers = {
        if (!toDropoff)
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickup,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        if (toDropoff)
          Marker(
            markerId: const MarkerId('dropoff'),
            position: dropoff,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        if (_driverPosition != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverPosition!,
            icon: carIcon,
            anchor: const Offset(0.5, 0.5),
            flat: true,
            rotation: _driverBearing,
            zIndex: 3,
          ),
      };
      final destination = toDropoff ? dropoff : pickup;
      final routePoints = _routeCoords.length >= 2
          ? _routeCoords
          : [
              ?_driverPosition,
              destination,
            ];
      _polylines = routePoints.length >= 2
          ? {_buildRoutePolyline(routePoints, toDropoff: toDropoff)}
          : {};
    });
  }

  Future<LatLng?> _ensureCurrentPosition({bool showErrors = true}) async {
    if (AppDefaultLocation.pinToDamascus) {
      final pos = _currentPosition ?? AppDefaultLocation.damascus;
      if (mounted && _currentPosition == null) {
        setState(() => _currentPosition = pos);
      }
      return pos;
    }

    if (_currentPosition != null) return _currentPosition;

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (showErrors && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.enableLocationPermission),
            ),
          );
        }
        return null;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (showErrors && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.enableLocationPermission),
            ),
          );
        }
        return null;
      }

      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final latLng = LatLng(pos.latitude, pos.longitude);
      if (!mounted) return latLng;
      setState(() => _currentPosition = latLng);
      _refreshLocalSurge();
      if (_activeRide == null) _loadNearbyDrivers();
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      return latLng;
    } catch (e) {
      debugPrint('ensureCurrentPosition: $e');
      if (showErrors && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unknownLocation)),
        );
      }
      return null;
    }
  }

  Future<void> _initLocation() async {
    if (AppDefaultLocation.pinToDamascus) {
      if (mounted) {
        setState(() => _currentPosition = AppDefaultLocation.damascus);
      }
      _refreshLocalSurge();
      if (_activeRide == null) _loadNearbyDrivers();
      return;
    }

    await _ensureCurrentPosition(showErrors: false);

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() => _currentPosition = LatLng(pos.latitude, pos.longitude));
      _refreshLocalSurge();
      if (_activeRide == null) _loadNearbyDrivers();
    });
  }

  Future<void> _refreshActiveRide() async {
    final rides = await RiderService.instance.getMyRides();
    if (!mounted) return;
    _applyRidesFromServer(rides);
  }

  Future<void> _checkActiveRide() async {
    final results = await Future.wait([
      RiderService.instance.getMyRides(),
      RiderService.instance.getScheduledRides(),
    ]);
    if (!mounted) return;
    final rides = results[0];
    final scheduled = results[1];
    _applyRidesFromServer(rides, refitOnNewLive: true);
    if (_activeRide == null) {
      setState(() => _scheduledRide = scheduled.isNotEmpty ? scheduled.first : null);
      if (_scheduledRide != null) _startScheduledWatch();
    }
  }

  Future<void> _checkRetryableRides() async {
    try {
      final list = await RiderService.instance.getRetryableRides();
      if (!mounted) return;
      setState(() => _retryableRide = list.isNotEmpty ? list.first : null);
    } catch (_) {}
  }

  Future<void> _retryRideSearch() async {
    final ride = _retryableRide;
    if (ride == null || _retryingSearch) return;
    setState(() => _retryingSearch = true);
    try {
      final updated = await RiderService.instance.retrySearch(ride.id);
      if (!mounted) return;
      setState(() {
        _retryableRide = null;
        _activeRide = updated;
      });
      _joinActiveTrip(updated.id);
      _startPolling();
      _rebuildMapOverlays(refitCamera: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _retryingSearch = false);
    }
  }

  // ─── Poll ride status every 5s ────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_activeRide == null || !mounted) {
        _pollTimer?.cancel();
        return;
      }
      final rides = await RiderService.instance.getMyRides();
      if (!mounted) return;
      final rideId = _activeRide!.id;
      final updated = rides.where((r) => r.id == rideId).toList();

      if (updated.isEmpty) {
        _pollTimer?.cancel();
        _resetAfterRide(rideId: rideId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.rideNoLongerActive)),
          );
        }
        await _checkActiveRide();
        return;
      }

      final ride = updated.first;
      if (ride.isTerminal) {
        _pollTimer?.cancel();
        _resetAfterRide(rideId: ride.id);
        if (ride.status == RideStatus.completed) {
          _onRideCompleted(ride.id);
        } else if (ride.status == RideStatus.no_driver_found &&
            ride.canRetrySearch) {
          setState(() => _retryableRide = ride);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.noDriverFoundRetry),
                action: SnackBarAction(
                  label: AppLocalizations.of(context)!.retry,
                  onPressed: _retryRideSearch,
                ),
              ),
            );
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.rideNoLongerActive),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _checkRetryableRides();
        await _checkActiveRide();
        return;
      }

      if (!ride.isLiveTrip) {
        _pollTimer?.cancel();
        _resetAfterRide(rideId: ride.id);
        await _checkActiveRide();
        return;
      }

      _syncDriverPositionFromRide(ride);
      try {
        final live = await RiderService.instance.getLiveRide(rideId);
        if (mounted) _applyLiveDriverPosition(live);
      } catch (_) {}
      if (!mounted) return;
      final refit = _activeRide?.status != ride.status;
      setState(() => _activeRide = ride);
      _rebuildMapOverlays(refitCamera: refit);
      if (refit) _scheduleDirectionsFetch(immediate: true);
    });
  }

  void _applyLiveDriverPosition(Map<String, dynamic> live) {
    final d = live['driver'];
    if (d is! Map) return;
    final lat = double.tryParse(d['lat']?.toString() ?? '');
    final lng = double.tryParse(d['lng']?.toString() ?? '');
    if (lat == null || lng == null) return;
    final next = LatLng(lat, lng);
    if (_driverPosition != null) {
      _driverBearing = MapIcons.bearing(_driverPosition!, next);
    }
    _driverPosition = next;
    if (live['etaMinutes'] != null && _activeRide != null) {
      // ETA refreshed from traffic-aware backend
    }
  }

  Future<void> _recenter() async {
    if (_activeRide != null) {
      _fitCameraToActiveRide();
      return;
    }
    final pos = await _ensureCurrentPosition(showErrors: true);
    if (pos != null && _mapController != null) {
      await _mapController!.animateCamera(CameraUpdate.newLatLngZoom(pos, 16));
    }
  }

  Future<void> _openRideSheet() async {
    HapticFeedback.mediumImpact();

    if (_currentPosition == null) {
      await _ensureCurrentPosition(showErrors: !AppDefaultLocation.pinToDamascus);
    }
    if (!mounted || _currentPosition == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.34,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        expand: false,
        builder: (_, scrollController) => RiderRequestSheet(
          scrollController: scrollController,
          currentLocation: _currentPosition,
          selectedVehicle: _selectedVehicle,
          onVehicleChanged: (v) => setState(() => _selectedVehicle = v),
          onRideCreated: (ride) {
            _joinActiveTrip(ride.id);
            setState(() => _activeRide = ride);
            _rebuildMapOverlays(refitCamera: true);
            _scheduleDirectionsFetch(immediate: true);
            _startPolling();
            _startSafetyTracking();
          },
        ),
      ),
    );
  }

  Future<void> _callDriver(Map<String, dynamic>? driver) async {
    final local = AppLocalizations.of(context)!;
    var phone = normalizePhoneForTel(driver?['phone']?.toString());

    if (phone == null && _activeRide != null) {
      await _refreshActiveRide();
      phone = normalizePhoneForTel(_activeRide?.driver?['phone']?.toString());
    }

    if (phone == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.rideNoDriverPhone)),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (!await canLaunchUrl(uri)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.rideCallFailed)),
        );
        return;
      }
      final launched = await launchUrl(uri);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.rideCallFailed)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.rideCallFailed)),
      );
    }
  }

  void _onRideCompleted(int rideId) {
    if (_ratingShownFor.contains(rideId)) return;
    _ratingShownFor.add(rideId);

    final ride = _activeRide;
    if (ride?.paymentMethod == 'sham_cash' && ride?.paymentReference == null) {
      final primaryShare = ride?.splitFareAccepted == true
          ? (ride!.splitFare!['primaryShare'] as num?)?.toDouble()
          : null;
      showShamCashPaymentSheet(
        context,
        rideId: rideId,
        estimatedFare: primaryShare ?? ride?.estimatedFare,
      ).then((_) {
        if (mounted && ride?.passengerRating == null) {
          _showRatingDialog(rideId);
        }
      });
      return;
    }
    if (ride?.passengerRating != null) return;
    _showRatingDialog(rideId);
  }

  void _showRatingDialog(int rideId) {
    showRideRatingSheet(
      context,
      rideId: rideId,
      suggestedFare: _activeRide?.estimatedFare,
    );
  }

  /// إلغاء الرحلة الفورية قبل بدئها (أثناء البحث / إسناد السائق / وصول السائق).
  Future<void> _cancelActiveRide() async {
    final ride = _activeRide;
    if (ride == null) return;
    HapticFeedback.mediumImpact();
    final local = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(local.cancel_ride),
        content: Text(local.cancel_ride_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(local.keep_Ride),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(local.cancel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await RiderService.instance.cancelRide(ride.id);
      _resetAfterRide(rideId: ride.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.ride_cancelled)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelScheduledRide() async {
    if (_scheduledRide == null) return;
    HapticFeedback.mediumImpact();
    final local = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: Text(local.cancel_ride),
        content: Text(local.scheduledRidesDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: Text(local.keep_Ride),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: Text(local.cancel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await RiderService.instance.cancelRide(_scheduledRide!.id);
      if (mounted) setState(() => _scheduledRide = null);
      _scheduledPollTimer?.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }


  // ────────────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;
    final name = user?.firstName ?? '';
    final viewPad = MediaQuery.paddingOf(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final showHomeSheet = _activeRide == null;
    final hasLiveRide = _activeRide?.isLiveTrip == true;
    final mapBottomPad = hasLiveRide
        ? screenH * 0.48
        : (showHomeSheet ? screenH * _homeSheetSize + viewPad.bottom : 0.0);
    final activeRide = _activeRide;
    final showPickupLabel = hasLiveRide &&
        activeRide != null &&
        !activeRide.headingToDropoff;
    final mapDistanceText = hasLiveRide && activeRide != null
        ? (activeRide.estimatedDistanceKm != null
            ? local.distanceKmUnit(
                activeRide.estimatedDistanceKm!.toStringAsFixed(1),
              )
            : null)
        : null;

    return A11yScreen(
      label: local.letsGo,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: const RiderMenuSheet(),
        body: Builder(
          builder: (ctx) => Stack(
            clipBehavior: Clip.none,
            children: [
              // ════ MAP (bottom layer) ═══════════════════════════
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? AppDefaultLocation.damascus,
                  zoom: 15,
                ),
                padding: EdgeInsets.only(
                  top: viewPad.top + 64,
                  bottom: mapBottomPad,
                  left: 8,
                  right: 8,
                ),
                onMapCreated: (c) {
                  _mapController = c;
                  setState(() => _mapReady = true);
                  _bottomCtrl.forward();
                  if (_activeRide == null) {
                    _loadNearbyDrivers();
                  }
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                markers: _markers,
                polylines: _polylines,
              ),

              // ════ HOME SHEET (Bolt-style draggable) ═══════════
              if (_activeRide == null)
                DraggableScrollableSheet(
                  controller: _homeSheetController,
                  initialChildSize: 0.22,
                  minChildSize: 0.15,
                  maxChildSize: 0.58,
                  snap: true,
                  snapSizes: const [0.15, 0.22, 0.58],
                  builder: (context, scrollController) => RiderBottomPanel(
                    scrollController: scrollController,
                    sheetSize: _homeSheetSize,
                    selectedVehicle: _selectedVehicle,
                    vehicles: _vehicles,
                    surgeMultiplier: _localSurge,
                    surgeLabel: _localSurgeLabel,
                    onVehicleChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedVehicle = v);
                    },
                    onWhereTap: _openRideSheet,
                    onLaterTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScheduleRideScreen(),
                        ),
                      );
                      if (mounted) _checkActiveRide();
                    },
                    local: local,
                  ),
                ),

              if (_activeRide == null && _scheduledRide != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: screenH * _homeSheetSize + viewPad.bottom + 8,
                  child: ScheduledRideBar(
                    ride: _scheduledRide!,
                    whenLabel: _fmtScheduledAt(_scheduledRide!.scheduledAt),
                    local: local,
                    onCancel: _cancelScheduledRide,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UpcomingTripsScreen(),
                      ),
                    ),
                  ),
                ),

              // ════ RETRY BANNER (above sheet) ═════════════════════
              if (_activeRide == null &&
                  _retryableRide != null &&
                  _scheduledRide == null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: screenH * _homeSheetSize + viewPad.bottom + 8,
                  child: RetryRideBanner(
                    loading: _retryingSearch,
                    onRetry: _retryRideSearch,
                  ),
                ),

              // ════ MAP OVERLAYS (active ride) ═══════════════════
              if (showPickupLabel)
                Positioned(
                  left: 0,
                  right: 0,
                  top: viewPad.top + 96,
                  child: Center(
                    child: RiderActiveRideUi.mapPickupLabel(local.mapMeetingPoint),
                  ),
                ),
              if (mapDistanceText != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: mapBottomPad + 24,
                  child: Center(
                    child: RiderActiveRideUi.mapDistanceChip(mapDistanceText),
                  ),
                ),

              // ════ ACTIVE RIDE BOTTOM SHEET ═════════════════════
              if (hasLiveRide && activeRide != null)
                DraggableScrollableSheet(
                  controller: _activeSheetController,
                  initialChildSize: 0.56,
                  minChildSize: 0.32,
                  maxChildSize: 0.9,
                  snap: true,
                  snapSizes: const [0.32, 0.56, 0.9],
                  builder: (context, scrollController) =>
                      RiderActiveRideBottomSheet(
                    scrollController: scrollController,
                    ride: activeRide,
                    t: local,
                    audioRecording: _audioRecording,
                    onToggleAudio: () =>
                        setState(() => _audioRecording = !_audioRecording),
                    onRefresh: _checkActiveRide,
                    onCancel: _cancelActiveRide,
                    onSafety: () => showRideSafetySheet(
                      context,
                      rideId: activeRide.id,
                    ),
                    onCall: activeRide.hasDriver
                        ? () => _callDriver(activeRide.driver)
                        : null,
                    onShamCashPay: activeRide.paymentMethod == 'sham_cash'
                        ? () {
                            final split = activeRide.splitFare;
                            final primaryShare = activeRide.splitFareAccepted
                                ? (split?['primaryShare'] as num?)?.toDouble()
                                : null;
                            showShamCashPaymentSheet(
                              context,
                              rideId: activeRide.id,
                              estimatedFare:
                                  primaryShare ?? activeRide.estimatedFare,
                            );
                          }
                        : null,
                    onMessage: activeRide.hasDriver
                        ? () {
                            final d = activeRide.driver!;
                            final driverName = [
                              d['firstName'],
                              d['lastName'],
                            ]
                                .where(
                                  (e) =>
                                      e != null &&
                                      e.toString().isNotEmpty,
                                )
                                .join(' ');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RideChatScreen(
                                  mode: ChatMode.ride,
                                  rideId: activeRide.id,
                                  title: driverName.isNotEmpty
                                      ? driverName
                                      : local.chatWithDriver,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),

              if (hasLiveRide)
                Positioned(
                  top: viewPad.top + 12,
                  right: 16,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 3,
                    child: IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      onPressed: () {
                        _activeSheetController.animateTo(
                          0.32,
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                ),

              // ════ TOP BAR ════════════════════════════════════════
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      RiderMapTopButton(
                        semanticsLabel: local.a11yOpenMenu,
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (name.isNotEmpty && !hasLiveRide)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${local.hey} $name 👋',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (name.isEmpty) const Spacer(),
                      const SizedBox(width: 10),
                      if (_activeRide != null) ...[
                        RiderMapTopButton(
                          semanticsLabel: local.a11ySafety,
                          onTap: () => showRideSafetySheet(
                            context,
                            rideId: _activeRide!.id,
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            color: Colors.red.shade700,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      RiderMapTopButton(
                        semanticsLabel: local.a11ySurgeMap,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SurgeMapScreen(),
                          ),
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFf97316),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      RiderMapTopButton(
                        semanticsLabel: local.a11yRecenterMap,
                        onTap: _recenter,
                        child: const Icon(
                          Icons.my_location_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

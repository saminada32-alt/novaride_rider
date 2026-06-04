import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import '../../../core/services/rider_socket_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:novaride_rider/core/services/rider_socket_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/default_location.dart';
import '../../../core/services/directions_service.dart';
import '../../../core/utils/map_icons.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';
import '../rides/schedule_ride_screen.dart';
import '../surge_map/surge_map_screen.dart';
import '../account/upcoming_trips/upcoming_trips_screen.dart';
import '../payments/sham_cash_sheet.dart';
import '../chat/ride_chat_screen.dart';
import '../services/ride_safety_service.dart';
import 'ride_safety_sheet.dart';
import 'rider_request_sheet.dart';
import 'rider_menu_sheet.dart';

String? _driverPhotoUrl(Map<String, dynamic>? driver) =>
    resolveMediaUrl(
      driver?['profileImage']?.toString() ??
          driver?['driverPhoto']?.toString(),
    );

Widget _driverAvatar(Map<String, dynamic>? driver, {double size = 44}) {
  final url = _driverPhotoUrl(driver);
  if (url != null) {
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Icon(Icons.person_rounded, size: size * 0.5, color: Colors.black54),
    );
  }
  return Icon(Icons.person_rounded, size: size * 0.5, color: Colors.black54);
}

// ─── Vehicle Model ────────────────────────────────────────────
class VehicleOption {
  final String id;
  final String label;
  final String sublabel;
  final IconData icon;
  final String eta;
  final double multiplier;

  const VehicleOption({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.icon,
    required this.eta,
    required this.multiplier,
  });
}

final _vehicles = [
  const VehicleOption(
    id: 'car',
    label: 'NovaX',
    sublabel: '4 seats',
    icon: Icons.directions_car_filled_rounded,
    eta: '3 min',
    multiplier: 1.0,
  ),
  const VehicleOption(
    id: 'van',
    label: 'NovaPro',
    sublabel: '7 seats',
    icon: Icons.airport_shuttle_rounded,
    eta: '5 min',
    multiplier: 1.5,
  ),
  const VehicleOption(
    id: 'taxi',
    label: 'Taxi',
    sublabel: 'Licensed',
    icon: Icons.local_taxi_rounded,
    eta: '4 min',
    multiplier: 1.2,
  ),
];

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
  RideModel? _activeRide;
  RideModel? _scheduledRide;
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
    _loadMapIcons();
    _refreshLocalSurge();
    _nearbyTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_activeRide == null) _loadNearbyDrivers();
      _refreshLocalSurge();
    });

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
            if (_driverPosition != null) _driverPosition!,
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
      if (_driverPosition != null) _driverPosition!,
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
              if (_driverPosition != null) _driverPosition!,
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
    final rides = await RiderService.instance.getMyRides();
    if (!mounted) return;
    _applyRidesFromServer(rides, refitOnNewLive: true);
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
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.rideNoLongerActive),
              backgroundColor: Colors.orange,
            ),
          );
        }
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
      final refit = _activeRide?.status != ride.status;
      setState(() => _activeRide = ride);
      _rebuildMapOverlays(refitCamera: refit);
      if (refit) _scheduleDirectionsFetch(immediate: true);
    });
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
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: RiderRequestSheet(
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
      showShamCashPaymentSheet(
        context,
        rideId: rideId,
        estimatedFare: ride?.estimatedFare,
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
    final local = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        double rating = 5;
        bool submitting = false;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(local.rateYourRide),
          content: StatefulBuilder(
            builder: (ctx, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(local.howWasYourTrip),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final filled = i < rating.round();
                      return IconButton(
                        onPressed: submitting
                            ? null
                            : () =>
                                setState(() => rating = (i + 1).toDouble()),
                        icon: Icon(
                          filled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.pop(ctx),
              child: Text(local.skip),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setState(() => submitting = true);
                      try {
                        await RiderService.instance.rateRide(
                          rideId,
                          rating.round(),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(local.ratingSubmitted)),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setState(() => submitting = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(local.ratingFailed),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(local.submit),
            ),
          ],
        );
      },
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

  VehicleOption get _currentVehicle => _vehicles.firstWhere(
    (v) => v.id == _selectedVehicle,
    orElse: () => _vehicles.first,
  );

  // ────────────────────────────── BUILD ──────────────────────
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;
    final name = user?.firstName ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(

      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.black,
        drawer: const RiderMenuSheet(),
        body: Builder(
          builder: (ctx) => Stack(
            children: [
              // ════ MAP ═══════════════════════════════════════════
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _currentPosition ?? AppDefaultLocation.damascus,
                  zoom: 15,
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

              // ════ TOP BAR ════════════════════════════════════════
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      // Menu
                      _topBtn(
                        onTap: () => Scaffold.of(ctx).openDrawer(),
                        child: const Icon(
                          Icons.menu_rounded,
                          color: Colors.black,
                          size: 22,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Greeting pill
                      if (name.isNotEmpty)
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
                        _topBtn(
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

                      // Demand / surge map
                      _topBtn(
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

                      // Recenter
                      _topBtn(
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

              // ════ ACTIVE RIDE BANNER ════════════════════════════
              if (_activeRide != null)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                    child: _ActiveRideBanner(
                      ride: _activeRide!,
                      onRefresh: _checkActiveRide,
                      onCancel: _cancelActiveRide,
                      onCall: _activeRide!.hasDriver
                          ? () => _callDriver(_activeRide!.driver)
                          : null,
                      onShamCashPay: _activeRide!.paymentMethod == 'sham_cash'
                          ? () => showShamCashPaymentSheet(
                                context,
                                rideId: _activeRide!.id,
                                estimatedFare: _activeRide!.estimatedFare,
                              )
                          : null,
                      onChat: _activeRide!.hasDriver
                          ? () {
                              final d = _activeRide!.driver!;
                              final name = [
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
                                    rideId: _activeRide!.id,
                                    title: name.isNotEmpty
                                        ? name
                                        : local.chatWithDriver,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  ),
                ),

              // ════ SCHEDULED RIDE (لا يجمّد الهوم) ═════════════════
              if (_activeRide == null && _scheduledRide != null)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 0,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ScheduledRideBar(
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
                        const SizedBox(height: 8),
                        SlideTransition(
                          position: _bottomSlide,
                          child: _BottomPanel(
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
                      ],
                    ),
                  ),
                )
              else if (_activeRide == null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _bottomSlide,
                    child: _BottomPanel(
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
                ),
            ],
          ),
        ),
      ),
      // ),
    );
  }

  Widget _topBtn({required Widget child, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: child),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// SCHEDULED RIDE BAR (فوق لوحة الحجز — لا يمنع رحلة جديدة)
// ─────────────────────────────────────────────────────────────
class _ScheduledRideBar extends StatelessWidget {
  final RideModel ride;
  final String whenLabel;
  final AppLocalizations local;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const _ScheduledRideBar({
    required this.ride,
    required this.whenLabel,
    required this.local,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Colors.indigo.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.scheduledRidesTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${local.when} · $whenLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (ride.dropoffAddress?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        ride.dropoffAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey.shade600,
                onPressed: onCancel,
                tooltip: local.cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM PANEL
// ─────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final String selectedVehicle;
  final List<VehicleOption> vehicles;
  final double surgeMultiplier;
  final String? surgeLabel;
  final void Function(String) onVehicleChanged;
  final VoidCallback onWhereTap;
  final VoidCallback onLaterTap;
  final AppLocalizations local;

  const _BottomPanel({
    required this.selectedVehicle,
    required this.vehicles,
    this.surgeMultiplier = 1.0,
    this.surgeLabel,
    required this.onVehicleChanged,
    required this.onWhereTap,
    required this.onLaterTap,
    required this.local,
  });

  VehicleOption get _current => vehicles.firstWhere(
    (v) => v.id == selectedVehicle,
    orElse: () => vehicles.first,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                // ─── Vehicle Tabs ─────────────────────────────────
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vehicles.length + 1, // +1 for "Later"
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      if (i == vehicles.length) {
                        // LATER button
                        return GestureDetector(
                          onTap: onLaterTap,
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(.06),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.schedule_rounded,
                                      size: 22,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  local.later,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  local.scheduleRide,
                                  style: const TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final v = vehicles[i];
                      final sel = selectedVehicle == v.id;

                      return GestureDetector(
                        onTap: () => onVehicleChanged(v.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 90,
                          decoration: BoxDecoration(
                            color: sel ? Colors.black : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel ? Colors.black : Colors.grey.shade200,
                              width: sel ? 2 : 1,
                            ),
                            boxShadow: sel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(.2),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: sel ? 1.1 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? Colors.white.withOpacity(.15)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      v.icon,
                                      size: 26,
                                      color: sel
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                v.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: sel ? Colors.white : Colors.black87,
                                ),
                              ),
                              Text(
                                v.eta,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: sel
                                      ? Colors.white.withOpacity(.7)
                                      : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                if (surgeMultiplier > 1.01)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.orange.shade800, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Surge ×${surgeMultiplier.toStringAsFixed(1)}${surgeLabel != null ? ' · $surgeLabel' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ─── Fare estimate ────────────────────────────────
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${local.pricesmayvary} · ${_current.label} · ${_current.sublabel}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ─── WHERE TO Button ──────────────────────────────
                GestureDetector(
                  onTap: onWhereTap,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 20),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            local.whereTo,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.bolt_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _current.eta,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ACTIVE RIDE BANNER
// ─────────────────────────────────────────────────────────────
class _ActiveRideBanner extends StatefulWidget {
  final RideModel ride;
  final VoidCallback? onRefresh;
  final VoidCallback? onCall;
  final VoidCallback? onShamCashPay;
  final VoidCallback? onChat;
  final VoidCallback? onCancel;
  const _ActiveRideBanner({
    required this.ride,
    this.onRefresh,
    this.onCall,
    this.onShamCashPay,
    this.onChat,
    this.onCancel,
  });
  @override
  State<_ActiveRideBanner> createState() => _ActiveRideBannerState();
}

class _ActiveRideBannerState extends State<_ActiveRideBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final status = ride.status;
    final local = AppLocalizations.of(context)!;

    // Status config
    final cfg = _statusConfig(status, local: local);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cfg['color'].withOpacity(.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cfg['color'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Icon(cfg['icon'] as IconData, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      cfg['text'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (status == RideStatus.searching)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white.withOpacity(.7),
                      ),
                    ),
                  if (widget.onRefresh != null)
                    IconButton(
                      onPressed: widget.onRefresh,
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      tooltip: local.retry,
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Fare row
                  if (ride.estimatedFare != null)
                    Row(
                      children: [
                        _infoChip(
                          Icons.attach_money_rounded,
                          CurrencyUtils.formatSyp(ride.estimatedFare),
                          Colors.green,
                        ),
                        const SizedBox(width: 10),
                        if (ride.etaMinutes != null)
                          _infoChip(
                            Icons.schedule_rounded,
                            '${ride.etaMinutes} min',
                            Colors.blue,
                          ),
                        if (ride.estimatedDistanceKm != null) ...[
                          const SizedBox(width: 10),
                          _infoChip(
                            Icons.straighten_rounded,
                            '${ride.estimatedDistanceKm!.toStringAsFixed(1)} km',
                            Colors.orange,
                          ),
                        ],
                      ],
                    ),

                  if (ride.paymentMethod == 'sham_cash' &&
                      widget.onShamCashPay != null &&
                      (status == RideStatus.trip_started ||
                          status == RideStatus.passenger_onboard)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onShamCashPay,
                        icon: const Icon(Icons.phone_android_rounded, size: 18),
                        label: Text(local.shamCash),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade200),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Driver info
                  if (ride.hasDriver) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _driverAvatar(ride.driver, size: 44),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${ride.driver!['firstName'] ?? ''} ${ride.driver!['lastName'] ?? ''}'
                                    .trim(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    ride.driver?['rating']?.toString() ?? '5.0',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              if (ride.vehicle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${ride.vehicle!['brand'] ?? ''} ${ride.vehicle!['model'] ?? ''} · ${ride.vehicle!['type'] ?? ride.vehicleType ?? ''}'
                                      .trim(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Call button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.call_rounded,
                              color: Colors.green,
                              size: 22,
                            ),
                            onPressed: widget.onCall,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Message button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.blue,
                              size: 22,
                            ),
                            onPressed: widget.onChat,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Progress steps
                  if (ride.isLiveTrip) ...[
                    const SizedBox(height: 14),
                    _StatusSteps(status: status),
                  ],

                  // Cancel button — only before the trip starts
                  if (widget.onCancel != null &&
                      (status == RideStatus.searching ||
                          status == RideStatus.driver_assigned ||
                          status == RideStatus.driver_arrived)) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onCancel,
                        icon: const Icon(Icons.close_rounded, size: 18),
                        label: Text(local.cancel_ride),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );

  Map<String, dynamic> _statusConfig(
    RideStatus s, {
    required AppLocalizations local,
  }) {
    switch (s) {
      case RideStatus.scheduled:
        return {
          'color': Colors.indigo.shade600,
          'icon': Icons.schedule_rounded,
          'text': local.scheduledRidesTitle,
        };
      case RideStatus.searching:
        return {
          'color': Colors.orange.shade600,
          'icon': Icons.search_rounded,
          'text': local.findYourDriver,
        };
      case RideStatus.driver_assigned:
        return {
          'color': Colors.blue.shade600,
          'icon': Icons.directions_car_rounded,
          'text': local.yourDriverIsOnTheWay,
        };
      case RideStatus.driver_arrived:
        return {
          'color': Colors.green.shade600,
          'icon': Icons.location_on_rounded,
          'text': local.driverHasArrived,
        };
      case RideStatus.passenger_onboard:
        return {
          'color': Colors.teal.shade600,
          'icon': Icons.airline_seat_recline_normal_rounded,
          'text': local.youAreOnBoard,
        };
      case RideStatus.trip_started:
        return {
          'color': const Color(0xFF1a1a2e),
          'icon': Icons.navigation_rounded,
          'text': local.headingToDestination,
        };
      default:
        return {
          'color': Colors.grey,
          'icon': Icons.info_rounded,
          'text': s.name.replaceAll('_', ' '),
        };
    }
  }
}

// ─── Status Steps ─────────────────────────────────────────────
class _StatusSteps extends StatelessWidget {
  final RideStatus status;
  const _StatusSteps({required this.status});

  int get _step {
    switch (status) {
      case RideStatus.searching:
        return 0;
      case RideStatus.driver_assigned:
        return 1;
      case RideStatus.driver_arrived:
        return 2;
      case RideStatus.passenger_onboard:
      case RideStatus.trip_started:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final steps = [
      local.rideStepFinding,
      local.rideStepAssigned,
      local.rideStepArrived,
      local.rideStepRiding,
    ];
    final current = _step;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector
          final filled = (i ~/ 2) < current;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? Colors.black : Colors.grey.shade200,
            ),
          );
        }

        final idx = i ~/ 2;
        final done = idx < current;
        final active = idx == current;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: active ? 28 : 20,
              height: active ? 28 : 20,
              decoration: BoxDecoration(
                color: done
                    ? Colors.black
                    : active
                    ? Colors.black
                    : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(.3),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: done
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      )
                    : active
                    ? const Icon(Icons.circle, color: Colors.white, size: 8)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[idx],
              style: TextStyle(
                fontSize: 9,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.black : Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}

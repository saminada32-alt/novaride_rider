// lib/features/rider/rides/schedule_ride_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/constants/default_location.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/rider_service.dart';
import '../promotions/promo_provider.dart';
import '../models/ride_model.dart';
import '../widgets/surge_badge.dart';
import 'my_scheduled_rides_screen.dart';
import '../../../core/constants/maps_constants.dart';

class ScheduleRideScreen extends StatefulWidget {
  const ScheduleRideScreen({super.key});
  @override
  State<ScheduleRideScreen> createState() => _ScheduleRideScreenState();
}

class _ScheduleRideScreenState extends State<ScheduleRideScreen>
    with SingleTickerProviderStateMixin {
  // ─── State ────────────────────────────────────────────────────
  GoogleMapController? _mapCtrl;
  LatLng? _currentLatLng;
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;

  String _pickupAddress = '';
  String _dropoffAddress = '';
  DateTime? _scheduledAt;

  bool _loading = false;
  bool _mapExpanded = false;
  bool _selectingOnMap = false; // وضع الاختيار من الخريطة

  // تقدير السعر (يُحسب عند توفّر الوجهة + الموعد)
  Map<String, dynamic>? _estimate;
  bool _estimating = false;

  // Search
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  List<_PlacePrediction> _predictions = [];
  bool _searching = false;
  Timer? _debounce;

  // Animation
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // Markers
  Set<Marker> get _markers => {
    if (_pickupLatLng != null)
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupAddress),
      ),
    if (_dropoffLatLng != null)
      Marker(
        markerId: const MarkerId('dropoff'),
        position: _dropoffLatLng!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Dropoff', snippet: _dropoffAddress),
      ),
  };

  // ─── Lifecycle ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─── Location ─────────────────────────────────────────────────
  Future<void> _initLocation() async {
    if (AppDefaultLocation.pinToDamascus) {
      if (!mounted) return;
      setState(() {
        _currentLatLng = AppDefaultLocation.damascus;
        _pickupLatLng = AppDefaultLocation.damascus;
        _pickupAddress = AppDefaultLocation.pickupLabelAr;
      });
      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLngZoom(AppDefaultLocation.damascus, 15),
      );
      return;
    }

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // على الـ simulator الـ location مو enabled دايماً
        // حط موقع افتراضي
        if (mounted)
          setState(() {
            _currentLatLng = const LatLng(33.5138, 36.2765);
            _pickupLatLng = _currentLatLng;
            _pickupAddress = 'Current Location';
            if (_currentLatLng != null) {
              _reverseGeocode(_currentLatLng!, isPickup: true);
            }
          });
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        // افتراضي
        if (mounted) {
          setState(() {
            _currentLatLng = const LatLng(33.5138, 36.2765);
            _pickupLatLng = _currentLatLng;
            _pickupAddress = 'Current Location';
            if (_currentLatLng != null) {
              _reverseGeocode(_currentLatLng!, isPickup: true);
            }
          });
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      setState(() {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);
        _pickupLatLng = _currentLatLng;
        _pickupAddress = 'Current Location';
        if (_currentLatLng != null) {
          _reverseGeocode(_currentLatLng!, isPickup: true);
        }
      });

      _reverseGeocode(_currentLatLng!, isPickup: true);

      _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng!, 15));
    } catch (e) {
      // إذا فشل → موقع افتراضي
      if (mounted)
        setState(() {
          _currentLatLng = const LatLng(33.5138, 36.2765);
          _pickupLatLng = _currentLatLng;
          _pickupAddress = 'Current Location';
        });
    }
  }

  // ─── Reverse Geocode ──────────────────────────────────────────
  Future<void> _reverseGeocode(LatLng pos, {required bool isPickup}) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${pos.latitude},${pos.longitude}'
        '&language=ar&key=${GoogleMapsConfig.apiKey}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      if (data['status'] == 'OK') {
        final addr = data['results'][0]['formatted_address'] as String;
        if (!mounted) return;
        setState(() {
          if (isPickup)
            _pickupAddress = addr;
          else
            _dropoffAddress = addr;
        });
      }
    } catch (_) {}
  }

  // ─── Places Autocomplete ──────────────────────────────────────
  Future<void> _search(String q) async {
    if (q.length < 2) {
      setState(() => _predictions = []);
      return;
    }
    setState(() => _searching = true);

    try {
      final loc = _currentLatLng;
      final locBias = loc != null
          ? '&location=${loc.latitude},${loc.longitude}&radius=50000'
          : '';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=${Uri.encodeComponent(q)}'
        '&language=ar'
        '$locBias'
        '&key=${GoogleMapsConfig.apiKey}',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);

      if (!mounted) return;
      if (data['status'] == 'OK') {
        setState(() {
          _predictions = (data['predictions'] as List)
              .map(
                (p) => _PlacePrediction(
                  placeId: p['place_id'],
                  description: p['description'],
                  mainText: p['structured_formatting']['main_text'],
                  secondaryText:
                      p['structured_formatting']['secondary_text'] ?? '',
                ),
              )
              .toList();
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _searching = false);
  }

  // ─── Get Place Details ────────────────────────────────────────
  Future<void> _selectPlace(_PlacePrediction p) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _predictions = [];
      _searchCtrl.text = p.mainText;
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json'
        '?place_id=${p.placeId}'
        '&fields=geometry,formatted_address'
        '&key=${GoogleMapsConfig.apiKey}',
      );

      final res = await http.get(url).timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        final addr = data['result']['formatted_address'] as String;
        final latLng = LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );

        if (!mounted) return;
        setState(() {
          _dropoffLatLng = latLng;
          _dropoffAddress = addr;
          _searchCtrl.text = p.mainText;
        });
        _fetchEstimate();

        _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));

        HapticFeedback.selectionClick();
      }
    } catch (_) {}
  }

  // ─── Map Tap (اختيار من الخريطة) ─────────────────────────────
  Future<void> _onMapTap(LatLng pos) async {
    if (!_selectingOnMap) return;

    setState(() {
      _dropoffLatLng = pos;
    });
    _fetchEstimate();
    HapticFeedback.selectionClick();
    _reverseGeocode(pos, isPickup: false);

    _mapCtrl?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  // ─── DateTime Picker ──────────────────────────────────────────
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 2))),
      builder: (ctx, child) => Theme(
        data: Theme.of(
          ctx,
        ).copyWith(colorScheme: const ColorScheme.light(primary: Colors.black)),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
    _fetchEstimate();
  }

  // ─── Fare estimate ────────────────────────────────────────────
  Future<void> _fetchEstimate() async {
    if (_pickupLatLng == null || _dropoffLatLng == null || _scheduledAt == null) {
      if (mounted) setState(() => _estimate = null);
      return;
    }
    setState(() => _estimating = true);
    try {
      final est = await RiderService.instance.estimateFare(
        pickupLat: _pickupLatLng!.latitude,
        pickupLng: _pickupLatLng!.longitude,
        dropoffLat: _dropoffLatLng!.latitude,
        dropoffLng: _dropoffLatLng!.longitude,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      setState(() => _estimate = est);
    } catch (_) {
      if (mounted) setState(() => _estimate = null);
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  // ─── Confirm ──────────────────────────────────────────────────
  Future<void> _confirm() async {
    if (_scheduledAt == null || _dropoffLatLng == null) return;

    if (_scheduledAt!.isBefore(
      DateTime.now().add(const Duration(minutes: 30)),
    )) {
      _snack('Please schedule at least 30 minutes ahead', Colors.orange);
      return;
    }

    setState(() => _loading = true);
    HapticFeedback.mediumImpact();

    try {
      final promoCode = context.read<PromoProvider>().code;
      final ride = await RiderService.instance.createRide(
        pickupLat: _pickupLatLng?.latitude ?? 0,
        pickupLng: _pickupLatLng?.longitude ?? 0,
        dropoffLat: _dropoffLatLng!.latitude,
        dropoffLng: _dropoffLatLng!.longitude,
        pickupAddress: _pickupAddress,
        dropoffAddress: _dropoffAddress,
        scheduledAt: _scheduledAt,
        promoCode: promoCode,
      );
      if (!mounted) return;
      if (promoCode != null) {
        await context.read<PromoProvider>().clear();
      }
      _showSuccess(ride);
    } catch (e) {
      if (mounted) _snack(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Success Dialog ───────────────────────────────────────────
  void _showSuccess(RideModel ride) {
    final local = AppLocalizations.of(context)!;
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                local.rideScheduled,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Info chips
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _chip(
                    Icons.schedule_rounded,
                    _fmtDate(_scheduledAt!),
                    Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (ride.estimatedFare != null)
                _chip(
                  Icons.attach_money_rounded,
                  CurrencyUtils.formatSyp(ride.estimatedFare),
                  Colors.green,
                ),
              const SizedBox(height: 8),
              Text(
                local.ride + ' #${ride.id}',
                style: TextStyle(color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                local.yourdriver,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Text(
                    local.done,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────
  String _fmtDate(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} · $h:$m';
  }

  bool get _valid => _scheduledAt != null && _dropoffLatLng != null;

  void _snack(String msg, Color color) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  // ─── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;

    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: Text(local.scheduleRide),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_rounded),
            tooltip: local.myScheduledRides,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MyScheduledRidesScreen(),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ─── 1. DATE & TIME ──────────────────────────────────
            _SectionLabel(icon: '📅', label: local.when),
            const SizedBox(height: 10),
            _DateTimeCard(
              value: _scheduledAt,
              onTap: _pickDateTime,
              fmt: _scheduledAt != null ? _fmtDate(_scheduledAt!) : null,
              labelSelect: local.selectDateTime,
              labelMin: local.minimumAhead,
              labelReady: local.ready,
            ),

            const SizedBox(height: 24),

            // ─── 2. PICKUP ────────────────────────────────────────
            _SectionLabel(icon: '📍', label: local.pickup),
            const SizedBox(height: 10),
            _PickupCard(
              selected: _pickupAddress,
              currentAddress: _pickupAddress == 'Current Location'
                  ? local.gettingAddress
                  : _pickupAddress,
              homeAddress: user?.homeAddress,
              workAddress: user?.workAddress,
              onCurrentLocation: () {
                setState(() {
                  _pickupLatLng = _currentLatLng;
                  _pickupAddress = 'Current Location';
                });
                if (_currentLatLng != null) {
                  _reverseGeocode(_currentLatLng!, isPickup: true);
                }
              },
              onHome: user?.homeAddress != null
                  ? () => setState(() {
                      _pickupAddress = user!.homeAddress!;
                    })
                  : null,
              onWork: user?.workAddress != null
                  ? () => setState(() {
                      _pickupAddress = user!.workAddress!;
                    })
                  : null,
            ),

            const SizedBox(height: 24),

            // ─── 3. DESTINATION ───────────────────────────────────
            _SectionLabel(icon: '🏁', label: local.destination),
            const SizedBox(height: 10),

            // Search + Map toggle in one row
            Row(
              children: [
                Expanded(
                  child: _SearchBox(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    searching: _searching,
                    selected: _dropoffAddress,
                    onChanged: (q) {
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 400),
                        () => _search(q),
                      );
                    },
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() {
                        _predictions = [];
                        _dropoffLatLng = null;
                        _dropoffAddress = '';
                        _estimate = null;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                // Map picker toggle
                GestureDetector(
                  onTap: () => setState(() {
                    _selectingOnMap = !_selectingOnMap;
                    _mapExpanded = _selectingOnMap;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _selectingOnMap ? Colors.black : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: _selectingOnMap ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            // Predictions
            if (_predictions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8),
                  ],
                ),
                child: Column(
                  children: _predictions
                      .map(
                        (p) => InkWell(
                          onTap: () => _selectPlace(p),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.mainText,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        p.secondaryText,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 11,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ─── 4. MAP ────────────────────────────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: //(_currentLatLng != null) ? (
              _mapExpanded
                  ? 360
                  : 220,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: // _currentLatLng == null
                  //? null
                  // :
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target:
                                _currentLatLng ??
                                const LatLng(33.5138, 36.2765),
                            zoom: 14,
                          ),
                          onMapCreated: (c) {
                            _mapCtrl = c;
                            if (_currentLatLng != null) {
                              Future.delayed(
                                const Duration(milliseconds: 300),
                                () {
                                  c.animateCamera(
                                    CameraUpdate.newLatLngZoom(
                                      _currentLatLng!,
                                      15,
                                    ),
                                  );
                                },
                              );
                            }
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: false,
                          zoomControlsEnabled: false,
                          markers: _markers,
                          onTap: _onMapTap,
                        ),
                      ),

                      // Expand/collapse button
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mapExpanded = !_mapExpanded),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: Icon(
                              _mapExpanded
                                  ? Icons.fullscreen_exit_rounded
                                  : Icons.fullscreen_rounded,
                              size: 20,
                            ),
                          ),
                        ),
                      ),

                      // Tap to select banner
                      if (_selectingOnMap)
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(.85),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  local.tapMapSelect,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _selectingOnMap = false;
                                  }),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white60,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Recenter
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: GestureDetector(
                          onTap: () {
                            if (_currentLatLng != null) {
                              _mapCtrl?.animateCamera(
                                CameraUpdate.newLatLngZoom(_currentLatLng!, 15),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(
                              Icons.my_location_rounded,
                              size: 20,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            ),

            // Selected destination address
            if (_dropoffAddress.isNotEmpty && _dropoffLatLng != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dropoffAddress,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _dropoffLatLng = null;
                        _dropoffAddress = '';
                        _searchCtrl.clear();
                        _estimate = null;
                      }),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.green.shade400,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ─── 5. SUMMARY ───────────────────────────────────────
            if (_valid) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.rideSummary,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      icon: Icons.schedule_rounded,
                      label: local.when,
                      value: _fmtDate(_scheduledAt!),
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      icon: Icons.radio_button_checked_rounded,
                      label: local.from,
                      value: _pickupAddress,
                      color: Colors.green.shade300,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      icon: Icons.location_on_rounded,
                      label: local.to,
                      value: _dropoffAddress,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 14),
                    Container(height: 1, color: Colors.white12),
                    const SizedBox(height: 14),
                    _buildFareSection(local),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ─── 6. CONFIRM BUTTON ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 58,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _valid && !_loading
                      ? Colors.black
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _valid
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: (_valid && !_loading) ? _confirm : null,
                    child: Center(
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.schedule_send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _valid
                                      ? local.confirmSchedule
                                      : local.selectDateDestination,
                                  style: TextStyle(
                                    color: _valid ? Colors.white : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFareSection(AppLocalizations local) {
    if (_estimating) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
          ),
          const SizedBox(width: 12),
          Text(
            local.calculatingPrice,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      );
    }
    if (_estimate == null) {
      return Text(
        local.setDateDestForPrice,
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      );
    }
    final selected = _estimate!['selected'] as Map<String, dynamic>? ?? {};
    final fare = (selected['fare'] as num?)?.toDouble();
    final surge = _estimate!['surge'] as Map<String, dynamic>?;
    final mult = (surge?['multiplier'] as num?)?.toDouble() ?? 1.0;
    final level = surge?['level']?.toString();
    final zoneLabel = surge?['zone']?['labelAr']?.toString();
    final dist = (_estimate!['distanceKm'] as num?)?.toDouble();
    final eta = (_estimate!['etaMinutes'] as num?)?.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payments_rounded, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Text(
              local.estimatedPrice,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
              ),
            ),
            const Spacer(),
            Text(
              CurrencyUtils.formatSyp(fare),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          local.kmMinutes(dist?.toStringAsFixed(1) ?? '--', '${eta ?? '--'}'),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        if (mult > 1.01) ...[
          const SizedBox(height: 10),
          SurgeBadge(
            multiplier: mult,
            level: level,
            zoneLabel: zoneLabel,
            dark: true,
          ),
        ],
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
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
}

// ─────────────────────────────────────────────────────────────────
// SUB WIDGETS
// ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String icon, label;
  const _SectionLabel({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(icon, style: const TextStyle(fontSize: 16)),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _DateTimeCard extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final String? fmt;
  const _DateTimeCard({
    required this.value,
    required this.onTap,
    this.fmt,
    required labelSelect,
    required String labelMin,
    required String labelReady,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    final local = AppLocalizations.of(context)!;
    final isValid =
        hasValue &&
        value!.isAfter(DateTime.now().add(const Duration(minutes: 30)));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasValue
                ? (isValid ? Colors.green.shade200 : Colors.orange.shade200)
                : Colors.transparent,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: hasValue
                    ? (isValid ? Colors.green.shade50 : Colors.orange.shade50)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.calendar_today_rounded,
                color: hasValue
                    ? (isValid ? Colors.green : Colors.orange)
                    : Colors.black54,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasValue ? fmt! : 'Select date & time',
                    style: TextStyle(
                      fontWeight: hasValue
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: hasValue ? Colors.black87 : Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  if (hasValue && !isValid)
                    Text(
                      local.minimumAhead,
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                    ),
                  if (hasValue && isValid)
                    Text(
                      local.ready,
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final String selected;
  final String? currentAddress;
  final String? homeAddress;
  final String? workAddress;
  final VoidCallback onCurrentLocation;
  final VoidCallback? onHome;
  final VoidCallback? onWork;

  const _PickupCard({
    required this.selected,
    this.currentAddress,
    this.homeAddress,
    this.workAddress,
    required this.onCurrentLocation,
    this.onHome,
    this.onWork,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          _Option(
            icon: Icons.my_location_rounded,
            iconColor: Colors.green,
            title: 'Current Location',
            subtitle: currentAddress ?? 'Detecting...',
            selected: selected == 'Current Location',
            onTap: onCurrentLocation,
          ),
          if (homeAddress != null) ...[
            const _Divider(),
            _Option(
              icon: Icons.home_rounded,
              iconColor: Colors.blue,
              title: 'Home',
              subtitle: homeAddress!,
              selected: selected == homeAddress,
              onTap: onHome!,
            ),
          ],
          if (workAddress != null) ...[
            const _Divider(),
            _Option(
              icon: Icons.work_rounded,
              iconColor: Colors.orange,
              title: 'Work',
              subtitle: workAddress!,
              selected: selected == workAddress,
              onTap: onWork!,
            ),
          ],
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Option({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (selected)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
        ],
      ),
    ),
  );
}

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool searching;
  final String selected;
  final void Function(String) onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.focusNode,
    required this.searching,
    required this.selected,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
      ],
    ),
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Search destination...',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                ),
              )
            : const Icon(Icons.search_rounded, color: Colors.black54, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.grey,
                  size: 18,
                ),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width - 120,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ],
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 16,
    endIndent: 16,
    color: Colors.grey.shade100,
  );
}

// ─── Model ────────────────────────────────────────────────────────
class _PlacePrediction {
  final String placeId, description, mainText, secondaryText;
  const _PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}


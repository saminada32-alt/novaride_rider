import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/default_location.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';
import '../../../core/services/market_service.dart';
import '../promotions/promo_provider.dart';
import '../widgets/surge_badge.dart';
import '../../../core/services/ride_booking_offline.dart';
import '../../../core/widgets/a11y.dart';
import 'where_to_screen.dart';
import 'rider_vehicle_options.dart';
import 'rider_catalog_service.dart';
import 'widgets/rider_vehicle_chips.dart';

class RiderRequestSheet extends StatefulWidget {
  final LatLng? currentLocation;
  final String selectedVehicle;
  final void Function(String) onVehicleChanged;
  final void Function(RideModel) onRideCreated;
  final ScrollController? scrollController;

  const RiderRequestSheet({
    super.key,
    required this.currentLocation,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.onRideCreated,
    this.scrollController,
  });

  @override
  State<RiderRequestSheet> createState() => _RiderRequestSheetState();
}

class _RiderRequestSheetState extends State<RiderRequestSheet> {
  LatLng? _pickupLatLng;
  String? _pickupAddress;

  @override
  void initState() {
    super.initState();
    _pickupLatLng = widget.currentLocation ??
        (AppDefaultLocation.pinToDamascus ? AppDefaultLocation.damascus : null);
  }

  LatLng? get _pickup => _pickupLatLng;

  bool _loading = false;
  bool _confirming = false;
  String? _destination;
  double? _destLat;
  double? _destLng;
  double? _fare;
  double? _distKm;
  double _surgeMultiplier = 1.0;
  String? _surgeLabel;
  String? _surgeLevel;
  double? _originalFare;
  double? _discountAmount;
  String? _promoCode;
  String _paymentMethod = 'cash';
  final List<Map<String, dynamic>> _stops = [];
  bool _splitFareEnabled = false;
  final _splitPhoneCtrl = TextEditingController();
  int _splitPercent = 50;
  bool _isPool = false;
  int _poolMaxSeats = 2;

  void _showLocationRequired() {
    final local = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(local.enableLocationPermission),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _openSearch({bool pickup = false}) async {
    if (_pickup == null && !pickup) {
      _showLocationRequired();
      return;
    }

    final local = AppLocalizations.of(context)!;
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WhereToScreen(
          pickupLocation: _pickup ?? widget.currentLocation,
          title: pickup ? local.from : local.whereTo,
        ),
      ),
    );

    if (result == null || !mounted) return;

    if (pickup) {
      setState(() {
        _pickupLatLng = LatLng(result.lat, result.lng);
        _pickupAddress = result.address;
      });
      if (_destLat != null && _destLng != null) {
        setState(() => _loading = true);
        await _fetchFareEstimate(_destLat!, _destLng!);
        if (mounted) setState(() => _loading = false);
      }
      return;
    }

    _applyDestination(result.address, result.lat, result.lng);
  }

  @override
  void dispose() {
    _splitPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _addStop() async {
    if (_pickup == null) return;
    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WhereToScreen(pickupLocation: _pickup),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _stops.add({
        'lat': result.lat,
        'lng': result.lng,
        'address': result.address,
      });
    });
    if (_destLat != null && _destLng != null) {
      setState(() => _loading = true);
      await _fetchFareEstimate(_destLat!, _destLng!);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchFareEstimate(double lat, double lng) async {
    final pickup = _pickup!;
    final data = await RiderService.instance.estimateFare(
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropoffLat: lat,
      dropoffLng: lng,
      vehicleType: widget.selectedVehicle,
      promoCode: context.read<PromoProvider>().code,
      stops: _stops.isEmpty ? null : _stops,
    );
    if (!mounted) return;

    final selected = data['selected'] as Map<String, dynamic>? ?? {};
    final surge = data['surge'] as Map<String, dynamic>?;
    final promo = data['promo'] as Map<String, dynamic>?;

    setState(() {
      _distKm = (data['distanceKm'] as num?)?.toDouble();
      _fare = (selected['fare'] as num?)?.toDouble();
      _originalFare = (selected['originalFare'] as num?)?.toDouble() ??
          (promo?['originalFare'] as num?)?.toDouble();
      _discountAmount = (selected['discountAmount'] as num?)?.toDouble() ??
          (promo?['discountAmount'] as num?)?.toDouble();
      _promoCode = promo?['code']?.toString();
      _surgeMultiplier = (surge?['multiplier'] as num?)?.toDouble() ?? 1.0;
      _surgeLabel = surge?['zone']?['labelAr']?.toString();
      _surgeLevel = surge?['level']?.toString();
      _loading = false;
    });

    final promoError = data['promoError']?.toString();
    if (promoError != null && promoError.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(promoError), backgroundColor: Colors.orange),
      );
    }
  }

  void _applyDestination(String address, double lat, double lng) {
    if (_pickup == null) {
      _showLocationRequired();
      return;
    }

    setState(() {
      _destination = address;
      _destLat = lat;
      _destLng = lng;
      _confirming = true;
      _loading = true;
    });

    _fetchFareEstimate(lat, lng).catchError((_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.fareEstimateFailed),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> _tapSavedPlace(String title, String address) async {
    if (_pickup == null) {
      _showLocationRequired();
      return;
    }
    setState(() => _loading = true);
    try {
      final locs = await locationFromAddress(address);
      if (!mounted) return;
      if (locs.isEmpty) {
        setState(() => _loading = false);
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.locationPickFor(title))),
        );
        return;
      }
      _applyDestination(
        address,
        locs.first.latitude,
        locs.first.longitude,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.locationPickFailed),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onVehicleTap(String type) {
    widget.onVehicleChanged(type);
    if (_confirming && _destLat != null && _destLng != null) {
      setState(() => _loading = true);
      _fetchFareEstimate(_destLat!, _destLng!).catchError((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  String _pickupLabel(BuildContext context) {
    if (_pickupAddress?.trim().isNotEmpty == true) {
      return _pickupAddress!.trim();
    }
    if (AppDefaultLocation.pinToDamascus) {
      final code = Localizations.localeOf(context).languageCode;
      return AppDefaultLocation.pickupLabel(code);
    }
    return AppLocalizations.of(context)!.currentLocation;
  }

  Future<void> _confirmRide() async {
    final pickup = _pickup;
    if (pickup == null || _destLat == null) return;

    if (_surgeMultiplier >= 1.2) {
      final ok = await SurgeBadge.confirmIfHigh(
        context,
        multiplier: _surgeMultiplier,
        level: _surgeLevel,
        zoneLabel: _surgeLabel,
      );
      if (!ok || !mounted) return;
    }

    setState(() => _loading = true);

    final local = AppLocalizations.of(context)!;
    try {
      final promoCode = context.read<PromoProvider>().code;
      final accessible = false;
      final market = await MarketService.instance.resolve(
        pickup.latitude,
        pickup.longitude,
      );
      final paymentMethod = _splitFareEnabled ? 'sham_cash' : _paymentMethod;
      final payload = RiderService.instance.buildRidePayload(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: _destLat!,
        dropoffLng: _destLng!,
        pickupAddress: _pickupLabel(context),
        dropoffAddress: _destination,
        vehicleType: widget.selectedVehicle,
        promoCode: promoCode,
        paymentMethod: paymentMethod,
        accessibilityRequired: accessible,
        stops: _stops.isEmpty ? null : _stops,
        splitFarePhone: _splitFareEnabled ? _splitPhoneCtrl.text.trim() : null,
        splitFarePercent: _splitFareEnabled ? _splitPercent : null,
        marketCode: market.code,
        isPool: _isPool,
        poolMaxSeats: _isPool ? _poolMaxSeats : null,
      );
      final result = await RideBookingOffline.submit(payload);
      if (!mounted) return;
      if (result.queued) {
        Navigator.pop(context);
        announceForAccessibility(context, local.offlineRideQueued);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.offlineRideQueued)),
        );
        return;
      }
      if (promoCode != null) {
        await context.read<PromoProvider>().clear();
      }
      Navigator.pop(context);
      if (_splitFareEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(local.splitFareInviteSent)),
        );
      }
      widget.onRideCreated(result.ride!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _confirming ? _buildConfirm() : _buildSearch();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: widget.scrollController != null
          ? ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              children: [body],
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: body,
            ),
    );
  }

  Widget _buildSearch() {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(),
        const SizedBox(height: 12),
        _routeEditor(local),
        const SizedBox(height: 14),
        RiderVehicleChips(
          selectedVehicle: widget.selectedVehicle,
          vehicles: RiderCatalogService.instance.vehicles,
          onChanged: _onVehicleTap,
          local: local,
        ),
        const SizedBox(height: 16),
        Text(
          local.suggestions,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 6),
        if (user?.homeAddress?.isNotEmpty == true)
          _suggTile(
            Icons.home_rounded,
            local.home,
            user!.homeAddress!,
            onTap: () => _tapSavedPlace(local.home, user.homeAddress!),
          ),
        if (user?.workAddress?.isNotEmpty == true)
          _suggTile(
            Icons.work_rounded,
            local.work,
            user!.workAddress!,
            onTap: () => _tapSavedPlace(local.work, user.workAddress!),
          ),
      ],
    );
  }

  Widget _routeEditor(AppLocalizations local) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _openSearch(pickup: true),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.radio_button_checked,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _pickupLabel(context),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
            child: Row(
              children: [
                Container(width: 2, height: 20, color: Colors.grey.shade300),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _openSearch(),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: Colors.red.shade400,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        local.whereTo,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════
  // شاشة التأكيد
  // ════════════════════════════════════════════════════════
  Widget _buildConfirm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _handle(),
        const SizedBox(height: 16),

        // Header
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _confirming = false),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'تأكيد الرحلة',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Route
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _locationRow(
                Icons.radio_button_checked,
                Colors.green,
                _pickupLabel(context),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Container(
                  width: 2,
                  height: 18,
                  color: Colors.grey.shade300,
                ),
              ),
              _locationRow(
                Icons.location_on_rounded,
                Colors.red,
                _destination ?? '',
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Price Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0f0f1a), Color(0xFF1e1e3a)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'السعر التقديري',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              if (_originalFare != null &&
                  _discountAmount != null &&
                  _discountAmount! > 0) ...[
                Text(
                  CurrencyUtils.formatSyp(_originalFare),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 16,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Text(
                CurrencyUtils.formatSyp(_fare),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (_promoCode != null && (_discountAmount ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.discountPromo(
                    _promoCode!,
                    CurrencyUtils.formatSyp(_discountAmount),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF4ade80),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (_surgeMultiplier > 1.01) ...[
                const SizedBox(height: 10),
                SurgeBadge(
                  multiplier: _surgeMultiplier,
                  level: _surgeLevel,
                  zoneLabel: _surgeLabel,
                  dark: true,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  _chip(
                    Icons.straighten_rounded,
                    _distKm != null
                        ? AppLocalizations.of(context)!.distanceKmUnit(
                            _distKm!.toStringAsFixed(1),
                          )
                        : '--',
                    Colors.blue,
                  ),
                  _chip(
                    Icons.directions_car_rounded,
                    vehicleLabel(
                      widget.selectedVehicle,
                      car: AppLocalizations.of(context)!.car,
                      van: AppLocalizations.of(context)!.van,
                      taxi: AppLocalizations.of(context)!.taxi,
                      accessible: AppLocalizations.of(context)!.accessibleRide,
                      moto: AppLocalizations.of(context)!.vehicleMoto,
                    ),
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        A11yHeader(
          label: AppLocalizations.of(context)!.paymentMethodLabel,
          child: Text(
            AppLocalizations.of(context)!.paymentMethodLabel,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _payOption(
                Icons.money_rounded,
                AppLocalizations.of(context)!.cashPayment,
                'cash',
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _payOption(
                Icons.phone_android_rounded,
                AppLocalizations.of(context)!.shamCashPayment,
                'sham_cash',
                Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.teal.shade100),
          ),
          child: Row(
            children: [
              Icon(Icons.people_outline, color: Colors.teal.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.poolRideTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      AppLocalizations.of(context)!.poolRideSubtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isPool,
                activeColor: Colors.teal,
                onChanged: _loading
                    ? null
                    : (v) => setState(() {
                          _isPool = v;
                          if (v && _stops.isNotEmpty) {
                            _stops.clear();
                          }
                        }),
              ),
            ],
          ),
        ),
        if (_isPool) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.poolPassengersLabel,
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
              const Spacer(),
              DropdownButton<int>(
                value: _poolMaxSeats,
                items: [2, 3, 4]
                    .map(
                      (n) => DropdownMenuItem(
                        value: n,
                        child: Text('$n'),
                      ),
                    )
                    .toList(),
                onChanged: _loading ? null : (v) => setState(() => _poolMaxSeats = v ?? 2),
              ),
            ],
          ),
        ],

        const SizedBox(height: 16),
        A11yHeader(
          label: AppLocalizations.of(context)!.multiStopTitle,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.multiStopTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _loading || _isPool ? null : _addStop,
                icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                label: Text(AppLocalizations.of(context)!.addStop),
              ),
            ],
          ),
        ),
        if (_stops.isNotEmpty)
          ..._stops.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 16, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.value['address']?.toString() ??
                            AppLocalizations.of(context)!
                                .multiStopNumber(e.key + 1),
                        style: const TextStyle(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () {
                              setState(() => _stops.removeAt(e.key));
                              if (_destLat != null && _destLng != null) {
                                _fetchFareEstimate(_destLat!, _destLng!);
                              }
                            },
                      icon: const Icon(Icons.close, size: 18),
                      tooltip: AppLocalizations.of(context)!.removeStop,
                    ),
                  ],
                ),
              )),

        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(AppLocalizations.of(context)!.splitFareTitle),
          subtitle: Text(AppLocalizations.of(context)!.splitFareHint),
          value: _splitFareEnabled,
          onChanged: _loading
              ? null
              : (v) => setState(() {
                  _splitFareEnabled = v;
                  if (v) _paymentMethod = 'sham_cash';
                }),
        ),
        if (_splitFareEnabled) ...[
          Semantics(
            label: AppLocalizations.of(context)!.splitFarePhone,
            textField: true,
            child: TextField(
              controller: _splitPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.splitFarePhone,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.splitFarePercent),
          Slider(
            value: _splitPercent.toDouble(),
            min: 10,
            max: 90,
            divisions: 8,
            label: '$_splitPercent%',
            onChanged: _loading
                ? null
                : (v) => setState(() => _splitPercent = v.round()),
          ),
        ],

        const SizedBox(height: 16),

        // ─── زر التأكيد ─────────────────────────────────
        A11yButton(
          label: AppLocalizations.of(context)!.confirmRide,
          child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirmRide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
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
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context)!.confirmRide,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        ),

        const SizedBox(height: 8),

        TextButton(
          onPressed: () => setState(() => _confirming = false),
          child: Text(
            'تغيير الوجهة',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ──────────────────────────────────────────
  Widget _handle() => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );

  Widget _payOption(IconData icon, String label, String value, Color color) {
    final selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: selected ? color : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  Widget _chip(IconData icon, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(.15),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );

  Widget _suggTile(
    IconData icon,
    String title,
    String sub, {
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.black54),
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
                    fontSize: 13,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: Colors.grey[300],
          ),
        ],
      ),
    ),
  );
}

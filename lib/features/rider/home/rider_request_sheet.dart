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
import '../promotions/promo_provider.dart';
import '../widgets/surge_badge.dart';
import 'where_to_screen.dart';

class RiderRequestSheet extends StatefulWidget {
  final LatLng? currentLocation;
  final String selectedVehicle;
  final void Function(String) onVehicleChanged;
  final void Function(RideModel) onRideCreated;

  const RiderRequestSheet({
    super.key,
    required this.currentLocation,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.onRideCreated,
  });

  @override
  State<RiderRequestSheet> createState() => _RiderRequestSheetState();
}

class _RiderRequestSheetState extends State<RiderRequestSheet> {
  LatLng? get _pickup =>
      widget.currentLocation ??
      (AppDefaultLocation.pinToDamascus ? AppDefaultLocation.damascus : null);

  bool _loading = false;
  bool _confirming = false;
  String? _destination;
  double? _destLat;
  double? _destLng;
  double? _fare;
  double? _distKm;
  int? _eta;
  double _surgeMultiplier = 1.0;
  String? _surgeLabel;
  String? _surgeLevel;
  double? _originalFare;
  double? _discountAmount;
  String? _promoCode;
  String _paymentMethod = 'cash';

  void _showLocationRequired() {
    final local = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(local.enableLocationPermission),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // ─── فتح WhereToScreen وانتظار النتيجة ───────────────────
  Future<void> _openSearch() async {
    if (_pickup == null) {
      _showLocationRequired();
      return;
    }

    final result = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => WhereToScreen(pickupLocation: _pickup),
      ),
    );

    if (result == null || !mounted) return;

    _applyDestination(result.address, result.lat, result.lng);
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
      _eta = (data['etaMinutes'] as num?)?.toInt();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر حساب السعر'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — تعذّر تحديد الموقع')),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذّر تحديد الموقع'),
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

    try {
      final promoCode = context.read<PromoProvider>().code;
      final ride = await RiderService.instance.createRide(
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        dropoffLat: _destLat!,
        dropoffLng: _destLng!,
        pickupAddress: _pickupLabel(context),
        dropoffAddress: _destination,
        vehicleType: widget.selectedVehicle,
        promoCode: promoCode,
        paymentMethod: _paymentMethod,
      );
      if (!mounted) return;
      if (promoCode != null) {
        await context.read<PromoProvider>().clear();
      }
      Navigator.pop(context); // ← سكّر الشيت
      widget.onRideCreated(ride); // ← أبلغ الـ HomeScreen
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: _confirming ? _buildConfirm() : _buildSearch(),
    );
  }

  // ════════════════════════════════════════════════════════
  // شاشة البحث
  // ════════════════════════════════════════════════════════
  Widget _buildSearch() {
    final local = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().passenger;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _handle(),
        const SizedBox(height: 16),

        Text(
          local.letsGo,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Pickup
        _locationRow(
          Icons.radio_button_checked,
          Colors.green,
          _pickupLabel(context),
        ),
        const SizedBox(height: 6),

        // Where To — الزر الرئيسي
        GestureDetector(
          onTap: _openSearch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Colors.red,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    local.whereTo,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white54,
                  size: 13,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Vehicles
        Row(
          children: [
            _vBtn('car', Icons.directions_car_filled_rounded, local.car),
            const SizedBox(width: 10),
            _vBtn('van', Icons.airport_shuttle_rounded, local.van),
            const SizedBox(width: 10),
            _vBtn('taxi', Icons.local_taxi_rounded, local.taxi),
          ],
        ),

        const SizedBox(height: 16),

        // Suggestions
        Text(
          local.suggestions,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),

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
        _suggTile(
          Icons.shopping_bag_outlined,
          'City Mall',
          'City Mall, Damascus',
          onTap: () => _applyDestination('City Mall', 33.5080, 36.2800),
        ),
      ],
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
                  'خصم $_promoCode: -${CurrencyUtils.formatSyp(_discountAmount)}',
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
                    '${_distKm?.toStringAsFixed(1) ?? '--'} km',
                    Colors.blue,
                  ),
                  _chip(
                    Icons.schedule_rounded,
                    '${_eta ?? '--'} دقيقة',
                    Colors.orange,
                  ),
                  _chip(
                    Icons.directions_car_rounded,
                    widget.selectedVehicle,
                    Colors.purple,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Text(
          'طريقة الدفع',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _payOption(
                Icons.money_rounded,
                'كاش',
                'cash',
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _payOption(
                Icons.phone_android_rounded,
                'شام كاش',
                'sham_cash',
                Colors.blue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // ─── زر التأكيد ─────────────────────────────────
        SizedBox(
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
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'تأكيد الرحلة',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ],
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

  Widget _vBtn(String type, IconData icon, String label) {
    final sel = widget.selectedVehicle == type;
    return GestureDetector(
      onTap: () => _onVehicleTap(type),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: sel ? Colors.black : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: sel ? Colors.white : Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: sel ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

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

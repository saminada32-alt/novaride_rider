import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/a11y.dart';

/// Vehicle, payment, and accessibility selectors shared by instant + scheduled booking.
class RideBookingOptions extends StatelessWidget {
  final String selectedVehicle;
  final String paymentMethod;
  final bool accessibilityRequired;
  final ValueChanged<String> onVehicleChanged;
  final ValueChanged<String> onPaymentChanged;
  final ValueChanged<bool> onAccessibilityChanged;

  const RideBookingOptions({
    super.key,
    required this.selectedVehicle,
    required this.paymentMethod,
    required this.accessibilityRequired,
    required this.onVehicleChanged,
    required this.onPaymentChanged,
    required this.onAccessibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final vehicles = [
      ('car', l.car, Icons.directions_car_rounded),
      ('van', l.van, Icons.airport_shuttle_rounded),
      ('taxi', l.taxi, Icons.local_taxi_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        A11yHeader(
          label: l.vehicleTypeLabel,
          child: Text(
            l.vehicleTypeLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: vehicles.map((v) {
            final selected = selectedVehicle == v.$1;
            return A11yButton(
              label: '${l.vehicleTypeLabel}: ${v.$2}',
              enabled: true,
              child: FilterChip(
                selected: selected,
                avatar: Icon(v.$3, size: 18),
                label: Text(v.$2),
                onSelected: (_) {
                  onAccessibilityChanged(false);
                  onVehicleChanged(v.$1);
                },
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        A11yHeader(
          label: l.paymentMethodLabel,
          child: Text(
            l.paymentMethodLabel,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: A11yButton(
                label: l.cashPayment,
                child: _payChip(
                  context,
                  l.cashPayment,
                  Icons.money_rounded,
                  'cash',
                  Colors.green,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: A11yButton(
                label: l.shamCashPayment,
                child: _payChip(
                  context,
                  l.shamCashPayment,
                  Icons.phone_android_rounded,
                  'sham_cash',
                  Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _payChip(
    BuildContext context,
    String label,
    IconData icon,
    String value,
    Color color,
  ) {
    final selected = paymentMethod == value;
    return GestureDetector(
      onTap: () => onPaymentChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : Colors.grey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                  color: selected ? color : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

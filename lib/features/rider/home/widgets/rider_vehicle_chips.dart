import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../rider_vehicle_options.dart';

/// Compact horizontal vehicle pills (Bolt-style).
class RiderVehicleChips extends StatelessWidget {
  final String selectedVehicle;
  final List<VehicleOption> vehicles;
  final void Function(String) onChanged;
  final AppLocalizations local;
  final bool compact;

  const RiderVehicleChips({
    super.key,
    required this.selectedVehicle,
    required this.vehicles,
    required this.onChanged,
    required this.local,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return SizedBox(
      height: compact ? 40 : 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = vehicles[i];
          final sel = selectedVehicle == v.id;
          final label = v.displayLabel(
            isAr,
            car: local.car,
            van: local.van,
            taxi: local.taxi,
            accessible: local.accessibleRide,
            moto: local.vehicleMoto,
          );

          return GestureDetector(
            onTap: () => onChanged(v.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 14,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: sel ? Colors.black : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: sel ? Colors.black : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    v.icon,
                    size: compact ? 16 : 18,
                    color: sel ? Colors.white : Colors.black87,
                  ),
                  if (!compact) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

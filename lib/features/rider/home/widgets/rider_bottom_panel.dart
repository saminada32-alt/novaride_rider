import 'package:flutter/material.dart';
import '../../../../core/widgets/a11y.dart';
import '../../../../l10n/app_localizations.dart';
import '../rider_vehicle_options.dart';
import 'rider_vehicle_chips.dart';

class RiderBottomPanel extends StatefulWidget {
  final String selectedVehicle;
  final List<VehicleOption> vehicles;
  final double surgeMultiplier;
  final String? surgeLabel;
  final void Function(String) onVehicleChanged;
  final VoidCallback onWhereTap;
  final VoidCallback onLaterTap;
  final AppLocalizations local;
  final ScrollController? scrollController;
  final double sheetSize;

  const RiderBottomPanel({
    super.key,
    required this.selectedVehicle,
    required this.vehicles,
    this.surgeMultiplier = 1.0,
    this.surgeLabel,
    required this.onVehicleChanged,
    required this.onWhereTap,
    required this.onLaterTap,
    required this.local,
    this.scrollController,
    this.sheetSize = 0.22,
  });

  @override
  State<RiderBottomPanel> createState() => _RiderBottomPanelState();
}

class _RiderBottomPanelState extends State<RiderBottomPanel> {
  bool get _expanded => widget.sheetSize > 0.35;

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Column(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down_rounded
                      : Icons.keyboard_arrow_up_rounded,
                  size: 22,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: A11yButton(
              label: widget.local.a11yWhereTo,
              child: Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: widget.onWhereTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: Colors.grey.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.local.whereTo,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 22,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: widget.onLaterTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 16,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.local.scheduleRide,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
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
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RiderVehicleChips(
              selectedVehicle: widget.selectedVehicle,
              vehicles: widget.vehicles,
              onChanged: widget.onVehicleChanged,
              local: widget.local,
              compact: !_expanded,
            ),
          ),
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.surgeMultiplier > 1.01)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bolt_rounded,
                            color: Colors.orange.shade800,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.local.surgeChipLabel(
                                widget.surgeMultiplier.toStringAsFixed(1),
                                widget.surgeLabel != null
                                    ? ' · ${widget.surgeLabel}'
                                    : '',
                              ),
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
                  ...widget.vehicles.map((v) => _rideTypeRow(v, isAr)),
                  const SizedBox(height: 4),
                  Text(
                    widget.local.pricesmayvary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ] else
            const SizedBox(height: 12),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 10),
        ],
      ),
    );
  }

  Widget _rideTypeRow(VehicleOption v, bool isAr) {
    final selected = widget.selectedVehicle == v.id;
    final label = v.displayLabel(
      isAr,
      car: widget.local.car,
      van: widget.local.van,
      taxi: widget.local.taxi,
      accessible: widget.local.accessibleRide,
      moto: widget.local.vehicleMoto,
    );
    final subtitle = v.displaySubtitle(isAr, widget.local);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? Colors.grey.shade100 : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => widget.onVehicleChanged(v.id),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(v.icon, size: 22, color: Colors.black87),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Colors.black,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

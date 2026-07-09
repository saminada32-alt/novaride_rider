import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/utils/ride_trip_status.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/ride_model.dart';
import '../rider_driver_avatar.dart';

class ActiveRideBanner extends StatefulWidget {
  final RideModel ride;
  final VoidCallback? onRefresh;
  final VoidCallback? onCall;
  final VoidCallback? onShamCashPay;
  final VoidCallback? onChat;
  final VoidCallback? onCancel;
  const ActiveRideBanner({
    super.key,
    required this.ride,
    this.onRefresh,
    this.onCall,
    this.onShamCashPay,
    this.onChat,
    this.onCancel,
  });
  @override
  State<ActiveRideBanner> createState() => ActiveRideBannerState();
}

class ActiveRideBannerState extends State<ActiveRideBanner>
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
                  if (ride.hasSplitFare) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        ride.splitFareFriendPaid
                            ? local.splitFarePaidStatus
                            : ride.splitFareDeclined
                            ? local.splitFareDeclinedStatus
                            : ride.splitFareAccepted
                            ? '${local.splitFarePrimaryShare}: ${CurrencyUtils.formatSyp((ride.splitFare!['primaryShare'] as num?)?.toDouble() ?? ride.estimatedFare)}'
                            : local.splitFarePending,
                        style: TextStyle(
                          color: Colors.purple.shade800,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

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
                            '${ride.etaMinutes} ${local.minutesShort}',
                            Colors.blue,
                          ),
                        if (ride.estimatedDistanceKm != null) ...[
                          const SizedBox(width: 10),
                          _infoChip(
                            Icons.straighten_rounded,
                            local.distanceKmUnit(
                              ride.estimatedDistanceKm!.toStringAsFixed(1),
                            ),
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
                          child: riderDriverAvatar(ride.driver, size: 44),
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
                    RideStatusSteps(status: status),
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
          'text': rideTripStatusLabel(s, local),
        };
    }
  }
}

// ─── Status Steps ─────────────────────────────────────────────
class RideStatusSteps extends StatelessWidget {
  final RideStatus status;
  const RideStatusSteps({super.key, required this.status});

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

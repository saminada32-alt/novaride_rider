import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/ride_model.dart';
import 'active_ride_ui.dart';

class RiderActiveRideBottomSheet extends StatelessWidget {
  final ScrollController scrollController;
  final RideModel ride;
  final AppLocalizations t;
  final bool audioRecording;
  final VoidCallback onToggleAudio;
  final VoidCallback? onRefresh;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onCancel;
  final VoidCallback? onSafety;
  final VoidCallback? onShamCashPay;

  const RiderActiveRideBottomSheet({
    super.key,
    required this.scrollController,
    required this.ride,
    required this.t,
    required this.audioRecording,
    required this.onToggleAudio,
    this.onRefresh,
    this.onMessage,
    this.onCall,
    this.onCancel,
    this.onSafety,
    this.onShamCashPay,
  });

  Future<void> _showMoreMenu(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSafety != null)
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(t.rideOpenSafety),
                onTap: () => Navigator.pop(ctx, 'safety'),
              ),
            if (onRefresh != null)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(t.retry),
                onTap: () => Navigator.pop(ctx, 'refresh'),
              ),
            if (onCancel != null &&
                (ride.status == RideStatus.searching ||
                    ride.status == RideStatus.driver_assigned ||
                    ride.status == RideStatus.driver_arrived))
              ListTile(
                leading: const Icon(Icons.cancel_outlined, color: Colors.red),
                title: Text(
                  t.cancel_ride,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(ctx, 'cancel'),
              ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (action == 'safety') onSafety?.call();
    if (action == 'refresh') onRefresh?.call();
    if (action == 'cancel') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(t.rideCancelTitle),
          content: Text(t.cancel_ride_confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(t.yes, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (ok == true) onCancel?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final driver = ride.driver;
    final driverName = driver == null
        ? ''
        : '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'.trim();
    final rating = driver?['rating']?.toString() ?? '5.0';
    final pickup = ride.pickupAddress ??
        '${ride.pickupLat.toStringAsFixed(4)}, ${ride.pickupLng.toStringAsFixed(4)}';
    final dropoff = ride.dropoffAddress ??
        '${ride.dropoffLat.toStringAsFixed(4)}, ${ride.dropoffLng.toStringAsFixed(4)}';
    final waypointLabels = ride.waypoints
        .map(
          (w) =>
              w.address ??
              '${w.lat.toStringAsFixed(4)}, ${w.lng.toStringAsFixed(4)}',
        )
        .toList();
    final etaHeadline = RiderActiveRideUi.etaHeroText(ride, t);
    final instruction = RiderActiveRideUi.instructionText(ride, t);
    final vehicleDesc = RiderActiveRideUi.vehicleSubtitle(ride.vehicle);
    final plate = RiderActiveRideUi.plateText(ride.vehicle);
    final showDriver = ride.hasDriver && ride.status != RideStatus.searching;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.zero,
        children: [
          RiderActiveRideUi.sheetHandle(),
          RiderActiveRideUi.etaHeadline(
            etaHeadline,
            loading: ride.status == RideStatus.searching,
          ),
          if (ride.status != RideStatus.searching)
            RiderActiveRideUi.safetyAudioCard(
              t: t,
              recording: audioRecording,
              onToggle: onToggleAudio,
            ),
          RiderActiveRideUi.tripInstructionCard(
            t: t,
            instruction: instruction,
            onMore: () => _showMoreMenu(context),
          ),
          if (showDriver)
            RiderActiveRideUi.driverCard(
              t: t,
              driverName: driverName,
              ratingText: rating,
              plate: plate,
              vehicleDesc: vehicleDesc,
              driver: driver,
              vehicle: ride.vehicle,
              onMessage: onMessage,
              onCall: onCall,
              onMore: () => _showMoreMenu(context),
            ),
          if (ride.hasSplitFare) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ride.splitFareFriendPaid
                      ? t.splitFarePaidStatus
                      : ride.splitFareDeclined
                          ? t.splitFareDeclinedStatus
                          : ride.splitFareAccepted
                              ? '${t.splitFarePrimaryShare}: ${CurrencyUtils.formatSyp((ride.splitFare!['primaryShare'] as num?)?.toDouble() ?? ride.estimatedFare)}'
                              : t.splitFarePending,
                  style: TextStyle(
                    color: Colors.purple.shade800,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          RiderActiveRideUi.fareRow(ride, t),
          RiderActiveRideUi.routeTimelineCard(
            t: t,
            pickup: pickup,
            dropoff: dropoff,
            waypointLabels: waypointLabels,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                RiderActiveRideUi.chip(
                  Icons.confirmation_number_outlined,
                  t.rideNumber(ride.id),
                  Colors.grey,
                ),
                if (ride.etaMinutes != null) ...[
                  const SizedBox(width: 8),
                  RiderActiveRideUi.chip(
                    Icons.schedule_rounded,
                    '${ride.etaMinutes} ${t.minutesShort}',
                    Colors.blue,
                  ),
                ],
                if (ride.estimatedDistanceKm != null) ...[
                  const SizedBox(width: 8),
                  RiderActiveRideUi.chip(
                    Icons.straighten_rounded,
                    t.distanceKmUnit(
                      ride.estimatedDistanceKm!.toStringAsFixed(1),
                    ),
                    Colors.orange,
                  ),
                ],
              ],
            ),
          ),
          if (ride.paymentMethod == 'sham_cash' &&
              onShamCashPay != null &&
              (ride.status == RideStatus.trip_started ||
                  ride.status == RideStatus.passenger_onboard)) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onShamCashPay,
                  icon: const Icon(Icons.phone_android_rounded, size: 18),
                  label: Text(t.shamCash),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
          if (onCancel != null &&
              (ride.status == RideStatus.searching ||
                  ride.status == RideStatus.driver_assigned ||
                  ride.status == RideStatus.driver_arrived)) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: onCancel,
                child: Text(
                  t.cancel_ride,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ],
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

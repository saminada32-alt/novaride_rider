import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/ride_model.dart';
import '../rider_driver_avatar.dart';

/// Uber/Bolt-style UI for the rider active-ride bottom sheet.
class RiderActiveRideUi {
  RiderActiveRideUi._();

  static const Color _uberBlack = Color(0xFF000000);
  static const Color _safetyBlue = Color(0xFFE8F4FD);

  static String etaHeroText(RideModel ride, AppLocalizations t) {
    final minutes = ride.etaMinutes ?? 0;
    switch (ride.status) {
      case RideStatus.searching:
        return t.findYourDriver;
      case RideStatus.driver_assigned:
      case RideStatus.driver_arrived:
        return minutes > 0
            ? t.activeRideMeetDriverEta(minutes)
            : ride.status == RideStatus.driver_arrived
                ? t.driverHasArrived
                : t.yourDriverIsOnTheWay;
      case RideStatus.passenger_onboard:
        return t.youAreOnBoard;
      case RideStatus.trip_started:
        return minutes > 0
            ? t.activeRideArriveDropoffEta(minutes)
            : t.headingToDestination;
      default:
        return t.yourDriverIsOnTheWay;
    }
  }

  static String instructionText(RideModel ride, AppLocalizations t) {
    switch (ride.status) {
      case RideStatus.searching:
        return t.findYourDriver;
      case RideStatus.driver_assigned:
      case RideStatus.driver_arrived:
        return t.activeRideMeetDriver;
      case RideStatus.passenger_onboard:
        return t.youAreOnBoard;
      case RideStatus.trip_started:
        return t.headingToDestination;
      default:
        return t.rideTripDetailsHint;
    }
  }

  static String vehicleSubtitle(Map<String, dynamic>? vehicle) {
    if (vehicle == null) return '';
    final color = vehicle['color']?.toString().trim() ?? '';
    final brand = vehicle['brand']?.toString().trim() ?? '';
    final model = vehicle['model']?.toString().trim() ?? '';
    return [color, brand, model].where((s) => s.isNotEmpty).join(' ');
  }

  static String plateText(Map<String, dynamic>? vehicle) =>
      vehicle?['plateNumber']?.toString().trim() ?? '';

  static Widget sheetHandle() => Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 6),
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      );

  static Widget etaHeadline(String text, {bool loading = false}) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  height: 1.25,
                  color: _uberBlack,
                ),
              ),
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
          ],
        ),
      );

  static Widget safetyAudioCard({
    required AppLocalizations t,
    required bool recording,
    required VoidCallback onToggle,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _safetyBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                recording ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: recording ? Colors.red.shade700 : Colors.blue.shade800,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recording ? t.safetyRecording : t.safetyRecordAudio,
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              TextButton(
                onPressed: onToggle,
                style: TextButton.styleFrom(
                  foregroundColor: recording ? Colors.red : Colors.blue.shade900,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                child: Text(
                  recording ? '■' : t.safetyRecordStart,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );

  static Widget tripInstructionCard({
    required AppLocalizations t,
    required String instruction,
    VoidCallback? onMore,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (onMore != null)
                IconButton(
                  onPressed: onMore,
                  icon: const Icon(Icons.more_horiz_rounded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  color: Colors.grey.shade700,
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.rideTripDetails,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      instruction,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.3,
                        color: _uberBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  static Widget driverCard({
    required AppLocalizations t,
    required String driverName,
    required String ratingText,
    required String plate,
    required String vehicleDesc,
    required Map<String, dynamic>? driver,
    required Map<String, dynamic>? vehicle,
    VoidCallback? onMessage,
    VoidCallback? onCall,
    VoidCallback? onMore,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    riderVehicleImage(vehicle, height: 64),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (plate.isNotEmpty)
                            Text(
                              plate,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: _uberBlack,
                                letterSpacing: 0.5,
                              ),
                            ),
                          if (vehicleDesc.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              vehicleDesc,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: riderDriverAvatar(driver, size: 64),
                        ),
                        const SizedBox(height: 8),
                        _ratingPill(ratingText),
                        const SizedBox(height: 6),
                        Text(
                          driverName.isNotEmpty ? driverName : t.rideDriverLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: _uberBlack,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (onMessage != null)
                      Expanded(
                        child: _contactButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: t.sendMessage,
                          onTap: onMessage,
                          expanded: true,
                        ),
                      ),
                    if (onCall != null) ...[
                      const SizedBox(width: 8),
                      _contactButton(icon: Icons.call_rounded, onTap: onCall),
                    ],
                    if (onMore != null) ...[
                      const SizedBox(width: 8),
                      _contactButton(
                        icon: Icons.more_horiz_rounded,
                        onTap: onMore,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  static Widget _ratingPill(String rating) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              rating,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: _uberBlack,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
          ],
        ),
      );

  static Widget _contactButton({
    required IconData icon,
    String? label,
    required VoidCallback onTap,
    bool expanded = false,
  }) =>
      Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 48,
            padding: EdgeInsets.symmetric(
              horizontal: expanded ? 16 : 0,
              vertical: 12,
            ),
            constraints: BoxConstraints(minWidth: expanded ? 0 : 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: _uberBlack),
                if (label != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: _uberBlack,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );

  static Widget routeTimelineCard({
    required AppLocalizations t,
    required String pickup,
    required String dropoff,
    required List<String> waypointLabels,
  }) =>
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _routeRow(
                Colors.green,
                Icons.radio_button_checked_rounded,
                t.ridePickupLabel,
                pickup,
              ),
              Container(
                margin: const EdgeInsets.only(left: 11),
                width: 2,
                height: 16,
                color: Colors.grey.shade300,
              ),
              for (var i = 0; i < waypointLabels.length; i++) ...[
                _routeRow(
                  Colors.amber,
                  Icons.pin_drop_rounded,
                  '${t.multiStopLabel} ${i + 1}',
                  waypointLabels[i],
                ),
                Container(
                  margin: const EdgeInsets.only(left: 11),
                  width: 2,
                  height: 16,
                  color: Colors.grey.shade300,
                ),
              ],
              _routeRow(
                Colors.red,
                Icons.location_on_rounded,
                t.rideDropoffLabel,
                dropoff,
              ),
            ],
          ),
        ),
      );

  static Widget _routeRow(Color c, IconData icon, String title, String sub) =>
      Row(
        children: [
          Icon(icon, color: c, size: 22),
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
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      );

  static Widget chip(IconData icon, String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
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

  static Widget mapDistanceChip(String text) => Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: _uberBlack,
            ),
          ),
        ),
      );

  static Widget mapPickupLabel(String text) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        color: _uberBlack,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );

  static Widget fareRow(RideModel ride, AppLocalizations t) {
    if (ride.estimatedFare == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Text(
        CurrencyUtils.formatSyp(ride.estimatedFare),
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 18,
          color: _uberBlack,
        ),
      ),
    );
  }
}

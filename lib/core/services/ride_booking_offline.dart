import '../../features/rider/models/ride_model.dart';
import '../../features/rider/services/rider_service.dart';
import 'offline_ride_queue_service.dart';

/// Shared instant + scheduled booking with offline queue fallback.
class RideBookingOffline {
  RideBookingOffline._();

  static bool isNetworkError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('socket') ||
        msg.contains('timeout') ||
        msg.contains('failed host') ||
        msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('clientexception');
  }

  static bool payloadIsScheduled(Map<String, dynamic> payload) =>
      payload['scheduledAt'] != null &&
      payload['scheduledAt'].toString().isNotEmpty;

  static Future<({bool queued, RideModel? ride})> submit(
    Map<String, dynamic> payload,
  ) async {
    try {
      final ride = await RiderService.instance.createRideFromPayload(payload);
      return (queued: false, ride: ride);
    } catch (e) {
      if (isNetworkError(e)) {
        await OfflineRideQueueService.instance.enqueue(payload);
        return (queued: true, ride: null);
      }
      rethrow;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../services/network_connectivity_service.dart';
import '../services/offline_ride_queue_service.dart';

/// Shows pending offline bookings count and flush status.
class OfflineQueueBanner extends StatelessWidget {
  const OfflineQueueBanner({super.key});

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: OfflineRideQueueService.instance,
      builder: (context, _) {
        final queue = OfflineRideQueueService.instance;
        if (queue.count == 0) return const SizedBox.shrink();

        final l = AppLocalizations.of(context)!;
        final net = context.watch<NetworkConnectivityService>();
        final flushing = queue.isFlushing;
        final scheduled = queue.pending
            .where((q) => q.payload['scheduledAt'] != null)
            .length;
        final instant = queue.count - scheduled;

        String message;
        if (flushing) {
          message = l.offlineQueueFlushing;
        } else if (net.isOnline) {
          message = l.offlineQueuePendingOnline(queue.count);
        } else if (scheduled > 0 && instant > 0) {
          message = l.offlineQueuePendingMixed(scheduled, instant);
        } else if (scheduled > 0) {
          message = l.offlineQueuePendingScheduled(scheduled);
        } else {
          message = l.offlineQueuePendingInstant(instant);
        }

        return Semantics(
          liveRegion: true,
          label: message,
          child: Material(
            color: flushing ? Colors.blue.shade700 : Colors.orange.shade800,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

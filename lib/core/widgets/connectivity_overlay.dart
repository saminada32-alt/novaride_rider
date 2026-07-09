import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../services/app_controller.dart';
import '../services/network_connectivity_service.dart';
import '../services/offline_ride_queue_service.dart';
import '../widjets/no_internet_screen.dart';
import 'a11y.dart';
import 'offline_queue_banner.dart';

/// Global banner when offline or on a weak network + offline booking queue.
class ConnectivityOverlay extends StatefulWidget {
  final Widget child;

  const ConnectivityOverlay({super.key, required this.child});

  static const double _networkBannerHeight = 52;

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  AppNetworkStatus? _lastStatus;
  int _lastQueueCount = 0;

  @override
  void initState() {
    super.initState();
    OfflineRideQueueService.instance.load();
  }

  Future<void> _onBackOnline() async {
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    announceForAccessibility(context, l.offlineQueueFlushing);
    await OfflineRideQueueService.instance.flush(
      onSubmitted: (_) {
        if (!mounted) return;
        final left = OfflineRideQueueService.instance.count;
        if (left == 0) {
          announceForAccessibility(
            context,
            l.offlineQueueFlushDone,
          );
        }
      },
    );
  }

  void _onStatusChange(AppNetworkStatus status) {
    if (_lastStatus != AppNetworkStatus.online &&
        status == AppNetworkStatus.online) {
      if (OfflineRideQueueService.instance.count > 0) {
        _onBackOnline();
      }
    }
    _lastStatus = status;
  }

  void _onQueueChange(int count) {
    if (count < _lastQueueCount && count == 0 && mounted) {
      final l = AppLocalizations.of(context)!;
      announceForAccessibility(context, l.offlineQueueFlushDone);
    }
    _lastQueueCount = count;
  }

  @override
  Widget build(BuildContext context) {
    final net = context.watch<NetworkConnectivityService>();
    _onStatusChange(net.status);

    return ListenableBuilder(
      listenable: OfflineRideQueueService.instance,
      builder: (context, _) {
        final queueCount = OfflineRideQueueService.instance.count;
        _onQueueChange(queueCount);

        final showNetworkBanner = net.status != AppNetworkStatus.online;
        final showQueueBanner = queueCount > 0;
        final topPad = (showNetworkBanner ? ConnectivityOverlay._networkBannerHeight : 0) +
            (showQueueBanner ? OfflineQueueBanner.height : 0);

        return Stack(
          children: [
            AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(top: topPad.toDouble()),
              child: widget.child,
            ),
            if (showNetworkBanner)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: NoInternetWidget(
                    status: net.status,
                    isArabic: context.watch<AppController>().isArabic,
                    onRetry: net.probe,
                  ),
                ),
              ),
            if (showQueueBanner)
              Positioned(
                top: showNetworkBanner ? ConnectivityOverlay._networkBannerHeight : 0,
                left: 0,
                right: 0,
                child: const SafeArea(
                  bottom: false,
                  child: OfflineQueueBanner(),
                ),
              ),
          ],
        );
      },
    );
  }
}

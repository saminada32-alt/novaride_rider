import 'package:flutter/material.dart';
import '../../../core/services/notification_inbox_service.dart';
import '../../../core/widgets/a11y.dart';
import '../../../core/widgets/empty_illustration.dart';
import '../../../l10n/app_localizations.dart';
import '../account/familyprofile/familyprofile_screen.dart';
import '../chat/ride_chat_screen.dart';
import '../rides/my_rides_screen.dart';
import '../split_fare/split_fare_invites_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await NotificationInboxService.instance.loadFromApi();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openNotification(AppNotificationItem n) async {
    await NotificationInboxService.instance.markRead(n.id);
    if (mounted) setState(() {});
    if (!mounted) return;

    final rideId = int.tryParse(n.data['rideId']?.toString() ?? '');

    switch (n.type) {
      case 'RIDE_UPDATE':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MyRidesScreen()),
        );
        break;
      case 'CHAT_MESSAGE':
        if (rideId != null) {
          final local = AppLocalizations.of(context)!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RideChatScreen(
                mode: ChatMode.ride,
                rideId: rideId,
                title: local.chatWithDriver,
              ),
            ),
          );
        }
        break;
      case 'FAMILY_INVITE':
      case 'FAMILY_ACCEPT':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FamilyProfileScreen()),
        );
        break;
      case 'SPLIT_FARE_INVITE':
      case 'SPLIT_FARE_PAY':
      case 'SPLIT_FARE_ACCEPTED':
      case 'SPLIT_FARE_DECLINED':
      case 'SPLIT_FARE_PAID':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SplitFareInvitesScreen()),
        );
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final items = NotificationInboxService.instance.items;

    return A11yScreen(
      label: local.notificationsTitle,
      child: Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.notificationsTitle)),
        centerTitle: true,
        actions: [
          if (items.any((n) => !n.read))
            TextButton(
              onPressed: () async {
                await NotificationInboxService.instance.markAllRead();
                if (mounted) setState(() {});
              },
              child: Text(local.markAllRead),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : items.isEmpty
              ? EmptyIllustration(
                  imageAsset: 'assets/images/Push notifications-bro.png',
                  message: local.notificationsEmpty,
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = items[i];
                      return Material(
                        color: n.read ? Colors.grey.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(14),
                        child: ListTile(
                          title: Text(
                            n.title,
                            style: TextStyle(
                              fontWeight:
                                  n.read ? FontWeight.w500 : FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(n.body),
                          trailing: n.read
                              ? null
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                          onTap: () => _openNotification(n),
                        ),
                      );
                    },
                  ),
                ),
    ),
    );
  }
}

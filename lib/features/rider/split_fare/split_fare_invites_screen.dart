import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../payments/sham_cash_sheet.dart';
import 'split_fare_service.dart';

class SplitFareInvitesScreen extends StatefulWidget {
  const SplitFareInvitesScreen({super.key});

  @override
  State<SplitFareInvitesScreen> createState() => _SplitFareInvitesScreenState();
}

class _SplitFareInvitesScreenState extends State<SplitFareInvitesScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _invites = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await SplitFareService.instance.listMyInvites();
      if (mounted) setState(() => _invites = rows);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedToLoad)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String token) async {
    try {
      await SplitFareService.instance.acceptInvite(token);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.splitFareAccepted)),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _decline(String token) async {
    try {
      await SplitFareService.instance.declineInvite(token);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

    return A11yScreen(
      label: t.splitFareInvitesTitle,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.splitFareInvitesTitle),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.green))
            : _invites.isEmpty
                ? Center(child: Text(t.splitFareInvitesEmpty))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _invites.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _inviteCard(context, _invites[i], t),
                    ),
                  ),
      ),
    );
  }

  Widget _inviteCard(
    BuildContext context,
    Map<String, dynamic> invite,
    AppLocalizations t,
  ) {
    final status = invite['status']?.toString() ?? 'pending';
    final ride = invite['ride'] as Map<String, dynamic>?;
    final inviter = invite['inviter'] as Map<String, dynamic>?;
    final name = [
      inviter?['firstName'],
      inviter?['lastName'],
    ].where((e) => e != null && '$e'.isNotEmpty).join(' ');
    final share = (invite['shareAmount'] as num?)?.toDouble()
        ?? (invite['estimatedShareAmount'] as num?)?.toDouble();
    final rideId = invite['rideId'] as int? ?? ride?['id'] as int?;
    final token = invite['token']?.toString() ?? '';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name.isEmpty ? t.splitFareFriendInvite : '$name — ${t.splitFareTitle}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (ride != null) ...[
              const SizedBox(height: 6),
              Text(
                '${ride['pickupAddress'] ?? ''} → ${ride['dropoffAddress'] ?? ''}',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (share != null) ...[
              const SizedBox(height: 8),
              Text(
                '${t.splitFareYourShare}: ${CurrencyUtils.formatSyp(share)} (${invite['sharePercent']}%)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 12),
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _decline(token),
                      child: Text(t.splitFareDecline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _accept(token),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text(t.splitFareAccept),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'accepted' && rideId != null) ...[
              Text(t.splitFareAcceptedStatus, style: TextStyle(color: Colors.green.shade700)),
              if (ride?['status']?.toString() == 'completed'
                  && ride?['paymentMethod']?.toString() == 'sham_cash'
                  && invite['friendPaid'] != true) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => showShamCashPaymentSheet(
                      context,
                      rideId: rideId,
                      estimatedFare: share,
                      isSplitFriend: true,
                    ),
                    child: Text(t.splitFarePayShare),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

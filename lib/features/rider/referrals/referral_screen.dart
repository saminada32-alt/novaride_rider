import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import 'referral_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  ReferralStats? _stats;
  bool _loading = true;
  final _applyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final s = await ReferralService.instance.getMyStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l.referralTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.referralYourCode, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _stats?.code ?? '—',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        onPressed: _stats?.code == null
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: _stats!.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l.referralCopied)),
                                );
                              },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _statRow(l.referralTotal, '${_stats?.totalReferrals ?? 0}'),
                  _statRow(l.referralRewarded, '${_stats?.rewarded ?? 0}'),
                  _statRow(l.referralPending, '${_stats?.pending ?? 0}'),
                  _statRow(
                    l.referralEarned,
                    CurrencyUtils.formatSyp(_stats?.totalEarned ?? 0),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _applyCtrl,
                    decoration: InputDecoration(
                      labelText: l.referralApplyHint,
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      try {
                        await ReferralService.instance.applyCode(_applyCtrl.text);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.referralApplied)),
                        );
                        _applyCtrl.clear();
                        _load();
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
                    },
                    child: Text(l.referralApply),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

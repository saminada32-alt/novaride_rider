import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';
import 'wallet_transactions_screen.dart';
import 'work_profile_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});
  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  double _balance = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _methods = [];
  String? _shamPhone;
  String? _shamAccount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _balance = await RiderService.instance.getWalletBalance();
      final cfg = await RiderService.instance.getPaymentsConfig();
      final methods = cfg['methods'];
      if (methods is List) {
        _methods = methods.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      _shamPhone = cfg['shamCashPhone'] as String?;
      _shamAccount = cfg['shamCashAccountName'] as String?;
    } catch (_) {
      // Wallet/config may fail offline — show balance fallback only.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return A11yScreen(
      label: local.payment,
      child: Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.payment)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              color: Colors.green,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Balance Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade800],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          local.balance,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          CurrencyUtils.formatSyp(_balance),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          local.availableBalance,
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.help_outline),
                    title: Text(local.whatIsBalance),
                    onTap: () => _openBalanceInfo(context, local),
                  ),

                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_long),
                    title: Text(local.seeBalanceTransactions),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WalletTransactionsScreen(),
                      ),
                    ),
                  ),

                  const Divider(height: 32),

                  Text(
                    local.paymentMethods,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_methods.isNotEmpty)
                    ..._methods.map((m) {
                      final id = m['id'] as String? ?? '';
                      final isAr = Localizations.localeOf(context).languageCode == 'ar';
                      final title = isAr
                          ? (m['labelAr'] as String? ?? id)
                          : (m['labelEn'] as String? ?? id);
                      final desc = isAr
                          ? (m['descriptionAr'] as String?)
                          : (m['descriptionEn'] as String?);
                      final icon = id == 'sham_cash'
                          ? Icons.phone_iphone
                          : Icons.money;
                      return Column(
                        children: [
                          _methodTile(
                            context,
                            icon,
                            title,
                            subtitle: desc,
                            trailingDetail: id == 'sham_cash' && _shamPhone != null
                                ? '$_shamPhone${_shamAccount != null ? ' · $_shamAccount' : ''}'
                                : null,
                          ),
                          const SizedBox(height: 4),
                        ],
                      );
                    })
                  else ...[
                    _methodTile(context, Icons.phone_iphone, local.shamCash),
                    _methodTile(context, Icons.money, local.cash),
                  ],

                  const Divider(height: 32),

                  ListTile(
                    leading: const Icon(Icons.work_outline),
                    title: Text(
                      local.workProfile,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(local.workProfileDesc),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkProfileScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    ),
    );
  }

  void _openBalanceInfo(BuildContext context, AppLocalizations local) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  controller: ctrl,
                  children: [
                    Text(
                      local.whatIsBalance,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(local.balanceDesc),
                    const SizedBox(height: 20),
                    Text(
                      local.howToTopUp,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(local.topUpExplanation),
                    const SizedBox(height: 16),

                    // Payment methods icons
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _iconMethod(
                            local.shamCash,
                            Colors.orange,
                            Icons.account_balance,
                          ),
                          const SizedBox(width: 12),
                          _iconMethod(local.cashPayment, Colors.green, Icons.money),
                          const SizedBox(width: 12),
                          _iconMethod(local.cardPayment, Colors.blue, Icons.credit_card),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Text(
                      local.howToUseBalance,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(local.howToUseBalanceDesc),
                    const SizedBox(height: 16),

                    _faq(
                      local.whyNegativeBalance,
                      local.whyNegativeBalanceDesc,
                    ),
                    _faq(local.balanceExpire, local.balanceExpireDesc),
                    _faq(local.withdrawBalance, local.withdrawBalanceDesc),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconMethod(String name, Color color, IconData icon) => Container(
    width: 100,
    decoration: BoxDecoration(
      color: color.withOpacity(.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(.3)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _faq(String q, String a) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(q, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(a),
      ],
    ),
  );

  Widget _methodTile(
    BuildContext context,
    IconData icon,
    String title, {
    String? subtitle,
    String? trailingDetail,
    bool comingSoon = false,
  }) =>
      ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle != null || trailingDetail != null
        ? Text(
            [subtitle, trailingDetail].whereType<String>().join('\n'),
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          )
        : null,
    trailing: comingSoon
        ? Text(
            AppLocalizations.of(context)!.comingSoon,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          )
        : const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
    onTap: comingSoon
        ? () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.comingSoon),
              ),
            )
        : null,
  );
}

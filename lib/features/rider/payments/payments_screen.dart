import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
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

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    setState(() => _loading = true);
    _balance = await RiderService.instance.getWalletBalance();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.payment), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              color: Colors.green,
              onRefresh: _loadBalance,
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
                        const Text(
                          'Available Balance',
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

                  _methodTile(context, Icons.phone_iphone, local.shamCash, comingSoon: true),
                  _methodTile(context, Icons.money, local.cash, comingSoon: true),
                  _methodTile(context, Icons.add, local.addCard, comingSoon: true),

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
                            'Sham Cash',
                            Colors.orange,
                            Icons.account_balance,
                          ),
                          const SizedBox(width: 12),
                          _iconMethod('Cash', Colors.green, Icons.money),
                          const SizedBox(width: 12),
                          _iconMethod('Card', Colors.blue, Icons.credit_card),
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
    bool comingSoon = false,
  }) =>
      ListTile(
    leading: Icon(icon),
    title: Text(title),
    trailing: const Icon(Icons.chevron_right),
    onTap: comingSoon
        ? () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.comingSoon),
              ),
            )
        : null,
  );
}

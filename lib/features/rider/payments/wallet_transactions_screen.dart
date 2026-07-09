import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';
import 'wallet_transaction.dart';

class WalletTransactionsScreen extends StatefulWidget {
  const WalletTransactionsScreen({super.key});

  @override
  State<WalletTransactionsScreen> createState() =>
      _WalletTransactionsScreenState();
}

class _WalletTransactionsScreenState extends State<WalletTransactionsScreen> {
  List<WalletTransaction> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await RiderService.instance.getWalletTransactions();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.seeBalanceTransactions,
      child: Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.seeBalanceTransactions)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: Text(l.retry),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: Colors.green,
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.25,
                        ),
                        Center(
                          child: Text(
                            l.noTransactions,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _tile(_items[i]),
                    ),
            ),
    ),
    );
  }

  Widget _tile(WalletTransaction t) {
    final isDebit = t.amount < 0;
    final route = [
      if (t.pickupAddress?.trim().isNotEmpty == true) t.pickupAddress!.trim(),
      if (t.dropoffAddress?.trim().isNotEmpty == true) t.dropoffAddress!.trim(),
    ].join(' → ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: (isDebit ? Colors.red : Colors.green)
                .withOpacity(.12),
            child: Icon(
              isDebit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDebit ? Colors.red : Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.type.replaceAll('_', ' '),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (route.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    route,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
                if (t.paymentMethod != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    t.paymentMethod!,
                    style: const TextStyle(fontSize: 11, color: Colors.black45),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  _fmtDate(t.createdAt),
                  style: const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Text(
            CurrencyUtils.formatSyp(t.amount.abs()),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDebit ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

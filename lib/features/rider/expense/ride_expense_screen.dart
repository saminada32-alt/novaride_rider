import 'package:flutter/material.dart';

import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';
import 'expense_period.dart';
import 'ride_expense_export.dart';
import 'ride_expense_export_service.dart';

class RideExpensesScreen extends StatefulWidget {
  const RideExpensesScreen({super.key});

  @override
  State<RideExpensesScreen> createState() => _RideExpensesScreenState();
}

class _RideExpensesScreenState extends State<RideExpensesScreen> {
  List<RideModel> _allCompleted = [];
  ExpensePeriodType _period = ExpensePeriodType.thisMonth;
  DateTime? _customStart;
  DateTime? _customEnd;
  bool _loading = true;
  bool _exporting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  ({DateTime start, DateTime endExclusive}) get _range => expenseDateRange(
        type: _period,
        customStart: _customStart,
        customEndInclusive: _customEnd,
      );

  String _periodLabel(AppLocalizations local) => expensePeriodLabel(
        type: _period,
        thisMonthText: local.thisMonth,
        lastMonthText: local.lastMonth,
        customStart: _customStart,
        customEndInclusive: _customEnd,
        locale: Localizations.localeOf(context).toString(),
      );

  List<RideModel> get _rides {
    final range = _range;
    return _allCompleted.where((r) {
      return isRideInExpenseRange(
        r.completedAt ?? r.createdAt,
        range.start,
        range.endExclusive,
      );
    }).toList()
      ..sort((a, b) {
        final da = a.completedAt ?? a.createdAt ?? DateTime(0);
        final db = b.completedAt ?? b.createdAt ?? DateTime(0);
        return db.compareTo(da);
      });
  }

  double get _total =>
      _rides.fold(0.0, (s, r) => s + (r.estimatedFare ?? 0));

  double get _saved => _rides.fold(
        0.0,
        (s, r) => s + (r.discountAmount ?? 0),
      );

  Map<String, double> get _byPayment {
    final map = <String, double>{};
    for (final r in _rides) {
      final key = r.paymentMethod ?? 'other';
      map[key] = (map[key] ?? 0) + (r.estimatedFare ?? 0);
    }
    return map;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rides = await RiderService.instance.getMyRides();
      _allCompleted = rides.where((r) => r.isCompleted).toList();
    } catch (e) {
      _error = e.toString();
      _allCompleted = [];
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  ExpenseCsvLabels _csvLabels(AppLocalizations local) => ExpenseCsvLabels(
        title: local.expenseCsvTitle,
        period: local.expenseCsvPeriod,
        generated: local.expenseCsvGenerated,
        total: local.expenseCsvTotal,
        rideCount: local.expenseCsvRideCount,
        colRideId: local.expenseCsvColRideId,
        colDate: local.expenseCsvColDate,
        colFrom: local.expenseCsvColFrom,
        colTo: local.expenseCsvColTo,
        colAmount: local.expenseCsvColAmount,
        colPayment: local.expenseCsvColPayment,
        colPromo: local.expenseCsvColPromo,
        colDiscount: local.expenseCsvColDiscount,
        colDistance: local.expenseCsvColDistance,
        currency: local.expenseCsvCurrency,
      );

  Future<void> _export(AppLocalizations local) async {
    if (_rides.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(local.exportNoRides)),
      );
      return;
    }

    setState(() => _exporting = true);
    final periodLabel = _periodLabel(local);
    final periodSlug = expensePeriodSlug(
      type: _period,
      customStart: _customStart,
      customEndInclusive: _customEnd,
    );

    try {
      await RideExpenseExportService.instance.exportPeriod(
        labels: _csvLabels(local),
        periodLabel: periodLabel,
        periodSlug: periodSlug,
        rides: _rides,
        total: _total,
        saved: _saved,
        shareSubject: local.exportReport,
        paymentLabel: (key) => _paymentLabel(local, key ?? 'other'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.exportSuccess),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(local.exportFailed),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _paymentLabel(AppLocalizations local, String key) {
    switch (key) {
      case 'cash':
        return local.cash;
      case 'sham_cash':
        return local.shamCash;
      case 'balance':
        return local.balance;
      case 'card':
        return local.paymentCard;
      default:
        return local.other;
    }
  }

  IconData _paymentIcon(String key) {
    switch (key) {
      case 'cash':
        return Icons.payments_outlined;
      case 'sham_cash':
        return Icons.account_balance_wallet_outlined;
      case 'balance':
        return Icons.account_balance_outlined;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.more_horiz;
    }
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  String _route(RideModel r) {
    final from = r.pickupAddress?.trim();
    final to = r.dropoffAddress?.trim();
    if (from != null && from.isNotEmpty && to != null && to.isNotEmpty) {
      return '$from → $to';
    }
    return 'Ride #${r.id}';
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final rides = _rides;
    final payments = _byPayment.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return A11yScreen(
      label: local.rideExpenses,
      child: Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.rideExpenses)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : _error != null
              ? _errorView(local)
              : RefreshIndicator(
                  color: Colors.green,
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _periodSelector(local),
                      const SizedBox(height: 16),
                      _summaryCard(local, rides),
                      if (_saved > 0) ...[
                        const SizedBox(height: 12),
                        _promoBanner(local),
                      ],
                      if (payments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          local.expenseBreakdown,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...payments.map(
                          (e) => _paymentRow(
                            local,
                            e.key,
                            e.value,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text(
                        local.rides,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (rides.isEmpty)
                        _emptyState(local)
                      else
                        ...rides.map((r) => _rideCard(local, r)),
                      const SizedBox(height: 24),
                      Text(
                        local.exportReportHint,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: rides.isEmpty || _exporting
                              ? null
                              : () => _export(local),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.download_rounded),
                          label: Text(
                            _exporting
                                ? local.exportInProgress
                                : local.exportReport,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    ),
    );
  }

  Widget _errorView(AppLocalizations local) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _load,
                child: Text(local.retry),
              ),
            ],
          ),
        ),
      );

  Future<void> _pickCustomRange(AppLocalizations local) async {
    final defaults = defaultCustomRange();
    final initial = DateTimeRange(
      start: _customStart ?? defaults.$1,
      end: _customEnd ?? defaults.$2,
    );
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: local.expenseSelectDateRange,
      saveText: local.save,
      cancelText: local.cancel,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customStart = startOfDay(picked.start);
      _customEnd = startOfDay(picked.end);
    });
  }

  void _selectCustomPeriod(AppLocalizations local) {
    final defaults = defaultCustomRange();
    setState(() {
      _period = ExpensePeriodType.custom;
      _customStart ??= defaults.$1;
      _customEnd ??= defaults.$2;
    });
  }

  Widget _periodSelector(AppLocalizations local) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _periodChip(
                    local.thisMonth,
                    _period == ExpensePeriodType.thisMonth,
                    () => setState(() => _period = ExpensePeriodType.thisMonth),
                    compact: true,
                  ),
                ),
                Expanded(
                  child: _periodChip(
                    local.lastMonth,
                    _period == ExpensePeriodType.lastMonth,
                    () => setState(() => _period = ExpensePeriodType.lastMonth),
                    compact: true,
                  ),
                ),
                Expanded(
                  child: _periodChip(
                    local.expenseCustomRange,
                    _period == ExpensePeriodType.custom,
                    () => _selectCustomPeriod(local),
                    compact: true,
                  ),
                ),
              ],
            ),
            if (_period == ExpensePeriodType.custom) ...[
              const SizedBox(height: 8),
              Material(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _pickCustomRange(local),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          color: Colors.green.shade700,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _periodLabel(local),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                local.expenseTapToChangeDates,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.edit_outlined, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  Widget _periodChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool compact = false,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: compact ? 12 : 14,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );

  Widget _summaryCard(AppLocalizations local, List<RideModel> rides) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade700],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _periodLabel(local),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyUtils.formatSyp(_total),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _stat(
                    Icons.directions_car_outlined,
                    local.totalRides,
                    '${rides.length}',
                  ),
                ),
                Expanded(
                  child: _stat(
                    Icons.trending_flat,
                    local.avgRide,
                    rides.isEmpty
                        ? '--'
                        : CurrencyUtils.formatSypCompact(
                            _total / rides.length,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _stat(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: Colors.white70, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _promoBanner(AppLocalizations local) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_outlined, color: Colors.amber.shade800),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${local.promoSaved} ${CurrencyUtils.formatSyp(_saved)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _paymentRow(AppLocalizations local, String key, double amount) {
    final pct = _total > 0 ? amount / _total : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(_paymentIcon(key), color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _paymentLabel(local, key),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    color: Colors.green,
                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            CurrencyUtils.formatSyp(amount),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _rideCard(AppLocalizations local, RideModel r) {
    final hasDiscount = (r.discountAmount ?? 0) > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.local_taxi, color: Colors.green.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _route(r),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmtDate(r.completedAt ?? r.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (r.paymentMethod != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _paymentLabel(local, r.paymentMethod!),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyUtils.formatSyp(r.estimatedFare),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
              if (hasDiscount)
                Text(
                  '-${CurrencyUtils.formatSyp(r.discountAmount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber.shade800,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(AppLocalizations local) => Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              local.noData,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
}

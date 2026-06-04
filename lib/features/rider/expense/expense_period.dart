import 'package:intl/intl.dart';

enum ExpensePeriodType { thisMonth, lastMonth, custom }

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime dayAfter(DateTime d) => startOfDay(d).add(const Duration(days: 1));

/// Inclusive start, exclusive end (midnight after last day).
({DateTime start, DateTime endExclusive}) expenseDateRange({
  required ExpensePeriodType type,
  DateTime? customStart,
  DateTime? customEndInclusive,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  switch (type) {
    case ExpensePeriodType.thisMonth:
      return (
        start: DateTime(clock.year, clock.month, 1),
        endExclusive: DateTime(clock.year, clock.month + 1, 1),
      );
    case ExpensePeriodType.lastMonth:
      final last = DateTime(clock.year, clock.month - 1, 1);
      return (
        start: last,
        endExclusive: DateTime(clock.year, clock.month, 1),
      );
    case ExpensePeriodType.custom:
      final start = startOfDay(customStart ?? clock.subtract(const Duration(days: 29)));
      final endInc = startOfDay(customEndInclusive ?? clock);
      final endExclusive = dayAfter(
        endInc.isBefore(start) ? start : endInc,
      );
      return (start: start, endExclusive: endExclusive);
  }
}

bool isRideInExpenseRange(
  DateTime? rideAt,
  DateTime rangeStart,
  DateTime rangeEndExclusive,
) {
  if (rideAt == null) return false;
  final d = rideAt.toLocal();
  return !d.isBefore(rangeStart) && d.isBefore(rangeEndExclusive);
}

String expensePeriodLabel({
  required ExpensePeriodType type,
  required String thisMonthText,
  required String lastMonthText,
  DateTime? customStart,
  DateTime? customEndInclusive,
  String? locale,
}) {
  switch (type) {
    case ExpensePeriodType.thisMonth:
      return thisMonthText;
    case ExpensePeriodType.lastMonth:
      return lastMonthText;
    case ExpensePeriodType.custom:
      final fmt = DateFormat.yMMMd(locale);
      final a = customStart ?? DateTime.now();
      final b = customEndInclusive ?? a;
      return '${fmt.format(a)} — ${fmt.format(b)}';
  }
}

String expensePeriodSlug({
  required ExpensePeriodType type,
  DateTime? customStart,
  DateTime? customEndInclusive,
}) {
  switch (type) {
    case ExpensePeriodType.thisMonth:
      return 'this_month';
    case ExpensePeriodType.lastMonth:
      return 'last_month';
    case ExpensePeriodType.custom:
      final s = customStart ?? DateTime.now();
      final e = customEndInclusive ?? s;
      String p(DateTime d) =>
          '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      return 'custom_${p(s)}_${p(e)}';
  }
}

/// Default custom range: last 30 days through today.
(DateTime start, DateTime end) defaultCustomRange({DateTime? now}) {
  final clock = startOfDay(now ?? DateTime.now());
  return (clock.subtract(const Duration(days: 29)), clock);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:novaride_rider/features/rider/expense/expense_period.dart';

void main() {
  final clock = DateTime(2025, 5, 15, 14, 30);

  test('thisMonth range', () {
    final r = expenseDateRange(type: ExpensePeriodType.thisMonth, now: clock);
    expect(r.start, DateTime(2025, 5, 1));
    expect(r.endExclusive, DateTime(2025, 6, 1));
    expect(
      isRideInExpenseRange(DateTime(2025, 5, 10), r.start, r.endExclusive),
      isTrue,
    );
    expect(
      isRideInExpenseRange(DateTime(2025, 4, 30), r.start, r.endExclusive),
      isFalse,
    );
  });

  test('custom range is inclusive on end day', () {
    final r = expenseDateRange(
      type: ExpensePeriodType.custom,
      customStart: DateTime(2025, 5, 1),
      customEndInclusive: DateTime(2025, 5, 3),
      now: clock,
    );
    expect(r.start, DateTime(2025, 5, 1));
    expect(r.endExclusive, DateTime(2025, 5, 4));
    expect(
      isRideInExpenseRange(
        DateTime(2025, 5, 3, 23, 59),
        r.start,
        r.endExclusive,
      ),
      isTrue,
    );
    expect(
      isRideInExpenseRange(DateTime(2025, 5, 4), r.start, r.endExclusive),
      isFalse,
    );
  });

  test('custom slug encodes dates', () {
    expect(
      expensePeriodSlug(
        type: ExpensePeriodType.custom,
        customStart: DateTime(2025, 1, 5),
        customEndInclusive: DateTime(2025, 1, 20),
      ),
      'custom_20250105_20250120',
    );
  });
}

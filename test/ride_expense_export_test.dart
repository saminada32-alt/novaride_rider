import 'package:flutter_test/flutter_test.dart';
import 'package:novaride_rider/features/rider/expense/ride_expense_export.dart';
import 'package:novaride_rider/features/rider/models/ride_model.dart';

void main() {
  const labels = ExpenseCsvLabels(
    title: 'Test',
    period: 'Period',
    generated: 'Generated',
    total: 'Total',
    rideCount: 'Rides',
    colRideId: 'ID',
    colDate: 'Date',
    colFrom: 'From',
    colTo: 'To',
    colAmount: 'Amount',
    colPayment: 'Pay',
    colPromo: 'Promo',
    colDiscount: 'Disc',
    colDistance: 'Km',
    currency: 'SYP',
  );

  test('expenseExportFileName is safe', () {
    expect(
      expenseExportFileName(periodSlug: 'This Month!'),
      matches(RegExp(r'^novaride_expenses_\d{4}-\d{2}_this_month\.csv$')),
    );
  });

  test('buildRideExpensesCsv includes BOM and ride row', () {
    final ride = RideModel(
      id: 42,
      status: RideStatus.completed,
      pickupLat: 33.5,
      pickupLng: 36.2,
      dropoffLat: 33.6,
      dropoffLng: 36.3,
      estimatedFare: 15000,
      estimatedDistanceKm: 4.2,
      paymentMethod: 'cash',
      pickupAddress: 'مزة',
      dropoffAddress: 'الشعلان',
      completedAt: DateTime(2025, 5, 10, 14, 30),
    );

    final csv = buildRideExpensesCsv(
      labels: labels,
      periodLabel: 'May 2025',
      rides: [ride],
      total: 15000,
      saved: 0,
    );

    expect(csv.startsWith(kExpenseCsvBom), isTrue);
    expect(csv, contains('42'));
    expect(csv, contains('15000'));
    expect(csv, contains('4.2'));
    expect(csv, contains('مزة'));
  });
}

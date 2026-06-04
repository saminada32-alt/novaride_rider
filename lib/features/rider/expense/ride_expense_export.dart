import 'package:intl/intl.dart';

import '../models/ride_model.dart';

/// UTF-8 BOM so Excel opens Arabic correctly on Windows.
const String kExpenseCsvBom = '\uFEFF';

class ExpenseCsvLabels {
  const ExpenseCsvLabels({
    required this.title,
    required this.period,
    required this.generated,
    required this.total,
    required this.rideCount,
    required this.colRideId,
    required this.colDate,
    required this.colFrom,
    required this.colTo,
    required this.colAmount,
    required this.colPayment,
    required this.colPromo,
    required this.colDiscount,
    required this.colDistance,
    required this.currency,
  });

  final String title;
  final String period;
  final String generated;
  final String total;
  final String rideCount;
  final String colRideId;
  final String colDate;
  final String colFrom;
  final String colTo;
  final String colAmount;
  final String colPayment;
  final String colPromo;
  final String colDiscount;
  final String colDistance;
  final String currency;
}

String expenseExportFileName({
  required String periodSlug,
  DateTime? at,
}) {
  final now = at ?? DateTime.now();
  final stamp = DateFormat('yyyy-MM').format(now);
  final safePeriod = periodSlug
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'novaride_expenses_${stamp}_$safePeriod.csv';
}

String buildRideExpensesCsv({
  required ExpenseCsvLabels labels,
  required String periodLabel,
  required List<RideModel> rides,
  required double total,
  required double saved,
  String Function(String? paymentKey)? paymentLabel,
}) {
  final dateFmt = DateFormat('yyyy-MM-dd HH:mm');
  final buf = StringBuffer()
    ..write(kExpenseCsvBom)
    ..writeln(labels.title)
    ..writeln('${labels.period},${_csv(periodLabel)}')
    ..writeln('${labels.generated},${dateFmt.format(DateTime.now())}')
    ..writeln('${labels.total},${total.toStringAsFixed(0)} ${labels.currency}')
    ..writeln('${labels.rideCount},${rides.length}')
    ..writeln();

  if (saved > 0) {
    buf.writeln('${labels.colDiscount} (total),${saved.toStringAsFixed(0)}');
    buf.writeln();
  }

  buf.writeln([
    labels.colRideId,
    labels.colDate,
    labels.colFrom,
    labels.colTo,
    labels.colDistance,
    labels.colAmount,
    labels.colPayment,
    labels.colPromo,
    labels.colDiscount,
  ].join(','));

  for (final r in rides) {
    final date = r.completedAt ?? r.createdAt ?? DateTime.now();
    final pay = paymentLabel != null
        ? paymentLabel(r.paymentMethod)
        : (r.paymentMethod ?? '');
    final dist = r.estimatedDistanceKm != null
        ? r.estimatedDistanceKm!.toStringAsFixed(1)
        : '';
    buf.writeln([
      r.id,
      dateFmt.format(date.toLocal()),
      '"${_csv(r.pickupAddress)}"',
      '"${_csv(r.dropoffAddress)}"',
      dist,
      (r.estimatedFare ?? 0).toStringAsFixed(0),
      '"${_csv(pay)}"',
      '"${_csv(r.promoCode)}"',
      (r.discountAmount ?? 0).toStringAsFixed(0),
    ].join(','));
  }

  return buf.toString();
}

String _csv(String? v) => (v ?? '').replaceAll('"', '""');

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/ride_model.dart';
import 'ride_expense_export.dart';

class RideExpenseExportService {
  RideExpenseExportService._();
  static final RideExpenseExportService instance = RideExpenseExportService._();

  Future<void> shareCsvFile({
    required String csvContent,
    required String fileName,
    required String shareSubject,
    String? shareText,
  }) async {
    if (kIsWeb) {
      await Share.share(csvContent, subject: shareSubject);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsString(csvContent);

    final xFile = XFile(
      path,
      mimeType: 'text/csv',
      name: fileName,
    );

    await Share.shareXFiles(
      [xFile],
      subject: shareSubject,
      text: shareText,
    );
  }

  Future<void> exportPeriod({
    required ExpenseCsvLabels labels,
    required String periodLabel,
    required String periodSlug,
    required List<RideModel> rides,
    required double total,
    required double saved,
    required String shareSubject,
    String Function(String? paymentKey)? paymentLabel,
  }) async {
    final csv = buildRideExpensesCsv(
      labels: labels,
      periodLabel: periodLabel,
      rides: rides,
      total: total,
      saved: saved,
      paymentLabel: paymentLabel,
    );
    final fileName = expenseExportFileName(periodSlug: periodSlug);
    await shareCsvFile(
      csvContent: csv,
      fileName: fileName,
      shareSubject: shareSubject,
      shareText: '$shareSubject — $periodLabel',
    );
  }
}

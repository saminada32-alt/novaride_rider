import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class RetryRideBanner extends StatelessWidget {
  final bool loading;
  final VoidCallback onRetry;

  const RetryRideBanner({
    super.key,
    required this.loading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.refresh_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                local.noDriverRetryShort,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            TextButton(
              onPressed: loading ? null : onRetry,
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(local.retry),
            ),
          ],
        ),
      ),
    );
  }
}

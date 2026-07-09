import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../services/legal_service.dart';
import '../../features/legal/legal_document_screen.dart';

/// Blocks the app until the rider accepts updated legal policies.
Future<void> showLegalConsentDialogIfNeeded(BuildContext context) async {
  final isAr = Localizations.localeOf(context).languageCode == 'ar';
  bool needs = false;
  List<LegalDocumentView> docs = [];

  try {
    final status = await LegalService.instance.consentStatus();
    needs = status['needsConsent'] == true;
    if (needs) {
      docs = await LegalService.instance.fetchPassengerBundle(isAr: isAr);
    }
  } catch (_) {
    return;
  }

  if (!needs || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _LegalConsentDialog(docs: docs, isAr: isAr),
  );
}

class _LegalConsentDialog extends StatefulWidget {
  final List<LegalDocumentView> docs;
  final bool isAr;

  const _LegalConsentDialog({required this.docs, required this.isAr});

  @override
  State<_LegalConsentDialog> createState() => _LegalConsentDialogState();
}

class _LegalConsentDialogState extends State<_LegalConsentDialog> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await LegalService.instance.acceptConsents();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.policyUpdateTitle),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.policyUpdateBody),
            const SizedBox(height: 12),
            ...widget.docs.map(
              (doc) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(doc.title, style: const TextStyle(fontSize: 14)),
                subtitle: Text(doc.summary, style: const TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LegalDocumentScreen(document: doc),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _accepting ? null : _accept,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff16a34a),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _accepting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(l.registerPolicies),
          ),
        ),
      ],
    );
  }
}

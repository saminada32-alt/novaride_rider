import 'package:flutter/material.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../content/content_service.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<ContentFaqItem> _remote = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await ContentService.instance.fetchFaq();
      if (mounted) setState(() => _remote = items);
    } catch (_) {
      /* fallback below */
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return A11yScreen(
      label: local.faq,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(local.faq)),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    local.faqTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    local.faqSubtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_remote.isNotEmpty)
                    ..._remote.map(
                      (item) => _faqItem(
                        icon: Icons.help_outline_rounded,
                        question: item.question(isAr),
                        answer: item.answer(isAr),
                      ),
                    )
                  else ...[
                    _faqItem(
                      icon: Icons.payment,
                      question: local.faqPaymentQ,
                      answer: local.faqPaymentA,
                    ),
                    _faqItem(
                      icon: Icons.event_available,
                      question: local.faqScheduleQ,
                      answer: local.faqScheduleA,
                    ),
                    _faqItem(
                      icon: Icons.cancel_outlined,
                      question: local.faqCancelQ,
                      answer: local.faqCancelA,
                    ),
                    _faqItem(
                      icon: Icons.security,
                      question: local.faqSafetyQ,
                      answer: local.faqSafetyA,
                    ),
                    _faqItem(
                      icon: Icons.support_agent,
                      question: local.faqSupportQ,
                      answer: local.faqSupportA,
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _faqItem({
    required IconData icon,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.green.shade700),
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

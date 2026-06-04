import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.faq), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ===== HEADER =====
          Text(
            local.faqTitle,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

          // ===== FAQ ITEMS =====
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
      ),
    );
  }

  // ===== SINGLE FAQ ITEM =====
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

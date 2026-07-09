import 'package:flutter/material.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../account/safety/safety_account_screen.dart' as emergency_settings;
import '../support/support_screen.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return A11yScreen(
      label: local.safety,
      child: Scaffold(
      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.safety)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Header Image =====
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 72,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // ===== Safety Sections =====
          _safetyItem(
            icon: Icons.verified_user,
            title: local.driverVerification,
            body: local.driverVerificationDesc,
            iconColor: Colors.green.shade400,
          ),
          const Divider(height: 32, thickness: 0.5),
          _safetyItem(
            icon: Icons.local_police,
            title: local.emergencyAssistance,
            body: local.emergencyAssistanceDesc,
            iconColor: Colors.green.shade400,
          ),
          const Divider(height: 32, thickness: 0.5),
          _safetyItem(
            icon: Icons.safety_divider,
            title: local.rideSafety,
            body: local.rideSafetyDesc,
            iconColor: Colors.green.shade400,
          ),
          const Divider(height: 32, thickness: 0.5),
          _safetyItem(
            icon: Icons.person,
            title: local.safeBehavior,
            body: local.safeBehaviorDesc,
            iconColor: Colors.green.shade400,
          ),
          const Divider(height: 32, thickness: 0.5),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
            child: _safetyItem(
              icon: Icons.phone_in_talk,
              title: local.contactSupport,
              body: local.contactSupportDesc,
              iconColor: Colors.green.shade400,
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const emergency_settings.SafetyScreen(),
              ),
            ),
            icon: const Icon(Icons.contact_emergency_outlined),
            label: Text(local.emergencyContact),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SupportScreen()),
            ),
            icon: const Icon(Icons.report_problem),
            label: Text(local.reportIssue),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _safetyItem({
    required IconData icon,
    required String title,
    required String body,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

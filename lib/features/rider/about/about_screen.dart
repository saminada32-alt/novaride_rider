import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(local.about), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ===== HEADER IMAGE =====
          SizedBox(
            height: 250,
            child: Image.asset(
              'assets/images/about_header.PNG',
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 24),

          // ===== APP NAME =====
          Text(
            local.appName,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          // ===== VERSION =====
          Text(
            '${local.version} 1.0.0',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.6),
            ),
          ),

          const SizedBox(height: 24),

          // ===== DESCRIPTION =====
          Text(
            local.aboutDesc,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),

          const SizedBox(height: 32),

          // ===== FEATURES =====
          _featureItem(
            icon: Icons.directions_car,
            title: local.aboutFeature1Title,
            desc: local.aboutFeature1Desc,
          ),
          const SizedBox(height: 16),

          _featureItem(
            icon: Icons.schedule,
            title: local.aboutFeature2Title,
            desc: local.aboutFeature2Desc,
          ),
          const SizedBox(height: 16),

          _featureItem(
            icon: Icons.security,
            title: local.aboutFeature3Title,
            desc: local.aboutFeature3Desc,
          ),

          const SizedBox(height: 40),

          // ===== FOOTER =====
          Text(
            local.aboutFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ===== FEATURE ITEM =====
  Widget _featureItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.green.shade700, size: 28),
        const SizedBox(width: 12),
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
              const SizedBox(height: 4),
              Text(
                desc,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

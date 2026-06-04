// file: language_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/app_controller.dart'; // ← مهم جداً

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final ctrl = context.watch<AppController>();
    final isAr = ctrl.isArabic;

    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Text(l.language),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // IMAGE
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/images/language.png",
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ENGLISH BUTTON
            _langButton(
              title: "English",
              active: !isAr,
              onTap: () {
                context.read<AppController>().changeLanguage('en');
              },
            ),

            const SizedBox(height: 20),

            // ARABIC BUTTON
            _langButton(
              title: "العربية",
              active: isAr,
              onTap: () {
                context.read<AppController>().changeLanguage('ar');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _langButton({
    required String title,
    required VoidCallback onTap,
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 180,
        height: 180,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: active
                ? [
                    const Color(0xff16a34a),
                    const Color(0xff16a34a).withOpacity(.7),
                  ]
                : [Colors.grey.shade300, Colors.grey.shade200],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: active ? Colors.white : Colors.black54,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

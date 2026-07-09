import 'package:flutter/material.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../../rider/home/rider_home_screen.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    return A11yScreen(
      label: local.introTitle,
      child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        title: Semantics(
          header: true,
          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "NovaRide",
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.directions_car, color: Colors.green, size: 26),
          ],
        ),
        ),
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔥 الصورة الدائرية
              CircleAvatar(
                radius: 150,
                backgroundImage: const AssetImage(
                  'assets/images/intro_avatar.png',
                ),
                backgroundColor: Colors.grey.shade300,

                //  child: Icon(
                // Icons.person,
                //size: 60,
                //color: Colors.grey.shade700,
                // ),
              ),

              const SizedBox(height: 24),

              // 🔥 النص الترحيبي
              Text(
                local.introTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                local.introSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 40),

              // زر المتابعة
              SizedBox(
                width: double.infinity,
                height: 54,
                child: A11yButton(
                  label: local.startNow,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RiderHomeScreen(),
                        ),
                      );
                    },
                    child: Text(
                      local.startNow,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

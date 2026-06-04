import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/login/login_screen.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../safety/safety_account_screen.dart';
import '../personal_info/personal_info_screen.dart';
import '../familyprofile/familyprofile_screen.dart';
import '../privacy/privacy_screen.dart';
import '../upcoming_trips/upcoming_trips_screen.dart';
import '../language/language_screen.dart';
import '../my_account_all/provider/account_provider.dart';

class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _picker = ImagePicker();

  Future<void> _pickPhoto() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    final ok = await context.read<AuthProvider>().uploadProfilePhoto(
      File(picked.path),
    );
    if (!mounted) return;

    final local = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? local.savedSuccessfully : 'Failed to upload photo'),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.passenger;

    final name = [
      user?.firstName,
      user?.lastName,
    ].where((s) => s?.isNotEmpty == true).join(' ');
    final email = user?.email ?? '';
    final phone = user?.phone ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(local.myAccount),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── User Card ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10),
                ],
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    imageUrl: user?.profileImageUrl,
                    name: name.isNotEmpty ? name : local.guest,
                    radius: 32,
                    showCameraBadge: true,
                    onTap: _pickPhoto,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.isNotEmpty ? name : local.guest,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (email.isNotEmpty)
                          Text(
                            email,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Personal ────────────────────────────────────────
            _section(local.personalInfo),
            _tile(
              Icons.person,
              local.personalInfo,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PersonalInfoScreen()),
              ),
            ),
            _tile(
              Icons.group,
              local.familyProfile,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FamilyProfileScreen()),
              ),
            ),
            _tile(
              Icons.shield,
              local.safety,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => AccountProvider(),
                    child: const SafetyScreen(),
                  ),
                ),
              ),
            ),
            _tile(
              Icons.privacy_tip,
              local.privacy,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacyScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Settings ────────────────────────────────────────
            _section(local.settings),
            _tile(
              Icons.language,
              local.language,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LanguageScreen()),
              ),
            ),
            _tile(
              Icons.calendar_today,
              local.calendars,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpcomingTripsScreen()),
              ),
            ),

            const SizedBox(height: 24),

            // ─── Actions ─────────────────────────────────────────
            _tile(Icons.logout, local.logout, () async {
              await auth.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }, color: Colors.orange),

            _tile(Icons.delete_outline, local.deleteAccount, () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(local.deleteAccount),
                  content: const Text(
                    'This action is irreversible. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm != true) return;

              final ok = await context.read<AccountProvider>().deleteAccount();
              if (ok && context.mounted) {
                await auth.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            }, color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 15,
        color: Colors.black54,
      ),
    ),
  );

  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color color = Colors.black,
  }) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: color),
    title: Text(title, style: TextStyle(fontSize: 16, color: color)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}


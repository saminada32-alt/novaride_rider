import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/utils/profile_photo_picker.dart';
import '../../../../core/widgets/a11y.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/widgets/profile_avatar.dart';
import 'Edit_info_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final t = AppLocalizations.of(context)!;
    await showProfilePhotoSourceSheet(
      context,
      cameraLabel: t.camera,
      galleryLabel: t.gallery,
      onPicked: (file) async {
        setState(() => _uploadingPhoto = true);
        final ok = await context.read<AuthProvider>().uploadProfilePhoto(file);
        if (!mounted) return;
        setState(() => _uploadingPhoto = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? t.savedSuccessfully : t.failedToUploadPhoto),
            backgroundColor: ok ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final user = auth.passenger;

    final firstName = user?.firstName ?? local.guest;
    final lastName = user?.lastName ?? '';
    final email = user?.email ?? '—';
    final phone = user?.phone ?? '—';
    final gender = user?.gender ?? '—';
    final home = user?.homeAddress ?? '—';
    final work = user?.workAddress ?? '—';

    return A11yScreen(
      label: local.personalInfo,
      child: Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.black,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditPersonalInfoScreen()),
        ),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: Text(
          local.editProfile,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.personalInfo)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ─── Glass Header ────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ProfileAvatar(
                            imageUrl: user?.profileImageUrl,
                            localPreviewPath: auth.localProfilePreview,
                            onNetworkImageLoaded: auth.clearLocalProfilePreview,
                            name: '$firstName $lastName'.trim(),
                            radius: 42,
                            showCameraBadge: true,
                            onTap: _uploadingPhoto ? null : _pickAndUploadPhoto,
                          ),
                          if (_uploadingPhoto)
                            const SizedBox(
                              width: 84,
                              height: 84,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      Text(
                        '$firstName $lastName'.trim(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            _section(local.personalInfo),
            _card(local.firstName, firstName),
            _card(local.lastName, lastName),
            _card(local.email, email),
            _card(local.phone, phone),
            _card(local.gender, _genderLabel(context, gender)),

            const SizedBox(height: 30),

            _section(local.addresses),
            _card(local.homeAddress, home),
            _card(local.workAddress, work),

            const SizedBox(height: 60),
          ],
        ),
      ),
    ),
    );
  }

  Widget _section(String title) => Align(
    alignment: Alignment.centerLeft,
    child: Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
    ),
  );

  Widget _card(String label, String value) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe5e5e5)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );

  String _genderLabel(BuildContext ctx, String gender) {
    final l = AppLocalizations.of(ctx)!;
    if (gender == 'male') return l.male;
    if (gender == 'female') return l.female;
    return '—';
  }
}

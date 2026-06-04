import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../intro/intro_screen.dart';
import '../../../l10n/app_localizations.dart';

class ProfileSetupScreen extends StatefulWidget {
  final Map<String, String>? registerData;
  const ProfileSetupScreen({super.key, this.registerData});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _birthDate = TextEditingController();
  String? _gender;

  @override
  void initState() {
    super.initState();
    // عبّي البيانات من الـ register إذا موجودة
    if (widget.registerData != null) {
      final name = widget.registerData!['name'] ?? '';
      final parts = name.trim().split(' ');
      _firstName.text = parts.isNotEmpty ? parts.first : '';
      _lastName.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      _email.text = widget.registerData!['email'] ?? '';
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _birthDate.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 10),
    );
    if (picked != null) {
      _birthDate.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final prov = context.read<AuthProvider>();

    // ─── أرسل البيانات للباك اند ──────────────────────────────
    final ok = await prov.updateProfile({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_birthDate.text.isNotEmpty) 'birthDate': _birthDate.text,
    });

    if (!mounted) return;

    if (ok) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreen()),
        (_) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(prov.error ?? 'Failed to save profile'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.green),
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Colors.green, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final prov = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(local.completeProfile),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),

              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                local.profileSetupTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                local.profileSetupDesc,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 28),

              TextFormField(
                controller: _firstName,
                decoration: _dec(local.firstName, Icons.person_outline),
                validator: (v) =>
                    v!.trim().isEmpty ? local.requiredField : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _lastName,
                decoration: _dec(local.lastName, Icons.person_outline),
                validator: (v) =>
                    v!.trim().isEmpty ? local.requiredField : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec(local.emailOptional, Icons.mail_outline),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: _dec(local.gender, Icons.wc),
                items: [
                  DropdownMenuItem(value: 'male', child: Text(local.male)),
                  DropdownMenuItem(value: 'female', child: Text(local.female)),
                ],
                onChanged: (v) => setState(() => _gender = v),
                validator: (v) => v == null ? local.requiredField : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _birthDate,
                readOnly: true,
                decoration: _dec(local.birthDate, Icons.calendar_month),
                onTap: _pickDate,
                validator: (v) => v!.isEmpty ? local.requiredField : null,
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: prov.loading ? null : _submit,
                  child: prov.loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          local.continueText,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

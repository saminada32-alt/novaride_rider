import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/widgets/a11y.dart';
import '../../../../core/utils/auth_error_messages.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../features/auth/providers/auth_provider.dart';

class EditPersonalInfoScreen extends StatefulWidget {
  const EditPersonalInfoScreen({super.key});
  @override
  State<EditPersonalInfoScreen> createState() => _EditPersonalInfoScreenState();
}

class _EditPersonalInfoScreenState extends State<EditPersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _homeCtrl = TextEditingController();
  final _workCtrl = TextEditingController();
  String? _gender;
  bool _loading = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final user = context.read<AuthProvider>().passenger;
    _firstName.text = user?.firstName ?? '';
    _lastName.text = user?.lastName ?? '';
    _email.text = user?.email ?? '';
    _homeCtrl.text = user?.homeAddress ?? '';
    _workCtrl.text = user?.workAddress ?? '';
    _gender = user?.gender;
    _initialized = true;
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _homeCtrl.dispose();
    _workCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);

    final prov = context.read<AuthProvider>();
    final ok = await prov.updateProfile({
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_homeCtrl.text.trim().isNotEmpty)
        'homeAddress': _homeCtrl.text.trim(),
      if (_workCtrl.text.trim().isNotEmpty)
        'workAddress': _workCtrl.text.trim(),
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.savedSuccessfully),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            localizeAuthError(
              prov.error,
              AppLocalizations.of(context)!,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    border: InputBorder.none,
    labelText: label,
    prefixIcon: Icon(icon, color: Colors.green.shade600),
  );

  Widget _card(String label, IconData icon, TextEditingController ctrl) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xffe5e5e5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(controller: ctrl, decoration: _dec(label, icon)),
      );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    return A11yScreen(
      label: local.editProfile,
      child: Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(local.editProfile)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Header
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.editProfile,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      local.updatePersonalInfo,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _card(local.firstName, Icons.person, _firstName),
                    const SizedBox(height: 14),
                    _card(local.lastName, Icons.person_outline, _lastName),
                    const SizedBox(height: 14),
                    _card(local.email, Icons.email_outlined, _email),
                    const SizedBox(height: 14),

                    // Gender
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xffe5e5e5)),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _gender,
                        decoration: _dec(local.gender, Icons.wc),
                        items: [
                          DropdownMenuItem(
                            value: 'male',
                            child: Text(local.male),
                          ),
                          DropdownMenuItem(
                            value: 'female',
                            child: Text(local.female),
                          ),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                    const SizedBox(height: 28),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        local.addresses,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _card(local.homeAddress, Icons.home_outlined, _homeCtrl),
                    const SizedBox(height: 14),
                    _card(local.workAddress, Icons.work_outline, _workCtrl),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),

          // Save button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 25),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: A11yButton(
                label: local.save,
                enabled: !_loading,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          local.save,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

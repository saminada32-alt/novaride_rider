import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/a11y.dart';
import '../../../core/utils/auth_error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/legal_service.dart';
import '../../legal/legal_document_screen.dart';
import '../providers/auth_provider.dart';
import '../otp/otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _code = '+963';
  bool _agreed = false;
  bool _loadingPolicies = false;
  List<LegalDocumentView> _policyDocs = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String v) {
    String c = v.replaceAll(RegExp(r'\D'), '');
    if (c.startsWith('0')) c = c.substring(1);
    if (c.length > 9) c = c.substring(0, 9);
    if (c != v) {
      _phoneCtrl.value = TextEditingValue(
        text: c,
        selection: TextSelection.collapsed(offset: c.length),
      );
    }
    setState(() {});
  }

  bool get _valid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().length >= 7 &&
      _agreed;

  Future<void> _register() async {
    if (!_valid) return;

    final phone = '$_code${_phoneCtrl.text.trim()}';
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          phone: phone,
          isLogin: false,
          registerData: {
            'name': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
          },
        ),
      ),
    );

    final prov = context.read<AuthProvider>();
    final ok = await prov.sendOtp(phone);
    if (!mounted || ok) return;

    final local = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(localizeAuthError(prov.error, local)),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _loadPoliciesIfNeeded() async {
    if (_policyDocs.isNotEmpty || _loadingPolicies) return;
    setState(() => _loadingPolicies = true);
    try {
      final isAr = Localizations.localeOf(context).languageCode == 'ar';
      final docs = await LegalService.instance.fetchPassengerBundle(isAr: isAr);
      if (mounted) setState(() => _policyDocs = docs);
    } catch (_) {
      /* fallback handled in sheet */
    } finally {
      if (mounted) setState(() => _loadingPolicies = false);
    }
  }

  void _showPolicies() {
    final l = AppLocalizations.of(context)!;
    _loadPoliciesIfNeeded();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, ctrl) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: ListView(
            controller: ctrl,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Text(
                l.policiesTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_loadingPolicies)
                const Center(child: CircularProgressIndicator())
              else if (_policyDocs.isEmpty)
                Text(
                  l.policiesFullText,
                  style: const TextStyle(fontSize: 15, height: 1.55),
                )
              else
                ..._policyDocs.expand((doc) => [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          doc.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(doc.summary),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LegalDocumentScreen(document: doc),
                            ),
                          );
                        },
                      ),
                      const Divider(),
                    ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final prov = context.watch<AuthProvider>();
    final isAr = Directionality.of(context) == TextDirection.rtl;

    return A11yScreen(
      label: l.registerTitle,
      child: Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/welcome_rider.PNG',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.60)),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    Align(
                      alignment: isAr ? Alignment.topRight : Alignment.topLeft,
                      child: A11yIconButton(
                        label: l.back,
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    A11yHeader(
                      label: l.registerTitle,
                      child: Text(
                        l.registerTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(60),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.97),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Column(
                        children: [
                          _field(_nameCtrl, l.registerFullName, Icons.person),
                          const SizedBox(height: 16),
                          _field(
                            _emailCtrl,
                            l.registerEmailOptional,
                            Icons.mail,
                          ),
                          const SizedBox(height: 16),

                          // Phone
                          A11yTextField(
                            label: l.registerPhone,
                            child: TextFormField(
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 9,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: l.registerPhone,
                                counterText: '',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CountryCodePicker(
                                      onChanged: (c) =>
                                          setState(() => _code = c.dialCode!),
                                      initialSelection: 'SY',
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ),
                              onChanged: _onPhoneChanged,
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Checkbox(
                                activeColor: Colors.green,
                                value: _agreed,
                                onChanged: (v) =>
                                    setState(() => _agreed = v ?? false),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: _showPolicies,
                                  child: Text(
                                    l.registerPolicies,
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          A11yButton(
                            label: l.registerButton,
                            enabled: _valid && !prov.loading,
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _valid
                                      ? Colors.black
                                      : Colors.grey.shade400,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: (_valid && !prov.loading)
                                    ? _register
                                    : null,
                                child: prov.loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        l.registerButton,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon) =>
      A11yTextField(
        label: label,
        child: TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      );
}

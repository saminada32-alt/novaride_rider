import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/legal_service.dart';
import '../../../core/utils/auth_error_messages.dart';
import '../providers/auth_provider.dart';
import '../profile_setup/profile_setup_screen.dart';
import '../../rider/home/rider_home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final bool isLogin;
  final Map<String, String>? registerData;

  const OtpScreen({
    super.key,
    required this.phone,
    this.isLogin = true,
    this.registerData,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpCtrl = TextEditingController();
  final _otpFocus = FocusNode();
  Timer? _timer;
  int _sec = 60;
  bool _isError = false;
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpCtrl.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _sec = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_sec == 0) {
        t.cancel();
      } else {
        setState(() => _sec--);
      }
    });
  }

  bool get _complete => RegExp(r'^\d{6}$').hasMatch(_otpCtrl.text);

  void _clear() {
    _otpCtrl.clear();
    _otpFocus.requestFocus();
    setState(() => _isError = false);
  }

  void _onOtpChanged(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits != value) {
      _otpCtrl.text = digits;
      _otpCtrl.selection = TextSelection.collapsed(offset: digits.length);
    }
    setState(() => _isError = false);
  }

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    _verifying = true;
    _otpFocus.unfocus();

    final t = AppLocalizations.of(context)!;
    final prov = context.read<AuthProvider>();

    final ok = await prov.verifyOtp(
      widget.phone,
      _otpCtrl.text,
      consents: LegalService.instance.passengerConsents(),
    );
    if (!mounted) return;
    _verifying = false;

    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _isError = true);
      _snack(localizeAuthError(prov.error, t), Colors.red.shade600);
      return;
    }

    if (widget.isLogin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        (_) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileSetupScreen(registerData: widget.registerData),
        ),
        (_) => false,
      );
    }
  }

  Future<void> _resend() async {
    final t = AppLocalizations.of(context)!;
    final prov = context.read<AuthProvider>();
    final ok = await prov.sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      _clear();
      _startTimer();
      _snack(t.codeSentSuccess, Colors.green);
    } else {
      _snack(localizeAuthError(prov.error, t), Colors.red.shade600);
    }
  }

  void _snack(String m, Color c) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(m),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final prov = context.watch<AuthProvider>();
    final loading = prov.loading || _verifying;
    final code = _otpCtrl.text;
    final digits = code.padRight(6).split('');

    return A11yScreen(
      label: local.otpTitle,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          title: Semantics(
            header: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'NovaRide',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.directions_car, color: Colors.green, size: 26),
              ],
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.lock_outline, size: 80, color: Colors.black),
              ),
              const SizedBox(height: 28),
              Text(
                local.otpTitle,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${local.otpSubtitle} ${widget.phone}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  final filled = i < code.length;
                  return Container(
                    width: 48,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _isError
                          ? Colors.red.shade100
                          : filled
                          ? Colors.green.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _otpFocus.hasFocus && i == code.length
                            ? Colors.green
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      filled ? digits[i] : '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otpCtrl,
                focusNode: _otpFocus,
                enabled: !loading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: local.otpHint,
                  counterText: '',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onOtpChanged,
                onSubmitted: (_) {
                  if (_complete) _verify();
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: A11yButton(
                  label: local.confirm,
                  enabled: _complete && !loading,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: (_complete && !loading) ? _verify : null,
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            local.confirm,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: _sec > 0
                    ? Text(
                        local.resendIn(_sec),
                        style: TextStyle(color: Colors.grey[500]),
                      )
                    : TextButton(
                        onPressed: loading ? null : _resend,
                        child: Text(
                          local.resend,
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
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

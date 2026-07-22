import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/a11y.dart';
import '../../../core/widgets/otp_code_input.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/services/legal_service.dart';
import '../../../core/utils/auth_error_messages.dart';
import '../providers/auth_provider.dart';
import '../navigation/rider_onboarding_router.dart';
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
  final _otpKey = GlobalKey<OtpCodeInputState>();
  Timer? _timer;
  int _sec = 60;
  bool _isError = false;
  bool _verifying = false;
  int _verifySeq = 0;
  String _otp = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
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

  bool get _complete => _otp.length == 6;

  void _clear() {
    _otpKey.currentState?.clear();
    setState(() {
      _otp = '';
      _isError = false;
    });
  }

  Future<void> _verify([String? codeOverride]) async {
    final otp = (codeOverride ?? _otp).trim();
    if (otp.length != 6 || _verifying) return;
    _verifying = true;
    final seq = ++_verifySeq;
    setState(() {
      _otp = otp;
    });
    FocusManager.instance.primaryFocus?.unfocus();

    final t = AppLocalizations.of(context)!;
    final prov = context.read<AuthProvider>();

    final ok = await prov.verifyOtp(
      widget.phone,
      otp,
      consents: widget.isLogin
          ? null
          : LegalService.instance.passengerConsents(),
    );
    if (!mounted || seq != _verifySeq) return;
    setState(() => _verifying = false);

    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _isError = true);
      _snack(localizeAuthError(prov.error, t), Colors.red.shade600);
      Future.delayed(const Duration(milliseconds: 400), _clear);
      return;
    }

    TextInput.finishAutofillContext(shouldSave: false);

    if (widget.isLogin) {
      final passenger = prov.passenger;
      if (passenger != null && !passenger.profileCompleted) {
        unawaited(
          RiderOnboardingRouter.resumeIncomplete(
            context,
            profileCompleted: false,
          ),
        );
        return;
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        (_) => false,
      );
    } else {
      unawaited(
        RiderOnboardingRouter.saveStep(RiderOnboardingStep.profileSetup),
      );
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
    final ok = widget.isLogin
        ? await prov.sendLoginOtp(widget.phone)
        : await prov.sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      _clear();
      _startTimer();
      await _otpKey.currentState?.restartListening();
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
    final loading = _verifying || prov.verifying;

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
              const SizedBox(height: 8),
              Text(
                'قد يستغرق وصول الرسالة 10–30 ثانية. إذا لم تصل، اضغط إعادة إرسال.',
                style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 32),
              OtpCodeInput(
                key: _otpKey,
                hasError: _isError,
                enabled: !loading,
                onChanged: (v) => setState(() {
                  _otp = v;
                  _isError = false;
                }),
                onCompleted: _verify,
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

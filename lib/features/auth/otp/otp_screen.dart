import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  final _ctrls = List.generate(6, (_) => TextEditingController());
  final _focus = List.generate(6, (_) => FocusNode());
  Timer? _timer;
  int _sec = 60;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focus.first.requestFocus(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
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

  String get _otp => _ctrls.map((c) => c.text).join();
  bool get _complete => _otp.length == 6;

  void _clear() {
    for (final c in _ctrls) {
      c.clear();
    }
    _focus.first.requestFocus();
    setState(() => _isError = false);
  }

  Future<void> _verify() async {
    if (!_complete) return;

    final prov = context.read<AuthProvider>();

    // ─── استدعاء الباك اند الحقيقي ───────────────────────────
    final ok = await prov.verifyOtp(widget.phone, _otp);
    if (!mounted) return;

    if (!ok) {
      HapticFeedback.heavyImpact();
      setState(() => _isError = true);
      Future.delayed(const Duration(milliseconds: 400), _clear);
      _snack(prov.error ?? 'Invalid code', Colors.red.shade600);
      return;
    }

    if (widget.isLogin) {
      // ─── Login → Home مباشرة ──────────────────────────────
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RiderHomeScreen()),
        (_) => false,
      );
    } else {
      // ─── Register → Profile Setup ─────────────────────────
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
    final prov = context.read<AuthProvider>();
    final ok = await prov.sendOtp(widget.phone);
    if (!mounted) return;
    if (ok) {
      _clear();
      _startTimer();
      _snack('Code sent!', Colors.green);
    } else {
      _snack(prov.error ?? 'Failed', Colors.red.shade600);
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
    final prov = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
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
            const Text(
              'OTP Verification',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the code sent to ${widget.phone}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (i) => SizedBox(
                  width: 50,
                  height: 58,
                  child: TextField(
                    controller: _ctrls[i],
                    focusNode: _focus[i],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _isError
                          ? Colors.red.shade100
                          : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Colors.green,
                          width: 2,
                        ),
                      ),
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (v) {
                      if (v.length == 6 && RegExp(r'^\d{6}$').hasMatch(v)) {
                        for (var j = 0; j < 6; j++) {
                          _ctrls[j].text = v[j];
                        }
                        _focus.last.unfocus();
                        setState(() {});
                        return;
                      }
                      if (v.isNotEmpty && i < 5) _focus[i + 1].requestFocus();
                      if (v.isEmpty && i > 0) _focus[i - 1].requestFocus();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: (_complete && !prov.loading) ? _verify : null,
                child: prov.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: _sec > 0
                  ? Text(
                      'Resend ($_sec)',
                      style: TextStyle(color: Colors.grey[500]),
                    )
                  : TextButton(
                      onPressed: prov.loading ? null : _resend,
                      child: const Text(
                        'Resend',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
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

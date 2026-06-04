
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/passenger_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/rider_fcm_service.dart';
import '../../../core/utils/media_url.dart';
import '../../rider/account/my_account_all/service/account_service.dart';

enum RiderStatus { notLoggedIn, newUser, returning }

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  PassengerModel? _passenger;
  String? _token;
  bool _isNew = false;
  String? _error;
  bool _loading = false;

  PassengerModel? get passenger => _passenger;
  String? get token => _token;
  bool get isNew => _isNew;
  String? get error => _error;
  bool get loading => _loading;

  // ─── فحص الحالة عند فتح التطبيق ──────────────────────────
  Future<RiderStatus> checkStatus() async {
    try {
      final tok = await _storage.read(key: 'passenger_token');
      if (tok == null) return RiderStatus.notLoggedIn;

      _token = tok;

      final res = await http
          .get(
            Uri.parse('${Api.base}${Api.passengerMe}'),
            headers: {..._h, 'Authorization': 'Bearer $tok'},
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        _passenger = PassengerModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)),
        );
        notifyListeners();
        unawaited(RiderFcmService.instance.uploadTokenIfLoggedIn());
        return _passenger!.profileCompleted
            ? RiderStatus.returning
            : RiderStatus.newUser;
      }
      return RiderStatus.notLoggedIn;
    } catch (_) {
      return RiderStatus.notLoggedIn;
    }
  }

  // ─── Send OTP ─────────────────────────────────────────────
  Future<bool> sendOtp(String phone) async {
    _begin();
    try {
      final res = await http
          .post(
            Uri.parse('${Api.base}${Api.sendOtp}'),
            headers: _h,
            body: jsonEncode({'phone': phone, 'role': 'PASSENGER'}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200 || res.statusCode == 201) {
        _loading = false;
        notifyListeners();
        return true;
      }
      _fail(data['message']?.toString() ?? 'Failed to send OTP');
      return false;
    } catch (e) {
      _fail('NET[${Api.base}]: $e');
      return false;
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────
  Future<bool> verifyOtp(String phone, String otp) async {
    _begin();
    try {
      final res = await http
          .post(
            Uri.parse('${Api.base}${Api.verifyOtp}'),
            headers: _h,
            body: jsonEncode({'phone': phone, 'otp': otp, 'role': 'PASSENGER'}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(utf8.decode(res.bodyBytes));

      if (res.statusCode == 200 || res.statusCode == 201) {
        // الباك اند يرجع access_token مو token
        final tok = data['access_token']?.toString();
        if (tok == null) {
          _fail('Invalid response');
          return false;
        }

        _token = tok;
        _isNew = data['isNew'] ?? false;
        await _storage.write(key: 'passenger_token', value: tok);

        // حمّل بيانات الراكب
        if (data['user'] != null) {
          _passenger = PassengerModel.fromJson(data['user']);
        }

        _loading = false;
        notifyListeners();
        unawaited(RiderFcmService.instance.uploadTokenIfLoggedIn());
        return true;
      }

      final msg = data['message'];
      _fail(msg is List ? msg.join(', ') : msg?.toString() ?? 'Invalid OTP');
      return false;
    } catch (e) {
      _fail('No internet connection');
      return false;
    }
  }

  // ─── Update Profile ───────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> body) async {
    if (_token == null) return false;
    _begin();
    try {
      final res = await http
          .patch(
            Uri.parse('${Api.base}${Api.passengerMe}'),
            headers: {..._h, 'Authorization': 'Bearer $_token'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        _passenger = PassengerModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)),
        );
        _loading = false;
        notifyListeners();
        return true;
      }
      _fail('Failed to update profile');
      return false;
    } catch (e) {
      _fail('No internet connection');
      return false;
    }
  }

  Future<bool> uploadProfilePhoto(File file) async {
    if (_token == null) return false;
    _begin();
    try {
      final path = await AccountService.instance.uploadProfilePhoto(file);
      if (path == null) {
        _fail('Failed to upload photo');
        return false;
      }
      _passenger = _passenger?.copyWith(
        profileImage: resolveMediaUrl(path) ?? path,
      );
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _fail('No internet connection');
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final data = await AccountService.instance.getProfile();
      if (data != null) {
        _passenger = PassengerModel.fromJson(data);
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── Logout ───────────────────────────────────────────────
  Future<void> logout() async {
    await _storage.delete(key: 'passenger_token');
    _passenger = null;
    _token = null;
    notifyListeners();
  }

  void _begin() {
    _loading = true;
    _error = null;
    notifyListeners();
  }

  void _fail(String e) {
    _error = e.replaceAll('Exception: ', '');
    _loading = false;
    notifyListeners();
  }
}

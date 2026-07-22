
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/passenger_model.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/rider_fcm_service.dart';
import '../../../core/utils/auth_error_messages.dart';
import '../../../core/utils/resilient_http.dart';
import '../../../core/utils/session_cache.dart';
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
  String? _localProfilePreview;
  bool _isNew = false;
  String? _error;
  bool _loading = false;
  bool _sendingOtp = false;
  bool _verifying = false;

  bool get sendingOtp => _sendingOtp;
  bool get verifying => _verifying;
  bool get loading => _verifying || _loading;

  PassengerModel? get passenger => _passenger;
  String? get token => _token;
  String? get localProfilePreview => _localProfilePreview;
  bool get isNew => _isNew;
  String? get error => _error;
  bool get isAccountNotFound => _error == authErrAccountNotFound;

  // ─── فحص الحالة عند فتح التطبيق ──────────────────────────
  Future<RiderStatus> checkStatus() async {
    String? tok;
    try {
      tok = await _storage.read(key: 'passenger_token');
      if (tok == null) return RiderStatus.notLoggedIn;

      _token = tok;

      final res = await ResilientHttp.sessionGet(
        Uri.parse('${Api.base}${Api.passengerMe}'),
        headers: {..._h, 'Authorization': 'Bearer $tok'},
      );

      if (res.statusCode == 401) {
        await logout();
        return RiderStatus.notLoggedIn;
      }

      if (res.statusCode == 200) {
        _passenger = PassengerModel.fromJson(
          jsonDecode(utf8.decode(res.bodyBytes)),
        );
        notifyListeners();
        unawaited(RiderFcmService.instance.uploadTokenIfLoggedIn());
        await SessionCache.saveRiderProfileCompleted(
          _passenger!.profileCompleted,
        );
        return _passenger!.profileCompleted
            ? RiderStatus.returning
            : RiderStatus.newUser;
      }

      if (tok.isNotEmpty) {
        final status = await _statusFromCache(fallback: RiderStatus.returning);
        unawaited(_refreshRiderInBackground(tok));
        return status;
      }
      return RiderStatus.notLoggedIn;
    } catch (_) {
      if (tok != null) {
        final status = await _statusFromCache(fallback: RiderStatus.returning);
        unawaited(_refreshRiderInBackground(tok));
        return status;
      }
      return RiderStatus.notLoggedIn;
    }
  }

  Future<void> _refreshRiderInBackground(String tok) async {
    try {
      final res = await ResilientHttp.get(
        Uri.parse('${Api.base}${Api.passengerMe}'),
        headers: {..._h, 'Authorization': 'Bearer $tok'},
      );
      if (res.statusCode != 200) return;
      _passenger = PassengerModel.fromJson(
        jsonDecode(utf8.decode(res.bodyBytes)),
      );
      await SessionCache.saveRiderProfileCompleted(
        _passenger!.profileCompleted,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<RiderStatus> _statusFromCache({
    required RiderStatus fallback,
  }) async {
    final completed = await SessionCache.loadRiderProfileCompleted();
    if (completed == true) return RiderStatus.returning;
    if (completed == false) return RiderStatus.newUser;
    return fallback;
  }

  // ─── Send OTP ─────────────────────────────────────────────
  Future<bool> sendLoginOtp(String phone) => sendOtp(phone, forLogin: true);

  Future<bool> sendOtp(String phone, {bool forLogin = false}) async {
    if (_sendingOtp) return false;
    _sendingOtp = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'role': 'PASSENGER',
      };
      if (forLogin) body['intent'] = 'login';

      final res = await ResilientHttp.authSendPost(
        Uri.parse('${Api.base}${Api.sendOtp}'),
        headers: _h,
        body: jsonEncode(body),
      );

      final data = ResilientHttp.decodeJson(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        _sendingOtp = false;
        notifyListeners();
        return true;
      }
      if (res.statusCode == 404) {
        _error = authErrAccountNotFound;
      } else if (data['code'] == 'SMS_DELIVERY_FAILED') {
        _error = authErrSendOtp;
      } else if (data['code'] == 'LEGAL_CONSENT_REQUIRED') {
        _error = data['message']?.toString() ?? 'Legal consent required';
      } else {
        _error = data['message']?.toString() ?? authErrSendOtp;
      }
      _sendingOtp = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error = authErrServerTimeout;
      _sendingOtp = false;
      notifyListeners();
      return false;
    } on SocketException {
      _error = authErrNoConnection;
      _sendingOtp = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      if (_error!.isEmpty) _error = authErrSendOtp;
      _sendingOtp = false;
      notifyListeners();
      return false;
    }
  }

  // ─── Verify OTP ───────────────────────────────────────────
  Future<bool> verifyOtp(
    String phone,
    String otp, {
    List<Map<String, String>>? consents,
  }) async {
    _verifying = true;
    _error = null;
    notifyListeners();
    try {
      final body = <String, dynamic>{
        'phone': phone,
        'otp': otp,
        'role': 'PASSENGER',
      };
      if (consents != null && consents.isNotEmpty) {
        body['consents'] = consents;
      }

      final res = await ResilientHttp.authPost(
        Uri.parse('${Api.base}${Api.verifyOtp}'),
        headers: _h,
        body: jsonEncode(body),
      );

      final data = ResilientHttp.decodeJson(res);

      if (res.statusCode == 200 || res.statusCode == 201) {
        final tok = data['access_token']?.toString();
        if (tok == null) {
          _error = authErrInvalidResponse;
          _verifying = false;
          notifyListeners();
          return false;
        }

        _token = tok;
        _isNew = data['isNew'] ?? false;
        await _storage.write(key: 'passenger_token', value: tok);

        if (data['user'] != null) {
          _passenger = PassengerModel.fromJson(data['user']);
          await SessionCache.saveRiderProfileCompleted(
            _passenger!.profileCompleted,
          );
        }

        _verifying = false;
        notifyListeners();
        unawaited(RiderFcmService.instance.uploadTokenIfLoggedIn());
        return true;
      }

      final msg = data['message'];
      if (data['code'] == 'LEGAL_CONSENT_REQUIRED') {
        _error = msg?.toString() ?? 'Legal consent required';
      } else {
        _error = msg is List
            ? msg.join(', ')
            : msg?.toString() ?? authErrInvalidOtp;
      }
      _verifying = false;
      notifyListeners();
      return false;
    } on TimeoutException {
      _error = authErrServerTimeout;
      _verifying = false;
      notifyListeners();
      return false;
    } on SocketException {
      _error = authErrNoConnection;
      _verifying = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      if (_error!.isEmpty) _error = authErrInvalidOtp;
      _verifying = false;
      notifyListeners();
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
        await SessionCache.saveRiderProfileCompleted(
          _passenger!.profileCompleted,
        );
        _loading = false;
        notifyListeners();
        return true;
      }
      _fail(authErrUpdateProfile);
      return false;
    } catch (e) {
      _fail(authErrNetwork);
      return false;
    }
  }

  void clearLocalProfilePreview() {
    if (_localProfilePreview == null) return;
    _localProfilePreview = null;
    notifyListeners();
  }

  Future<bool> uploadProfilePhoto(File file) async {
    if (_token == null) return false;
    _error = null;
    _localProfilePreview = file.path;
    _passenger = _passenger?.copyWith(profileImage: file.path);
    notifyListeners();
    try {
      final path = await AccountService.instance.uploadProfilePhoto(file);
      if (path == null) {
        _error = authErrUploadPhoto;
        notifyListeners();
        return false;
      }
      _passenger = _passenger?.copyWith(profileImage: path);
      notifyListeners();
      return true;
    } catch (e) {
      _error = authErrNetwork;
      notifyListeners();
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
    await SessionCache.clearRider();
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

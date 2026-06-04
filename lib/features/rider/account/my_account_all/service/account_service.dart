import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/api_constants.dart';

class AccountService {
  AccountService._();
  static AccountService instance = AccountService._();

  static const _storage = FlutterSecureStorage();
  static const _h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> _token() => _storage.read(key: 'passenger_token');
  Map<String, String> _auth(String t) => {..._h, 'Authorization': 'Bearer $t'};

  // ─── Get Profile ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    final tok = await _token();
    if (tok == null) return null;

    final res = await http
        .get(Uri.parse('${Api.base}${Api.passengerMe}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }

  // ─── Update Profile ───────────────────────────────────────
  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> data) async {
    final tok = await _token();
    if (tok == null) return null;

    final res = await http
        .patch(
          Uri.parse('${Api.base}${Api.passengerMe}'),
          headers: _auth(tok),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }

  Future<String?> uploadProfilePhoto(File file) async {
    final tok = await _token();
    if (tok == null) return null;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${Api.base}${Api.uploadPassengerProfile}'),
    )
      ..headers['Authorization'] = 'Bearer $tok'
      ..headers['Accept'] = 'application/json'
      ..files.add(
        await http.MultipartFile.fromPath('profileImage', file.path),
      );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['profileImage']?.toString();
    }
    return null;
  }

  // ─── Delete Account ───────────────────────────────────────
  Future<bool> deleteAccount() async {
    final tok = await _token();
    if (tok == null) return false;

    final res = await http
        .delete(Uri.parse('${Api.base}${Api.passengerMe}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      await _storage.delete(key: 'passenger_token');
      return true;
    }
    return false;
  }

  // ─── Emergency Contact ────────────────────────────────────

  // في getEmergencyContact() — أضف error handling
  Future<Map<String, dynamic>?> getEmergencyContact() async {
    final tok = await _token();
    if (tok == null) return null;

    try {
      final res = await http
          .get(
            Uri.parse('${Api.base}${Api.emergencyContact}'),
            headers: _auth(tok),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        // ← الباك اند ممكن يرجع null أو {}
        if (data == null || (data is Map && data.isEmpty)) return null;
        return data is Map ? Map<String, dynamic>.from(data) : null;
      }
      return null; // 404 = ما في contact بعد — مو error
    } catch (e) {
      return null; // network error — ما نوقف الـ loading
    }
  }

  Future<bool> saveEmergencyContact(
    String name,
    String phone,
    String? relation, {
    bool shareLiveLocation = false,
  }) async {
    final tok = await _token();
    if (tok == null) return false;

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.emergencyContact}'),
          headers: _auth(tok),
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'relation': relation,
            'shareLiveLocation': shareLiveLocation,
          }),
        )
        .timeout(const Duration(seconds: 10));

    return res.statusCode == 200 || res.statusCode == 201;
  }

  // ─── Family Members ───────────────────────────────────────
  Future<List<dynamic>> getFamilyMembers() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(Uri.parse('${Api.base}${Api.familyMembers}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) return data;
      if (data is Map && data['members'] is List) {
        return data['members'] as List;
      }
    }
    return [];
  }

  Future<bool> saveFamilyMembers(List<Map<String, dynamic>> members) async {
    final tok = await _token();
    if (tok == null) return false;

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.familyMembers}'),
          headers: _auth(tok),
          body: jsonEncode({'members': members}),
        )
        .timeout(const Duration(seconds: 15));

    return res.statusCode == 200 || res.statusCode == 201;
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import 'model/family_member.dart';

class FamilyApiService {
  FamilyApiService._();
  static final instance = FamilyApiService._();

  static const _storage = FlutterSecureStorage();
  static const _h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> _token() => _storage.read(key: 'passenger_token');
  Map<String, String> _auth(String t) => {..._h, 'Authorization': 'Bearer $t'};

  dynamic _decode(http.Response res) {
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  void _throw(dynamic data, int status) {
    final msg = data is Map ? data['message'] : null;
    throw Exception(
      msg is List ? msg.join(', ') : msg?.toString() ?? 'Error $status',
    );
  }

  Future<FamilyHub> getHub() async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.get(
      Uri.parse('${Api.base}${Api.familyMembers}'),
      headers: _auth(tok),
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return FamilyHub.fromJson(Map<String, dynamic>.from(data as Map));
    }
    _throw(data, res.statusCode);
    throw Exception('Failed');
  }

  Future<FamilyMember> invite(FamilyMember member) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.post(
      Uri.parse('${Api.base}${Api.familyMembers}/invite'),
      headers: _auth(tok),
      body: jsonEncode(member.toInviteJson()),
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return FamilyMember.fromJson(Map<String, dynamic>.from(data as Map));
    }
    _throw(data, res.statusCode);
    throw Exception('Failed');
  }

  Future<void> acceptInvite(int memberId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.post(
      Uri.parse('${Api.base}${Api.familyMembers}/invites/$memberId/accept'),
      headers: _auth(tok),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throw(_decode(res), res.statusCode);
    }
  }

  Future<void> declineInvite(int memberId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.post(
      Uri.parse('${Api.base}${Api.familyMembers}/invites/$memberId/decline'),
      headers: _auth(tok),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throw(_decode(res), res.statusCode);
    }
  }

  Future<void> removeMember(int memberId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.delete(
      Uri.parse('${Api.base}${Api.familyMembers}/members/$memberId'),
      headers: _auth(tok),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      _throw(_decode(res), res.statusCode);
    }
  }

  Future<FamilyHub> saveLegacy(List<Map<String, dynamic>> members) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http.post(
      Uri.parse('${Api.base}${Api.familyMembers}'),
      headers: _auth(tok),
      body: jsonEncode({'members': members}),
    );
    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return FamilyHub.fromJson(Map<String, dynamic>.from(data as Map));
    }
    _throw(data, res.statusCode);
    throw Exception('Failed');
  }
}

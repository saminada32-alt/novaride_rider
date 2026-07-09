import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class ReferralStats {
  final String code;
  final int totalReferrals;
  final int rewarded;
  final int pending;
  final double totalEarned;

  ReferralStats({
    required this.code,
    required this.totalReferrals,
    required this.rewarded,
    required this.pending,
    required this.totalEarned,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> j) => ReferralStats(
    code: j['code']?.toString() ?? '',
    totalReferrals: (j['totalReferrals'] as num?)?.toInt() ?? 0,
    rewarded: (j['rewarded'] as num?)?.toInt() ?? 0,
    pending: (j['pending'] as num?)?.toInt() ?? 0,
    totalEarned: (j['totalEarned'] as num?)?.toDouble() ?? 0,
  );
}

class ReferralService {
  ReferralService._();
  static final ReferralService instance = ReferralService._();
  static const _storage = FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'passenger_token');

  Future<ReferralStats> getMyStats() async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http.get(
      Uri.parse('${Api.base}/referrals/me'),
      headers: {'Authorization': 'Bearer $tok'},
    );
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return ReferralStats.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception(data['message']?.toString() ?? 'Failed');
  }

  Future<void> applyCode(String code) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http.post(
      Uri.parse('${Api.base}/referrals/apply'),
      headers: {
        'Authorization': 'Bearer $tok',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'code': code.trim().toUpperCase()}),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception(data['message']?.toString() ?? 'Failed');
    }
  }
}

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class SplitFareService {
  SplitFareService._();
  static final instance = SplitFareService._();

  static const _storage = FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final tok = await _storage.read(key: 'passenger_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (tok != null) 'Authorization': 'Bearer $tok',
    };
  }

  Future<List<Map<String, dynamic>>> listMyInvites() async {
    final res = await http.get(
      Uri.parse('${Api.base}${Api.splitFareInvitesMe}'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) throw Exception(res.body);
    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> acceptInvite(String token) async {
    final res = await http.post(
      Uri.parse('${Api.base}${Api.splitFareAccept(token)}'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) throw Exception(res.body);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> declineInvite(String token) async {
    final res = await http.post(
      Uri.parse('${Api.base}${Api.splitFareDecline(token)}'),
      headers: await _headers(),
    );
    if (res.statusCode >= 400) throw Exception(res.body);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }

  Future<Map<String, dynamic>> paySplitShare(int rideId, String reference) async {
    final res = await http.post(
      Uri.parse('${Api.base}${Api.splitFarePay(rideId)}'),
      headers: await _headers(),
      body: jsonEncode({'paymentReference': reference}),
    );
    if (res.statusCode >= 400) throw Exception(res.body);
    return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
  }
}

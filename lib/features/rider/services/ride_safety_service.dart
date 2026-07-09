import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class RideSafetyService {
  RideSafetyService._();
  static RideSafetyService instance = RideSafetyService._();

  static const _storage = FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'passenger_token');

  Future<Position?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> triggerSos(int rideId, {double? lat, double? lng}) async {
    final tok = await _token();
    if (tok == null) return false;

    final res = await http
        .post(
          Uri.parse('${Api.base}/rides/$rideId/sos'),
          headers: {
            'Authorization': 'Bearer $tok',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'lat': ?lat,
            'lng': ?lng,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return res.statusCode >= 200 && res.statusCode < 300;
  }

  Future<void> appendTrail(
    int rideId, {
    required double lat,
    required double lng,
  }) async {
    final tok = await _token();
    if (tok == null) return;

    try {
      await http
          .post(
            Uri.parse('${Api.base}/rides/$rideId/location-trail'),
            headers: {
              'Authorization': 'Bearer $tok',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'points': [
                {
                  'lat': lat,
                  'lng': lng,
                  'recordedAt': DateTime.now().toUtc().toIso8601String(),
                },
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {}
  }

  Future<bool> pingShareLocation(
    int rideId, {
    required double lat,
    required double lng,
  }) async {
    final tok = await _token();
    if (tok == null) return false;

    try {
      final res = await http
          .post(
            Uri.parse('${Api.base}/rides/$rideId/share-location'),
            headers: {
              'Authorization': 'Bearer $tok',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'lat': lat, 'lng': lng}),
          )
          .timeout(const Duration(seconds: 12));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return data['shared'] == true;
      }
    } catch (_) {}
    return false;
  }
}

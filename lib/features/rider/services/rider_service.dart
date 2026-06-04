import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/ride_model.dart';
import '../payments/wallet_transaction.dart';

class RiderService {
  RiderService._();
  static RiderService instance = RiderService._();

  static const _storage = FlutterSecureStorage();
  static const _h = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> _token() => _storage.read(key: 'passenger_token');

  Map<String, String> _auth(String t) => {..._h, 'Authorization': 'Bearer $t'};

  Map<String, dynamic> _parse(http.Response res) {
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    final msg = data['message'];
    throw Exception(msg is List ? msg.join(', ') : msg?.toString() ?? 'Error');
  }

  // ─── Create Ride ──────────────────────────────────────────
  // يطابق: POST /rides مع CreateRideDto
  Future<RideModel> createRide({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? pickupAddress,
    String? dropoffAddress,
    DateTime? scheduledAt,
    String? vehicleType,
    String? paymentMethod,
    String? promoCode,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.createRide}'),
          headers: _auth(tok),
          body: jsonEncode({
            'pickupLat': pickupLat,
            'pickupLng': pickupLng,
            'dropoffLat': dropoffLat,
            'dropoffLng': dropoffLng,
            if (pickupAddress != null) 'pickupAddress': pickupAddress,
            if (dropoffAddress != null) 'dropoffAddress': dropoffAddress,
            if (scheduledAt != null)
              'scheduledAt': scheduledAt.toUtc().toIso8601String(),
            if (vehicleType != null) 'vehicleType': vehicleType,
            if (paymentMethod != null) 'paymentMethod': paymentMethod,
            if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return RideModel.fromJson(_parse(res));
  }

  /// تقدير السعر الديناميكي قبل الحجز
  Future<Map<String, dynamic>> estimateFare({
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? vehicleType,
    DateTime? scheduledAt,
    String? promoCode,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final params = {
      'pickupLat': pickupLat.toString(),
      'pickupLng': pickupLng.toString(),
      'dropoffLat': dropoffLat.toString(),
      'dropoffLng': dropoffLng.toString(),
      if (vehicleType != null) 'vehicleType': vehicleType,
      if (scheduledAt != null) 'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
    };

    final uri = Uri.parse('${Api.base}${Api.pricingEstimate}').replace(
      queryParameters: params,
    );

    final res = await http
        .get(uri, headers: _auth(tok))
        .timeout(const Duration(seconds: 12));

    return _parse(res);
  }

  /// سائقون قريبون على الخريطة (أيقونة سيارة)
  Future<List<Map<String, dynamic>>> getNearbyDrivers({
    required double lat,
    required double lng,
    double radiusKm = 5,
  }) async {
    final uri = Uri.parse('${Api.base}${Api.nearbyDrivers}').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
      },
    );
    final res = await http
        .get(uri, headers: _h)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
  }

  Future<Map<String, dynamic>> getSurgeMap() async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http
        .get(Uri.parse('${Api.base}${Api.pricingSurgeMap}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 12));
    return _parse(res);
  }

  Future<Map<String, dynamic>> getSurgeAt(double lat, double lng) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final uri = Uri.parse('${Api.base}${Api.pricingSurgeAt}').replace(
      queryParameters: {'lat': lat.toString(), 'lng': lng.toString()},
    );
    final res = await http.get(uri, headers: _auth(tok)).timeout(const Duration(seconds: 10));
    return _parse(res);
  }

  /// تقدير سعر خدمة خاصة (صهريج، غسيل، نقل…)
  Future<Map<String, dynamic>> estimateSpecialService({
    required String type,
    double? lat,
    double? lng,
    int? barrels,
    String? serviceType,
    String? carType,
    int? cars,
    String? vehicleSize,
    int? workers,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final params = <String, String>{
      'type': type,
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
      if (barrels != null) 'barrels': barrels.toString(),
      if (serviceType != null) 'serviceType': serviceType,
      if (carType != null) 'carType': carType,
      if (cars != null) 'cars': cars.toString(),
      if (vehicleSize != null) 'vehicleSize': vehicleSize,
      if (workers != null) 'workers': workers.toString(),
    };

    final uri = Uri.parse('${Api.base}${Api.pricingSpecialEstimate}').replace(
      queryParameters: params,
    );

    final res = await http
        .get(uri, headers: _auth(tok))
        .timeout(const Duration(seconds: 12));

    return _parse(res);
  }

  // ─── Cancel Ride ──────────────────────────────────────────
  // يطابق: PATCH /rides/:id/cancel
  Future<void> cancelRide(int rideId, {String? reason}) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .patch(
          Uri.parse('${Api.base}/rides/$rideId/cancel'),
          headers: _auth(tok),
          body: jsonEncode({'reason': reason ?? 'Cancelled by passenger'}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 200 && res.statusCode < 300) return;

    final body = utf8.decode(res.bodyBytes);
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final msg = data['message'];
      final text = msg is List ? msg.join(', ') : msg?.toString();
      throw Exception(text ?? body);
    } on FormatException {
      throw Exception(body.isNotEmpty ? body : 'Failed to cancel ride');
    }
  }

  // ─── My Rides as Passenger ────────────────────────────────
  // يطابق: GET /rides/me/passenger
  Future<List<RideModel>> getMyRides() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.myPassengerRides}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data is List ? data : (data['data'] ?? []);
      return (list as List)
          .map((r) => RideModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    }
    return [];
  }

  // ─── Wallet ───────────────────────────────────────────────
  Future<double> getWalletBalance() async {
    final tok = await _token();
    if (tok == null) return 0;

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.passengerWallet}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return double.tryParse(data['balance']?.toString() ?? '0') ?? 0;
    }
    return 0;
  }

  Future<List<WalletTransaction>> getWalletTransactions() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.passengerWalletTransactions}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data is List ? data : (data['data'] ?? []);
      return (list as List)
          .map(
            (e) => WalletTransaction.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> exportPersonalData() async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.passengerDataExport}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 30));

    return _parse(res);
  }

  // ─── Special Order ────────────────────────────────────────
  Future<Map<String, dynamic>?> placeSpecialOrder({
    required String type,
    required Map<String, dynamic> details,
    required String location,
    required double totalPrice,
    double? lat,
    double? lng,
  }) async {
    final tok = await _token();
    if (tok == null) return null;

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.specialOrders}'),
          headers: _auth(tok),
          body: jsonEncode({
            'type': type,
            'details': details,
            'location': location,
            'totalPrice': totalPrice,
            if (lat != null) 'lat': lat,
            if (lng != null) 'lng': lng,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(utf8.decode(res.bodyBytes));
    }
    return null;
  }

  // ─── Promotions ───────────────────────────────────────────
  Future<Map<String, dynamic>> applyPromo(String code) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.applyPromo}'),
          headers: _auth(tok),
          body: jsonEncode({'code': code.trim().toUpperCase()}),
        )
        .timeout(const Duration(seconds: 10));

    return _parse(res);
  }

  Future<List<dynamic>> getPromotions() async {
    final res = await http
        .get(Uri.parse('${Api.base}${Api.promotions}'), headers: _h)
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data is List ? data : [];
    }
    return [];
  }

  Future<void> rateRide(int rideId, int rating, {String? comment}) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}/rides/$rideId/rate'),
          headers: _auth(tok),
          body: jsonEncode({
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      throw Exception(data['message'] ?? 'Failed to submit rating');
    }
  }

  Future<Map<String, dynamic>> getPaymentsConfig() async {
    final res = await http
        .get(Uri.parse('${Api.base}${Api.paymentsConfig}'), headers: _h)
        .timeout(const Duration(seconds: 10));
    return _parse(res);
  }

  Future<Map<String, dynamic>> getPaymentInstructions(int rideId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .get(
          Uri.parse('${Api.base}/rides/$rideId/payment-instructions'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 10));

    return _parse(res);
  }

  Future<RideModel> submitPaymentReference(int rideId, String reference) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .patch(
          Uri.parse('${Api.base}/rides/$rideId/payment-reference'),
          headers: _auth(tok),
          body: jsonEncode({'paymentReference': reference}),
        )
        .timeout(const Duration(seconds: 10));

    return RideModel.fromJson(_parse(res));
  }
}

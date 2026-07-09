import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../models/ride_model.dart';
import '../payments/wallet_transaction.dart';
import '../../../core/services/market_service.dart';

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

  Map<String, dynamic> buildRidePayload({
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
    bool accessibilityRequired = false,
    List<Map<String, dynamic>>? stops,
    String? splitFarePhone,
    int? splitFarePercent,
    String? marketCode,
    bool isPool = false,
    int? poolMaxSeats,
  }) {
    return {
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'pickupAddress': ?pickupAddress,
      'dropoffAddress': ?dropoffAddress,
      if (scheduledAt != null)
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'vehicleType': ?vehicleType,
      'paymentMethod': ?paymentMethod,
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
      if (accessibilityRequired) 'accessibilityRequired': true,
      if (stops != null && stops.isNotEmpty) 'stops': stops,
      if (splitFarePhone != null && splitFarePhone.isNotEmpty)
        'splitFarePhone': splitFarePhone,
      'splitFarePercent': ?splitFarePercent,
      if (marketCode != null && marketCode.isNotEmpty) 'marketCode': marketCode,
      if (isPool) 'isPool': true,
      if (isPool && poolMaxSeats != null) 'poolMaxSeats': poolMaxSeats,
    };
  }

  Future<RideModel> createRideFromPayload(Map<String, dynamic> payload) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.createRide}'),
          headers: _auth(tok),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));
    return RideModel.fromJson(_parse(res));
  }

  // ─── Create Ride ──────────────────────────────────────────
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
    bool accessibilityRequired = false,
    List<Map<String, dynamic>>? stops,
    String? splitFarePhone,
    int? splitFarePercent,
    bool isPool = false,
    int? poolMaxSeats,
  }) async {
    return createRideFromPayload(
      buildRidePayload(
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        dropoffLat: dropoffLat,
        dropoffLng: dropoffLng,
        pickupAddress: pickupAddress,
        dropoffAddress: dropoffAddress,
        scheduledAt: scheduledAt,
        vehicleType: vehicleType,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
        accessibilityRequired: accessibilityRequired,
        stops: stops,
        splitFarePhone: splitFarePhone,
        splitFarePercent: splitFarePercent,
        isPool: isPool,
        poolMaxSeats: poolMaxSeats,
      ),
    );
  }

  Future<RideModel> retrySearch(int rideId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.rideRetrySearch(rideId)}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 15));

    return RideModel.fromJson(_parse(res));
  }

  Future<List<RideModel>> getRetryableRides() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(Uri.parse('${Api.base}${Api.retryableRides}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final list = data is List ? data : [];
      return list
          .map((r) => RideModel.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> getLiveRide(int rideId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.rideLive(rideId)}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 10));

    return _parse(res);
  }

  Future<Map<String, dynamic>> getPoolInfo(int rideId) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.ridePool(rideId)}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 10));

    return _parse(res);
  }

  Future<void> reportRide(
    int rideId, {
    required String type,
    required String description,
    double? lat,
    double? lng,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.rideReport(rideId)}'),
          headers: _auth(tok),
          body: jsonEncode({
            'type': type,
            'description': description,
            'lat': ?lat,
            'lng': ?lng,
          }),
        )
        .timeout(const Duration(seconds: 15));

    _parse(res);
  }

  Future<Map<String, dynamic>> syncOfflineActions(
    List<Map<String, dynamic>> actions,
  ) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.syncOfflineRides}'),
          headers: _auth(tok),
          body: jsonEncode({'actions': actions}),
        )
        .timeout(const Duration(seconds: 30));

    return _parse(res);
  }

  Future<Map<String, dynamic>> submitPrivacyDsr({
    required String type,
    String? details,
    Map<String, dynamic>? rectificationPayload,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.privacyDsr}'),
          headers: _auth(tok),
          body: jsonEncode({
            'type': type,
            if (details != null && details.isNotEmpty) 'details': details,
            'rectificationPayload': ?rectificationPayload,
          }),
        )
        .timeout(const Duration(seconds: 15));

    return _parse(res);
  }

  Future<List<dynamic>> getMyPrivacyRequests() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(Uri.parse('${Api.base}${Api.privacyDsrMe}'), headers: _auth(tok))
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      return data is List ? data : [];
    }
    return [];
  }

  Future<void> cancelPrivacyRequest(int id) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.privacyDsrCancel(id)}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 10));

    _parse(res);
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
    List<Map<String, dynamic>>? stops,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    if (stops != null && stops.isNotEmpty) {
      final points = [
        {'lat': pickupLat, 'lng': pickupLng},
        ...stops,
        {'lat': dropoffLat, 'lng': dropoffLng},
      ];
      double totalFare = 0;
      double totalKm = 0;
      int totalEta = 0;
      Map<String, dynamic>? last;
      for (var i = 0; i < points.length - 1; i++) {
        final seg = await _estimateSegment(
          tok,
          pickupLat: (points[i]['lat'] as num).toDouble(),
          pickupLng: (points[i]['lng'] as num).toDouble(),
          dropoffLat: (points[i + 1]['lat'] as num).toDouble(),
          dropoffLng: (points[i + 1]['lng'] as num).toDouble(),
          vehicleType: vehicleType,
          scheduledAt: scheduledAt,
          promoCode: i == points.length - 2 ? promoCode : null,
        );
        last = seg;
        final selected = seg['selected'] as Map<String, dynamic>? ?? {};
        totalFare += (selected['fare'] as num?)?.toDouble() ?? 0;
        totalKm += (seg['distanceKm'] as num?)?.toDouble() ?? 0;
        totalEta += (seg['etaMinutes'] as num?)?.toInt() ?? 0;
      }
      return {
        ...?last,
        'distanceKm': totalKm,
        'etaMinutes': totalEta,
        'selected': {
          ...(last?['selected'] as Map<String, dynamic>? ?? {}),
          'fare': totalFare,
        },
        'multiStop': true,
      };
    }

    return _estimateSegment(
      tok,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropoffLat: dropoffLat,
      dropoffLng: dropoffLng,
      vehicleType: vehicleType,
      scheduledAt: scheduledAt,
      promoCode: promoCode,
    );
  }

  Future<Map<String, dynamic>> _estimateSegment(
    String tok, {
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
    String? vehicleType,
    DateTime? scheduledAt,
    String? promoCode,
  }) async {
    final params = {
      'pickupLat': pickupLat.toString(),
      'pickupLng': pickupLng.toString(),
      'dropoffLat': dropoffLat.toString(),
      'dropoffLng': dropoffLng.toString(),
      'vehicleType': ?vehicleType,
      if (scheduledAt != null)
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
    };
    final uri = Uri.parse(
      '${Api.base}${Api.pricingEstimate}',
    ).replace(queryParameters: params);
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
        .get(
          Uri.parse('${Api.base}${Api.pricingSurgeMap}'),
          headers: _auth(tok),
        )
        .timeout(const Duration(seconds: 12));
    return _parse(res);
  }

  Future<Map<String, dynamic>> getSurgeAt(double lat, double lng) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final uri = Uri.parse(
      '${Api.base}${Api.pricingSurgeAt}',
    ).replace(queryParameters: {'lat': lat.toString(), 'lng': lng.toString()});
    final res = await http
        .get(uri, headers: _auth(tok))
        .timeout(const Duration(seconds: 10));
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
      'serviceType': ?serviceType,
      'carType': ?carType,
      if (cars != null) 'cars': cars.toString(),
      'vehicleSize': ?vehicleSize,
      if (workers != null) 'workers': workers.toString(),
    };

    final uri = Uri.parse(
      '${Api.base}${Api.pricingSpecialEstimate}',
    ).replace(queryParameters: params);

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

  Future<List<RideModel>> getScheduledRides() async {
    final tok = await _token();
    if (tok == null) return [];

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.myPassengerScheduledRides}'),
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

  Future<RideModel> rescheduleRide(int rideId, DateTime scheduledAt) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .patch(
          Uri.parse('${Api.base}${Api.rideReschedule(rideId)}'),
          headers: _auth(tok),
          body: jsonEncode({
            'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    return RideModel.fromJson(_parse(res));
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
            (e) =>
                WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map)),
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
            'lat': ?lat,
            'lng': ?lng,
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

  Future<void> rateRide(
    int rideId,
    int rating, {
    String? comment,
    List<String>? tags,
    double? tipAmount,
  }) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');

    final res = await http
        .post(
          Uri.parse('${Api.base}/rides/$rideId/rate'),
          headers: _auth(tok),
          body: jsonEncode({
            'rating': rating,
            if (comment != null && comment.isNotEmpty) 'comment': comment,
            if (tags != null && tags.isNotEmpty) 'tags': tags,
            if (tipAmount != null && tipAmount > 0) 'tipAmount': tipAmount,
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

  Future<List<Map<String, dynamic>>> getVehicleTypes() async {
    final res = await http
        .get(Uri.parse('${Api.base}${Api.pricingVehicleTypes}'), headers: _h)
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    return [];
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

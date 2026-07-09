class RideWaypoint {
  final double lat;
  final double lng;
  final String? address;

  const RideWaypoint({required this.lat, required this.lng, this.address});

  factory RideWaypoint.fromJson(Map<String, dynamic> j) => RideWaypoint(
    lat: double.tryParse(j['lat']?.toString() ?? '0') ?? 0,
    lng: double.tryParse(j['lng']?.toString() ?? '0') ?? 0,
    address: j['address']?.toString(),
  );
}

enum RideStatus {
  searching,
  scheduled,
  driver_assigned,
  driver_arrived,
  passenger_onboard,
  trip_started,
  completed,
  cancelled,
  no_driver_found,
}

class RideModel {
  final int id;
  final RideStatus status;
  final double? estimatedFare;
  final double? estimatedDistanceKm;
  final int? etaMinutes;
  final String? cancelReason;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? vehicle;
  final String? vehicleType;
  final String? paymentMethod;
  final String? paymentReference;
  final DateTime? paymentConfirmedAt;
  final String? shamCashReference;
  final int? passengerRating;
  final int? driverRating;
  final double pickupLat;
  final double pickupLng;
  final double dropoffLat;
  final double dropoffLng;
  final String? pickupAddress;
  final String? dropoffAddress;
  final DateTime? scheduledAt;
  final String? promoCode;
  final double? originalFare;
  final double? discountAmount;
  final Map<String, dynamic>? splitFare;
  final List<RideWaypoint> waypoints;
  final List<Map<String, dynamic>> stopProgress;
  final int currentStopIndex;
  final String? rideMode;
  final String? poolGroupId;
  final int? poolSeatIndex;
  final int? maxPoolSeats;
  final bool canRetrySearch;

  const RideModel({
    required this.id,
    required this.status,
    required this.pickupLat,
    required this.pickupLng,
    required this.dropoffLat,
    required this.dropoffLng,
    this.estimatedFare,
    this.estimatedDistanceKm,
    this.etaMinutes,
    this.cancelReason,
    this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.driver,
    this.vehicle,
    this.vehicleType,
    this.paymentMethod,
    this.paymentReference,
    this.paymentConfirmedAt,
    this.shamCashReference,
    this.passengerRating,
    this.driverRating,
    this.pickupAddress,
    this.dropoffAddress,
    this.scheduledAt,
    this.promoCode,
    this.originalFare,
    this.discountAmount,
    this.splitFare,
    this.waypoints = const [],
    this.stopProgress = const [],
    this.currentStopIndex = 0,
    this.rideMode,
    this.poolGroupId,
    this.poolSeatIndex,
    this.maxPoolSeats,
    this.canRetrySearch = false,
  });

  bool get isPool => rideMode == 'pool' || poolGroupId != null;
  bool get hasMultiStop => waypoints.isNotEmpty;

  bool get hasSplitFare => splitFare != null && splitFare!['status'] != null;
  bool get splitFareAccepted => splitFare?['status']?.toString() == 'accepted';
  bool get splitFareDeclined =>
      ['declined', 'cancelled', 'expired'].contains(splitFare?['status']?.toString());
  bool get splitFareFriendPaid => splitFare?['friendPaid'] == true;

  /// رحلة مجدولة لم يحن موعدها بعد — لا تجمّد شاشة الهوم.
  bool get isUpcomingScheduled {
    if (isCompleted || isCancelled) return false;
    if (status == RideStatus.scheduled) return true;
    return status == RideStatus.searching &&
        scheduledAt != null &&
        scheduledAt!.isAfter(DateTime.now());
  }

  /// رحلة جارية الآن (بحث فوري، سائق، في الطريق…).
  bool get isLiveTrip {
    if (isCompleted || isCancelled || isUpcomingScheduled) return false;
    return status == RideStatus.searching ||
        status == RideStatus.driver_assigned ||
        status == RideStatus.driver_arrived ||
        status == RideStatus.passenger_onboard ||
        status == RideStatus.trip_started;
  }

  /// للتوافق مع الشاشات القديمة — يعادل الرحلة الجارية فقط.
  bool get isActive => isLiveTrip;

  bool get isCompleted => status == RideStatus.completed;
  bool get isCancelled => status == RideStatus.cancelled;

  bool get isTerminal =>
      isCompleted ||
      isCancelled ||
      status == RideStatus.no_driver_found;

  bool get hasDriver => driver != null;

  bool get isScheduled => isUpcomingScheduled;

  bool get headingToDropoff =>
      status == RideStatus.trip_started ||
      status == RideStatus.passenger_onboard;

  static RideStatus _parseStatus(String? s) {
    switch (s?.toLowerCase()) {
      case 'driver_assigned':
        return RideStatus.driver_assigned;
      case 'driver_arrived':
        return RideStatus.driver_arrived;
      case 'passenger_onboard':
        return RideStatus.passenger_onboard;
      case 'trip_started':
        return RideStatus.trip_started;
      case 'completed':
        return RideStatus.completed;
      case 'cancelled':
        return RideStatus.cancelled;
      case 'no_driver_found':
        return RideStatus.no_driver_found;
      case 'scheduled':
        return RideStatus.scheduled;
      default:
        return RideStatus.searching;
    }
  }

  factory RideModel.fromJson(Map<String, dynamic> j) => RideModel(
    id: j['id'],
    status: _parseStatus(j['status']?.toString()),
    pickupLat: double.tryParse(j['pickupLat']?.toString() ?? '0') ?? 0,
    pickupLng: double.tryParse(j['pickupLng']?.toString() ?? '0') ?? 0,
    dropoffLat: double.tryParse(j['dropoffLat']?.toString() ?? '0') ?? 0,
    dropoffLng: double.tryParse(j['dropoffLng']?.toString() ?? '0') ?? 0,
    pickupAddress: j['pickupAddress']?.toString(),
    dropoffAddress: j['dropoffAddress']?.toString(),
    estimatedFare: double.tryParse(j['estimatedFare']?.toString() ?? ''),
    estimatedDistanceKm: double.tryParse(
      j['estimatedDistanceKm']?.toString() ?? '',
    ),
    etaMinutes: j['etaMinutes'],
    cancelReason: j['cancelReason'],
    driver: j['driver'] != null ? Map<String, dynamic>.from(j['driver']) : null,
    vehicle: j['vehicle'] != null ? Map<String, dynamic>.from(j['vehicle']) : null,
    vehicleType: j['vehicleType']?.toString(),
    paymentMethod: j['paymentMethod']?.toString(),
    paymentReference: j['paymentReference']?.toString(),
    paymentConfirmedAt: j['paymentConfirmedAt'] != null
        ? DateTime.tryParse(j['paymentConfirmedAt'])
        : null,
    shamCashReference: j['shamCashReference']?.toString(),
    passengerRating: int.tryParse(j['passengerRating']?.toString() ?? ''),
    driverRating: int.tryParse(j['driverRating']?.toString() ?? ''),
    createdAt: j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'])
        : null,
    acceptedAt: j['acceptedAt'] != null
        ? DateTime.tryParse(j['acceptedAt'])
        : null,
    completedAt: j['completedAt'] != null
        ? DateTime.tryParse(j['completedAt'])
        : null,
    scheduledAt: j['scheduledAt'] != null
        ? DateTime.tryParse(j['scheduledAt'])
        : null,
    promoCode: j['promoCode']?.toString(),
    originalFare: double.tryParse(j['originalFare']?.toString() ?? ''),
    discountAmount: double.tryParse(j['discountAmount']?.toString() ?? ''),
    splitFare: j['splitFare'] != null
        ? Map<String, dynamic>.from(j['splitFare'] as Map)
        : null,
    waypoints: (j['waypoints'] as List<dynamic>? ?? [])
        .map((e) => RideWaypoint.fromJson(e as Map<String, dynamic>))
        .where((w) => w.lat.abs() > 0.01 && w.lng.abs() > 0.01)
        .toList(),
    stopProgress: (j['stopProgress'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
    currentStopIndex: int.tryParse(j['currentStopIndex']?.toString() ?? '0') ?? 0,
    rideMode: j['rideMode']?.toString(),
    poolGroupId: j['poolGroupId']?.toString(),
    poolSeatIndex: int.tryParse(j['poolSeatIndex']?.toString() ?? ''),
    maxPoolSeats: int.tryParse(j['maxPoolSeats']?.toString() ?? ''),
    canRetrySearch: j['canRetrySearch'] == true,
  );
}

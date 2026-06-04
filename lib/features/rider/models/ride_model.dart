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
  });

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
  );
}

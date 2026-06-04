import '../config/app_config.dart';

class Api {
  Api._();

  /// عنوان الـ API حسب البيئة (dev/staging/prod) — يُحقن وقت البناء.
  static String get base => AppConfig.apiBaseUrl;

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';

  // Passenger
  static const String passengerMe = '/passengers/me';
  static const String passengerRides = '/passengers/me/rides';
  static const String passengerWallet = '/passengers/me/wallet';
  static const String passengerWalletTransactions =
      '/passengers/me/wallet/transactions';
  static const String passengerDataExport = '/passengers/me/data-export';
  static const String emergencyContact = '/passengers/me/emergency-contact';
  static const String familyMembers = '/passengers/me/family';
  static const String uploadPassengerProfile = '/uploads/passenger-profile';

  // Special Orders
  static const String specialOrders = '/special-orders';
  static const String mySpecialOrders = '/special-orders/my';

  // Rides ← يطابق الباك اند الموجود
  static const String createRide = '/rides'; // POST
  static const String myPassengerRides = '/rides/me/passenger'; // GET

  // Promotions
  static const String applyPromo = '/promotions/apply';
  static const String promotions = '/promotions';

  // Pricing
  static const String pricingConfig = '/pricing/config';
  static const String pricingEstimate = '/pricing/estimate';
  static const String pricingZones = '/pricing/zones';
  static const String pricingSpecial = '/pricing/special';
  static const String pricingSpecialEstimate = '/pricing/special/estimate';
  static const String pricingSurgeMap = '/pricing/surge-map';
  static const String pricingSurgeAt = '/pricing/surge-at';

  // Locations
  static const String nearbyDrivers = '/locations/nearby-drivers';

  // Payments
  static const String paymentsConfig = '/payments/config';
}

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
  static const String passengerPlaces = '/passengers/me/places';
  static String passengerPlace(int id) => '/passengers/me/places/$id';
  static const String uploadPassengerProfile = '/uploads/passenger-profile';

  // Special Orders
  static const String specialOrders = '/special-orders';
  static const String mySpecialOrders = '/special-orders/my';

  // Rides ← يطابق الباك اند الموجود
  static const String createRide = '/rides'; // POST
  static const String myPassengerRides = '/rides/me/passenger'; // GET
  static const String myPassengerScheduledRides = '/rides/me/passenger/scheduled';
  static const String retryableRides = '/rides/me/retryable';
  static const String syncOfflineRides = '/rides/sync-offline';
  static String rideLive(int id) => '/rides/$id/live';
  static String ridePool(int id) => '/rides/$id/pool';
  static String rideRetrySearch(int id) => '/rides/$id/retry-search';
  static String rideReport(int id) => '/rides/$id/report';
  static String rideReschedule(int id) => '/rides/$id/reschedule';

  // Privacy DSR
  static const String privacyDsr = '/privacy/dsr';
  static const String privacyDsrMe = '/privacy/dsr/me';
  static String privacyDsrCancel(int id) => '/privacy/dsr/me/$id/cancel';

  // Promotions
  static const String applyPromo = '/promotions/apply';
  static const String promotions = '/promotions';

  // Pricing
  static const String pricingConfig = '/pricing/config';
  static const String pricingVehicleTypes = '/pricing/vehicle-types';
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

  // Split fare
  static const String splitFareInvitesMe = '/split-fare/invites/me';
  static String splitFareAccept(String token) => '/split-fare/invites/$token/accept';
  static String splitFareDecline(String token) => '/split-fare/invites/$token/decline';
  static String splitFarePay(int rideId) => '/split-fare/rides/$rideId/pay';

  // Legal
  static const String legalDocuments = '/legal/documents';
  static String legalDocument(String slug) => '/legal/documents/$slug';
  static const String legalConsent = '/legal/consent';
  static const String legalConsentStatus = '/legal/consent/status';
  static const String legalPdf = '/legal/pdf';

  // Content CMS
  static const String contentFaq = '/content/faq';
  static const String contentBanners = '/content/banners';
}

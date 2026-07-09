import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

/// موقع افتراضي للتطوير المحلي — دمشق.
/// في prod/staging يُستخدم GPS الفعلي لكل مناطق سوريا.
abstract final class AppDefaultLocation {
  static const double latitude = 33.5138;
  static const double longitude = 36.2765;
  static const LatLng damascus = LatLng(latitude, longitude);

  static const String pickupLabelAr = 'دمشق';
  static const String pickupLabelEn = 'Damascus';

  /// `true` فقط في dev — يثبت الخريطة على دمشق للاختبار.
  static bool get pinToDamascus => AppConfig.isDev;

  static String pickupLabel(String languageCode) =>
      languageCode == 'ar' ? pickupLabelAr : pickupLabelEn;
}

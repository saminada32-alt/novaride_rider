import 'package:google_maps_flutter/google_maps_flutter.dart';

/// موقع افتراضي مؤقت — دمشق. عطّل [pinToDamascus] لاحقاً لاستخدام GPS.
abstract final class AppDefaultLocation {
  static const double latitude = 33.5138;
  static const double longitude = 36.2765;
  static const LatLng damascus = LatLng(latitude, longitude);

  static const String pickupLabelAr = 'دمشق';
  static const String pickupLabelEn = 'Damascus';

  /// `true` = التطبيق يستخدم دمشق كموقع التقاط حتى نربط GPS.
  static const bool pinToDamascus = true;

  static String pickupLabel(String languageCode) =>
      languageCode == 'ar' ? pickupLabelAr : pickupLabelEn;
}

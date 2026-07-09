import 'package:flutter/material.dart';
import '../../../core/utils/media_url.dart';
import '../../../core/widgets/authed_network_image.dart';

String? riderDriverPhotoUrl(Map<String, dynamic>? driver) =>
    resolveMediaUrl(
      driver?['profileImage']?.toString() ??
          driver?['driverPhoto']?.toString(),
    );

String? riderVehicleImageUrl(Map<String, dynamic>? vehicle) =>
    resolveMediaUrl(vehicle?['imageUrl']?.toString());

Widget _networkImageBox({
  required String url,
  required double width,
  required double height,
  required BoxFit fit,
  required Widget fallback,
}) {
  return SizedBox(
    width: width,
    height: height,
    child: AuthedNetworkImage(
      url: url,
      fit: fit,
      fallback: fallback,
    ),
  );
}

Widget riderDriverAvatar(Map<String, dynamic>? driver, {double size = 44}) {
  final url = riderDriverPhotoUrl(driver);
  if (url != null) {
    return ClipOval(
      child: _networkImageBox(
        url: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: Icon(Icons.person_rounded, size: size * 0.5, color: Colors.black54),
      ),
    );
  }
  return Icon(Icons.person_rounded, size: size * 0.5, color: Colors.black54);
}

Widget riderVehicleImage(Map<String, dynamic>? vehicle, {double height = 72}) {
  final url = riderVehicleImageUrl(vehicle);
  if (url != null) {
    return _networkImageBox(
      url: url,
      width: height * 1.6,
      height: height,
      fit: BoxFit.contain,
      fallback: Icon(Icons.directions_car_filled_rounded, size: height * 0.55, color: Colors.black45),
    );
  }
  return Icon(Icons.directions_car_filled_rounded, size: height * 0.55, color: Colors.black45);
}

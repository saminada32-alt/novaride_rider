import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class ResolvedLocation {
  final double lat;
  final double lng;
  final String address;
  const ResolvedLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

/// Gets the device's current GPS position and reverse-geocodes it to a
/// human-readable address. Returns null if location services/permission are
/// unavailable or the lookup fails — callers must treat that as a real
/// failure (show an error), not silently proceed with a placeholder.
Future<ResolvedLocation?> resolveCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(const Duration(seconds: 10));

    String address = '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [p.street, p.subLocality, p.locality]
            .where((s) => s != null && s.trim().isNotEmpty)
            .toList();
        if (parts.isNotEmpty) address = parts.join('، ');
      }
    } catch (_) {
      // Reverse geocoding failed — keep the raw coordinates as the address;
      // lat/lng below are still correct and usable for the order.
    }

    return ResolvedLocation(lat: pos.latitude, lng: pos.longitude, address: address);
  } catch (_) {
    return null;
  }
}

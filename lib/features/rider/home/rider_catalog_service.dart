import 'package:flutter/material.dart';
import '../services/rider_service.dart';
import 'rider_vehicle_options.dart';

class RiderCatalogService {
  RiderCatalogService._();
  static final instance = RiderCatalogService._();

  List<VehicleOption> _vehicles = riderHomeVehicleOptions;
  bool _loaded = false;

  List<VehicleOption> get vehicles => _vehicles;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    try {
      final list = await RiderService.instance.getVehicleTypes();
      if (list.isNotEmpty) {
        _vehicles = list
            .where((e) => !riderHiddenVehicleIds.contains(e['id']))
            .map(
              (e) => VehicleOption(
                id: e['id'] as String,
                icon: _iconFor(e['icon'] as String? ?? e['id'] as String),
                multiplier: (e['multiplier'] as num?)?.toDouble() ?? 1.0,
                labelAr: e['labelAr'] as String?,
                labelEn: e['labelEn'] as String?,
                subtitleAr: e['subtitleAr'] as String?,
                subtitleEn: e['subtitleEn'] as String?,
              ),
            )
            .toList();
      }
    } catch (_) {
      // Keep static fallback.
    }
    _loaded = true;
  }

  static IconData _iconFor(String key) {
    switch (key) {
      case 'motorcycle':
        return Icons.two_wheeler_rounded;
      case 'van':
        return Icons.airport_shuttle_rounded;
      case 'taxi':
        return Icons.local_taxi_rounded;
      case 'wheelchair_accessible':
        return Icons.accessible_rounded;
      default:
        return Icons.directions_car_filled_rounded;
    }
  }
}

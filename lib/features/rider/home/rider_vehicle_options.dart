import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class VehicleOption {
  final String id;
  final IconData icon;
  final double multiplier;
  final String? labelAr;
  final String? labelEn;
  final String? subtitleAr;
  final String? subtitleEn;

  const VehicleOption({
    required this.id,
    required this.icon,
    required this.multiplier,
    this.labelAr,
    this.labelEn,
    this.subtitleAr,
    this.subtitleEn,
  });

  String displayLabel(
    bool isAr, {
    required String car,
    required String van,
    required String taxi,
    required String accessible,
    required String moto,
  }) {
    if (isAr && labelAr != null && labelAr!.isNotEmpty) return labelAr!;
    if (!isAr && labelEn != null && labelEn!.isNotEmpty) return labelEn!;
    return vehicleLabel(
      id,
      car: car,
      van: van,
      taxi: taxi,
      accessible: accessible,
      moto: moto,
    );
  }

  String displaySubtitle(bool isAr, AppLocalizations l) {
    if (isAr && subtitleAr != null && subtitleAr!.isNotEmpty) return subtitleAr!;
    if (!isAr && subtitleEn != null && subtitleEn!.isNotEmpty) return subtitleEn!;
    return vehicleSubtitle(id, l);
  }
}

const riderHiddenVehicleIds = {'scooter', 'wheelchair_accessible'};

const riderHomeVehicleOptions = [
  VehicleOption(
    id: 'car',
    icon: Icons.directions_car_filled_rounded,
    multiplier: 1.0,
  ),
  VehicleOption(
    id: 'motorcycle',
    icon: Icons.two_wheeler_rounded,
    multiplier: 0.75,
  ),
  VehicleOption(
    id: 'van',
    icon: Icons.airport_shuttle_rounded,
    multiplier: 1.5,
  ),
  VehicleOption(
    id: 'taxi',
    icon: Icons.local_taxi_rounded,
    multiplier: 1.2,
  ),
];

String vehicleLabel(
  String id, {
  required String car,
  required String van,
  required String taxi,
  required String accessible,
  required String moto,
}) {
  switch (id) {
    case 'motorcycle':
      return moto;
    case 'van':
      return van;
    case 'taxi':
      return taxi;
    case 'wheelchair_accessible':
      return accessible;
    default:
      return car;
  }
}

String vehicleSubtitle(String id, AppLocalizations l) {
  switch (id) {
    case 'motorcycle':
      return l.vehicleMotoSubtitle;
    case 'van':
      return l.vehicleVanSeatsSubtitle;
    case 'taxi':
      return l.vehicleTaxiSubtitle;
    case 'wheelchair_accessible':
      return l.accessibleRide;
    default:
      return l.vehicleCarSeatsSubtitle;
  }
}

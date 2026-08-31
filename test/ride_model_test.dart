import 'package:flutter_test/flutter_test.dart';
import 'package:novaride_rider/features/rider/models/ride_model.dart';

Map<String, dynamic> baseRideJson({
  String status = 'SEARCHING',
  Map<String, dynamic>? extra,
}) => {
  'id': 42,
  'status': status,
  'pickupLat': 33.5138,
  'pickupLng': 36.2765,
  'dropoffLat': 33.52,
  'dropoffLng': 36.29,
  ...?extra,
};

void main() {
  group('RideModel.fromJson — status parsing (must match backend RideStatus enum)', () {
    const backendToClient = {
      'SEARCHING': RideStatus.searching,
      'SCHEDULED': RideStatus.scheduled,
      'DRIVER_ASSIGNED': RideStatus.driver_assigned,
      'DRIVER_ARRIVED': RideStatus.driver_arrived,
      'PASSENGER_ONBOARD': RideStatus.passenger_onboard,
      'TRIP_STARTED': RideStatus.trip_started,
      'COMPLETED': RideStatus.completed,
      'CANCELLED': RideStatus.cancelled,
      'NO_DRIVER_FOUND': RideStatus.no_driver_found,
    };

    backendToClient.forEach((backendValue, expected) {
      test('"$backendValue" → $expected', () {
        final ride = RideModel.fromJson(baseRideJson(status: backendValue));
        expect(ride.status, expected);
      });
    });

    test('unknown/missing status silently falls back to searching', () {
      expect(
        RideModel.fromJson(baseRideJson(status: 'SOME_NEW_STATUS')).status,
        RideStatus.searching,
      );
      final json = baseRideJson()..remove('status');
      expect(RideModel.fromJson(json).status, RideStatus.searching);
    });
  });

  group('RideModel.fromJson — field parsing', () {
    test('parses numeric and date fields', () {
      final ride = RideModel.fromJson(baseRideJson(extra: {
        'estimatedFare': '15000',
        'estimatedDistanceKm': 4.2,
        'createdAt': '2025-05-10T12:00:00.000Z',
        'paymentConfirmedAt': '2025-05-10T12:05:00.000Z',
      }));
      expect(ride.estimatedFare, 15000);
      expect(ride.estimatedDistanceKm, 4.2);
      expect(ride.createdAt, DateTime.parse('2025-05-10T12:00:00.000Z'));
      expect(ride.paymentConfirmedAt, DateTime.parse('2025-05-10T12:05:00.000Z'));
    });

    test('missing optional fields default to null without throwing', () {
      final ride = RideModel.fromJson(baseRideJson());
      expect(ride.estimatedFare, isNull);
      expect(ride.driver, isNull);
      expect(ride.createdAt, isNull);
      expect(ride.waypoints, isEmpty);
    });

    test('filters out placeholder (near 0,0) waypoints', () {
      final ride = RideModel.fromJson(baseRideJson(extra: {
        'waypoints': [
          {'lat': 33.51, 'lng': 36.28, 'address': 'real stop'},
          {'lat': 0, 'lng': 0}, // placeholder — must be dropped
          {'lat': 0.005, 'lng': 40.0}, // lat too close to 0 — must be dropped
        ],
      }));
      expect(ride.waypoints, hasLength(1));
      expect(ride.waypoints.single.address, 'real stop');
      expect(ride.hasMultiStop, isTrue);
    });
  });

  group('RideModel — derived state getters', () {
    test('isLiveTrip is true for every in-progress status, false otherwise', () {
      const live = {
        RideStatus.driver_assigned,
        RideStatus.driver_arrived,
        RideStatus.passenger_onboard,
        RideStatus.trip_started,
      };
      for (final status in RideStatus.values) {
        final ride = RideModel.fromJson(baseRideJson(status: status.name.toUpperCase()));
        final expected = live.contains(status) ||
            (status == RideStatus.searching);
        expect(
          ride.isLiveTrip,
          expected,
          reason: 'status=$status',
        );
      }
    });

    test('isCompleted / isCancelled / isTerminal', () {
      expect(RideModel.fromJson(baseRideJson(status: 'COMPLETED')).isCompleted, isTrue);
      expect(RideModel.fromJson(baseRideJson(status: 'CANCELLED')).isCancelled, isTrue);
      expect(RideModel.fromJson(baseRideJson(status: 'NO_DRIVER_FOUND')).isTerminal, isTrue);
      expect(RideModel.fromJson(baseRideJson(status: 'SEARCHING')).isTerminal, isFalse);
    });

    test('headingToDropoff only true for passenger_onboard/trip_started', () {
      expect(
        RideModel.fromJson(baseRideJson(status: 'TRIP_STARTED')).headingToDropoff,
        isTrue,
      );
      expect(
        RideModel.fromJson(baseRideJson(status: 'PASSENGER_ONBOARD')).headingToDropoff,
        isTrue,
      );
      expect(
        RideModel.fromJson(baseRideJson(status: 'DRIVER_ASSIGNED')).headingToDropoff,
        isFalse,
      );
    });

    test('isUpcomingScheduled: SCHEDULED status is always upcoming', () {
      final ride = RideModel.fromJson(baseRideJson(status: 'SCHEDULED'));
      expect(ride.isUpcomingScheduled, isTrue);
      expect(ride.isLiveTrip, isFalse);
    });

    test('isUpcomingScheduled: SEARCHING + future scheduledAt is upcoming', () {
      final future = DateTime.now().add(const Duration(hours: 2)).toIso8601String();
      final ride = RideModel.fromJson(baseRideJson(
        status: 'SEARCHING',
        extra: {'scheduledAt': future},
      ));
      expect(ride.isUpcomingScheduled, isTrue);
    });

    test('isUpcomingScheduled: SEARCHING + past scheduledAt is not upcoming', () {
      final past = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      final ride = RideModel.fromJson(baseRideJson(
        status: 'SEARCHING',
        extra: {'scheduledAt': past},
      ));
      expect(ride.isUpcomingScheduled, isFalse);
      expect(ride.isLiveTrip, isTrue);
    });

    group('split fare state', () {
      test('hasSplitFare / splitFareAccepted / splitFareDeclined', () {
        final accepted = RideModel.fromJson(baseRideJson(extra: {
          'splitFare': {'status': 'accepted', 'friendPaid': true},
        }));
        expect(accepted.hasSplitFare, isTrue);
        expect(accepted.splitFareAccepted, isTrue);
        expect(accepted.splitFareFriendPaid, isTrue);
        expect(accepted.splitFareDeclined, isFalse);

        for (final s in ['declined', 'cancelled', 'expired']) {
          final ride = RideModel.fromJson(baseRideJson(extra: {
            'splitFare': {'status': s},
          }));
          expect(ride.splitFareDeclined, isTrue, reason: 'status=$s');
        }

        final none = RideModel.fromJson(baseRideJson());
        expect(none.hasSplitFare, isFalse);
      });
    });

    test('isPool via rideMode or poolGroupId', () {
      expect(
        RideModel.fromJson(baseRideJson(extra: {'rideMode': 'pool'})).isPool,
        isTrue,
      );
      expect(
        RideModel.fromJson(baseRideJson(extra: {'poolGroupId': 'grp_1'})).isPool,
        isTrue,
      );
      expect(RideModel.fromJson(baseRideJson()).isPool, isFalse);
    });
  });
}

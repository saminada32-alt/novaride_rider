import '../../features/rider/models/ride_model.dart';
import '../../l10n/app_localizations.dart';

String rideTripStatusLabel(RideStatus status, AppLocalizations t) {
  switch (status) {
    case RideStatus.scheduled:
      return t.tripStatusScheduled;
    case RideStatus.searching:
      return t.tripStatusSearching;
    case RideStatus.driver_assigned:
      return t.tripStatusAssigned;
    case RideStatus.driver_arrived:
      return t.tripStatusArrived;
    case RideStatus.passenger_onboard:
      return t.tripStatusOnboard;
    case RideStatus.trip_started:
      return t.tripStatusStarted;
    case RideStatus.completed:
      return t.tripStatusCompleted;
    case RideStatus.cancelled:
      return t.tripStatusCancelled;
    case RideStatus.no_driver_found:
      return t.tripStatusNoDriver;
  }
}

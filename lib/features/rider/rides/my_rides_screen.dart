import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';
import 'schedule_ride_screen.dart';

class MyRidesScreen extends StatefulWidget {
  const MyRidesScreen({super.key});
  @override
  State<MyRidesScreen> createState() => _MyRidesScreenState();
}

class _MyRidesScreenState extends State<MyRidesScreen> {
  List<RideModel> _rides = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _rides = await RiderService.instance.getMyRides();
    setState(() => _loading = false);
  }

  String _fmt(DateTime? d) {
    if (d == null) return '';
    final l = d.toLocal();
    return '${l.day}/${l.month}/${l.year}';
  }

  Color _color(RideStatus s) {
    switch (s) {
      case RideStatus.completed:
        return Colors.green;
      case RideStatus.cancelled:
        return Colors.red;
      case RideStatus.no_driver_found:
        return Colors.red;
      case RideStatus.trip_started:
        return Colors.purple;
      case RideStatus.driver_assigned:
      case RideStatus.driver_arrived:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;

    //final past = _rides.where((r) => !r.isActive).toList();
    final now = DateTime.now();

    final past = _rides.where((r) {
      return r.scheduledAt == null ||
          r.scheduledAt!.isBefore(now) ||
          r.status == RideStatus.completed ||
          r.status == RideStatus.cancelled;
    }).toList();
    final upcoming = _rides
        .where(
          (r) =>
              r.status == RideStatus.scheduled ||
              r.status == RideStatus.driver_assigned ||
              r.status == RideStatus.driver_arrived ||
              r.status == RideStatus.passenger_onboard ||
              r.status == RideStatus.trip_started,
        )
        .toList();

    print(_rides.map((e) => e.status).toList());
    //final upcoming = _rides.where((r) => r.isActive).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(local.myRides),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: local.past),
              Tab(text: local.upcoming),
            ],
          ),
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
            : TabBarView(
                children: [
                  _ridesList(past, local, empty: local.noPastRides),
                  _ridesList(
                    upcoming,
                    local,
                    empty: local.noUpcomingRides,
                    showSchedule: true,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _ridesList(
    List<RideModel> rides,
    AppLocalizations local, {
    required String empty,
    bool showSchedule = false,
  }) {
    if (rides.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Image.asset(
                showSchedule
                    ? 'assets/images/upcoming_empty.png'
                    : 'assets/images/past_empty.png',
                height: 220,
              ),
              const SizedBox(height: 16),
              Text(
                empty,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showSchedule) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ScheduleRideScreen(),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    local.scheduleRideButton,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: Colors.green,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rides.length,
        itemBuilder: (_, i) {
          final ride = rides[i];
          final color = _color(ride.status);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ride #${ride.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _fmt(ride.createdAt),
                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      ),
                      if (ride.etaMinutes != null && ride.isActive)
                        Text(
                          'ETA: ${ride.etaMinutes} min',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ride.estimatedFare != null
                          ? CurrencyUtils.formatSyp(ride.estimatedFare)
                          : '—',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        ride.status.name.replaceAll('_', ' '),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

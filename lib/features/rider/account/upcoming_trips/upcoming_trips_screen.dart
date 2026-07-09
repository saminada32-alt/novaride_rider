import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/a11y.dart';
import '../../../../core/utils/ride_trip_status.dart';
import '../../../../l10n/app_localizations.dart';
import '../../services/rider_service.dart';
import '../../models/ride_model.dart';
import '../../rides/schedule_ride_screen.dart';

class UpcomingTripsScreen extends StatefulWidget {
  const UpcomingTripsScreen({super.key});
  @override
  State<UpcomingTripsScreen> createState() => _UpcomingTripsScreenState();
}

class _UpcomingTripsScreenState extends State<UpcomingTripsScreen> {
  List<RideModel> _rides = [];
  final Map<int, ({String pickup, String dropoff})> _addresses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isUpcoming(RideModel r) {
    if (r.isCompleted || r.status == RideStatus.cancelled) return false;
    return r.isLiveTrip || r.isUpcomingScheduled;
  }

  Future<String> _resolveLabel(String? address, double lat, double lng) async {
    if (address != null && address.trim().isNotEmpty) return address.trim();
    try {
      final marks = await placemarkFromCoordinates(lat, lng);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final parts = [
          p.street,
          p.subLocality,
          p.locality,
          p.administrativeArea,
        ].where((e) => e != null && e.trim().isNotEmpty).map((e) => e!.trim());
        final line = parts.join(', ');
        if (line.isNotEmpty) return line;
      }
    } catch (_) {}
    return '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await RiderService.instance.getMyRides();
      final upcoming = all.where(_isUpcoming).toList()
        ..sort((a, b) {
          final da = a.scheduledAt ?? a.createdAt ?? DateTime(0);
          final db = b.scheduledAt ?? b.createdAt ?? DateTime(0);
          return da.compareTo(db);
        });

      final addr = <int, ({String pickup, String dropoff})>{};
      for (final r in upcoming) {
        addr[r.id] = (
          pickup: await _resolveLabel(
            r.pickupAddress,
            r.pickupLat,
            r.pickupLng,
          ),
          dropoff: await _resolveLabel(
            r.dropoffAddress,
            r.dropoffLat,
            r.dropoffLng,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _rides = upcoming;
        _addresses
          ..clear()
          ..addAll(addr);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _rides = [];
        _loading = false;
      });
    }
  }

  String _fmtDateTime(DateTime? d) {
    if (d == null) return '';
    return '${d.day}/${d.month}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(RideStatus s, AppLocalizations l) =>
      rideTripStatusLabel(s, l);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.upcomingTrips,
      child: Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.upcomingTrips)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              color: Colors.green,
              onRefresh: _load,
              child: _rides.isEmpty
                  ? _emptyState(l)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rides.length,
                      itemBuilder: (_, i) => _rideCard(_rides[i], l),
                    ),
            ),
    ),
    );
  }

  Widget _emptyState(AppLocalizations l) => ListView(
    children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.15),
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/no_trips.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l.noUpcomingTrips,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScheduleRideScreen()),
                ),
                child: Container(
                  height: 55,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xff16a34a),
                        const Color(0xff16a34a).withOpacity(.7),
                      ],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l.bookNow,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _rideCard(RideModel ride, AppLocalizations l) {
    Color color;
    switch (ride.status) {
      case RideStatus.driver_assigned:
        color = Colors.blue;
        break;
      case RideStatus.trip_started:
        color = Colors.purple;
        break;
      case RideStatus.driver_arrived:
        color = Colors.teal;
        break;
      case RideStatus.scheduled:
        color = Colors.indigo;
        break;
      default:
        color = Colors.orange;
    }

    final labels = _addresses[ride.id];
    final pickup = labels?.pickup ?? '—';
    final dropoff = labels?.dropoff ?? '—';
    final when = ride.scheduledAt ?? ride.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.directions_car, color: color, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.rideNumber(ride.id),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(ride.status, l),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _routeRow(Icons.radio_button_checked, Colors.green, pickup),
          const SizedBox(height: 6),
          _routeRow(Icons.location_on, Colors.red, dropoff),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _fmtDateTime(when),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
              Text(
                CurrencyUtils.formatSyp(ride.estimatedFare),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, Color color, String text) => Row(
    children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

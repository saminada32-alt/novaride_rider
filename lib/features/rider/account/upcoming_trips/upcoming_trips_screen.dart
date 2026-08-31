import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../core/utils/api_error_messages.dart';
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
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isUpcoming(RideModel r) {
    if (r.isCompleted || r.status == RideStatus.cancelled) return false;
    return r.isLiveTrip || r.isUpcomingScheduled;
  }

  bool _canCancel(RideModel ride) =>
      ride.status == RideStatus.scheduled ||
      ride.status == RideStatus.searching ||
      ride.status == RideStatus.driver_assigned ||
      ride.status == RideStatus.driver_arrived ||
      ride.status == RideStatus.no_driver_found;

  Future<void> _cancelRide(RideModel ride) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cancel_ride),
        content: Text(l.cancel_ride_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.keep_Ride),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l.cancelRideAction),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _cancelling.add(ride.id));
    try {
      await RiderService.instance.cancelRide(ride.id);
      if (!mounted) return;
      setState(() {
        _rides.removeWhere((r) => r.id == ride.id);
        _cancelling.remove(ride.id);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling.remove(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiError(e.toString(), AppLocalizations.of(context)!)),
        ),
      );
    }
  }

  Future<void> _reschedule(RideModel ride) async {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now().add(const Duration(minutes: 30));
    final initial = ride.scheduledAt ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? initial : now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final newAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (newAt.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.scheduleMinLeadTime)),
      );
      return;
    }

    try {
      final updated = await RiderService.instance.rescheduleRide(ride.id, newAt);
      if (!mounted) return;
      setState(() {
        final i = _rides.indexWhere((r) => r.id == ride.id);
        if (i >= 0) _rides[i] = updated;
        _rides.sort((a, b) {
          final da = a.scheduledAt ?? a.createdAt ?? DateTime(0);
          final db = b.scheduledAt ?? b.createdAt ?? DateTime(0);
          return da.compareTo(db);
        });
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.rescheduleRideSuccess),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeApiError(e.toString(), l)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetails(RideModel ride) {
    final labels = _addresses[ride.id];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _TripDetailsSheet(
        ride: ride,
        pickup: labels?.pickup ?? '—',
        dropoff: labels?.dropoff ?? '—',
        when: _fmtDateTime(ride.scheduledAt ?? ride.createdAt),
        statusLabel: _statusLabel(ride.status, AppLocalizations.of(context)!),
        canCancel: _canCancel(ride),
        canReschedule: ride.status == RideStatus.scheduled,
        cancelling: _cancelling.contains(ride.id),
        onCancel: () {
          Navigator.pop(sheetCtx);
          _cancelRide(ride);
        },
        onReschedule: () {
          Navigator.pop(sheetCtx);
          _reschedule(ride);
        },
      ),
    );
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetails(ride),
          child: Padding(
      padding: const EdgeInsets.all(16),
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
          if (_canCancel(ride)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _cancelling.contains(ride.id)
                    ? null
                    : () => _cancelRide(ride),
                icon: _cancelling.contains(ride.id)
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.close_rounded, size: 18),
                label: Text(l.cancel_ride),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
          ),
        ),
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

class _TripDetailsSheet extends StatelessWidget {
  final RideModel ride;
  final String pickup;
  final String dropoff;
  final String when;
  final String statusLabel;
  final bool canCancel;
  final bool canReschedule;
  final bool cancelling;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  const _TripDetailsSheet({
    required this.ride,
    required this.pickup,
    required this.dropoff,
    required this.when,
    required this.statusLabel,
    required this.canCancel,
    required this.canReschedule,
    required this.cancelling,
    required this.onCancel,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.rideNumber(ride.id),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(when, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 20),
            _row(Icons.radio_button_checked_rounded, Colors.green, pickup),
            const SizedBox(height: 10),
            _row(Icons.location_on_rounded, Colors.red, dropoff),
            if (ride.estimatedFare != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    l.estimatedPrice,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    CurrencyUtils.formatSyp(ride.estimatedFare),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            if (canReschedule || canCancel) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  if (canReschedule)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onReschedule,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue.shade700,
                          side: BorderSide(color: Colors.blue.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                        label: Text(l.rescheduleRideAction),
                      ),
                    ),
                  if (canReschedule && canCancel) const SizedBox(width: 10),
                  if (canCancel)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: cancelling ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: cancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.close_rounded, size: 18),
                        label: Text(l.cancel_ride),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      );
}

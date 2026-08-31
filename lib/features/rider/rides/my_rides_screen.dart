import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/ride_trip_status.dart';
import '../../../core/widgets/a11y.dart';
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
  bool _error = false;
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final rides = await RiderService.instance.getMyRides();
      if (!mounted) return;
      setState(() => _rides = rides);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  bool _canCancel(RideModel ride) =>
      ride.status == RideStatus.scheduled ||
      ride.status == RideStatus.searching ||
      ride.status == RideStatus.driver_assigned ||
      ride.status == RideStatus.driver_arrived ||
      ride.status == RideStatus.no_driver_found;

  Future<void> _cancelRide(RideModel ride) async {
    final l = AppLocalizations.of(context)!;
    final isScheduled = ride.status == RideStatus.scheduled;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isScheduled ? l.cancelScheduledRideTitle : l.cancel_ride,
        ),
        content: Text(
          isScheduled ? l.cancelScheduledRideConfirm : l.cancel_ride_confirm,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.ride_cancelled),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling.remove(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.actionFailed),
          backgroundColor: Colors.red,
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

    final newAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
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
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.rescheduleRideSuccess), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDetails(RideModel ride) {
    final local = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => _RideDetailsSheet(
        ride: ride,
        statusColor: _color(ride.status),
        statusLabel: rideTripStatusLabel(ride.status, local),
        dateLabel: _fmt(ride.createdAt),
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
              r.status == RideStatus.searching ||
              r.status == RideStatus.no_driver_found ||
              r.status == RideStatus.driver_assigned ||
              r.status == RideStatus.driver_arrived ||
              r.status == RideStatus.passenger_onboard ||
              r.status == RideStatus.trip_started,
        )
        .toList();

    //final upcoming = _rides.where((r) => r.isActive).toList();

    return A11yScreen(
      label: local.myRides,
      child: DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(local.myRides)),
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
    ),
    );
  }

  Widget _ridesList(
    List<RideModel> rides,
    AppLocalizations local, {
    required String empty,
    bool showSchedule = false,
  }) {
    if (rides.isEmpty && _error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                local.failedToLoad,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _load,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  local.retry,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }
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
                errorBuilder: (_, _, _) => Icon(
                  showSchedule
                      ? Icons.event_available_outlined
                      : Icons.history_rounded,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _showDetails(ride),
                child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            local.rideNumber(ride.id),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _fmt(ride.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                          if (ride.etaMinutes != null && ride.isActive)
                            Text(
                              local.rideEtaMinutes(ride.etaMinutes!),
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
                            rideTripStatusLabel(ride.status, local),
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
                if (showSchedule && _canCancel(ride)) ...[
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
                      label: Text(local.cancel_ride),
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
        },
      ),
    );
  }
}

class _RideDetailsSheet extends StatelessWidget {
  final RideModel ride;
  final Color statusColor;
  final String statusLabel;
  final String dateLabel;
  final bool canCancel;
  final bool canReschedule;
  final bool cancelling;
  final VoidCallback onCancel;
  final VoidCallback onReschedule;

  const _RideDetailsSheet({
    required this.ride,
    required this.statusColor,
    required this.statusLabel,
    required this.dateLabel,
    required this.canCancel,
    required this.canReschedule,
    required this.cancelling,
    required this.onCancel,
    required this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final driver = ride.driver;
    final driverName = driver == null
        ? null
        : '${driver['firstName'] ?? ''} ${driver['lastName'] ?? ''}'.trim();
    final driverRating = driver?['rating']?.toString();

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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 20),
            _row(
              Icons.radio_button_checked_rounded,
              Colors.green,
              ride.pickupAddress ??
                  '${ride.pickupLat.toStringAsFixed(4)}, ${ride.pickupLng.toStringAsFixed(4)}',
            ),
            const SizedBox(height: 10),
            _row(
              Icons.location_on_rounded,
              Colors.red,
              ride.dropoffAddress ??
                  '${ride.dropoffLat.toStringAsFixed(4)}, ${ride.dropoffLng.toStringAsFixed(4)}',
            ),
            if (driverName != null && driverName.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(driverName, style: const TextStyle(fontSize: 13)),
                  ),
                  if (driverRating != null) ...[
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(driverRating, style: const TextStyle(fontSize: 12)),
                  ],
                ],
              ),
            ],
            if (ride.paymentMethod != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 10),
                  Text(
                    ride.paymentMethod == 'sham_cash' ? l.shamCash : l.cashPayment,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ],
            if (ride.estimatedFare != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(l.estimatedPrice, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
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

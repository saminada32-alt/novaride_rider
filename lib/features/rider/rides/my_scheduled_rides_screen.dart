import 'package:flutter/material.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../models/ride_model.dart';
import '../services/rider_service.dart';

/// شاشة الرحلات المجدولة القادمة — عرض وإلغاء.
class MyScheduledRidesScreen extends StatefulWidget {
  const MyScheduledRidesScreen({super.key});

  @override
  State<MyScheduledRidesScreen> createState() => _MyScheduledRidesScreenState();
}

class _MyScheduledRidesScreenState extends State<MyScheduledRidesScreen> {
  bool _loading = true;
  List<RideModel> _rides = [];
  final Set<int> _cancelling = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final upcoming = await RiderService.instance.getScheduledRides();
      if (!mounted) return;
      setState(() {
        _rides = upcoming;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
          final ad = a.scheduledAt ?? DateTime.now();
          final bd = b.scheduledAt ?? DateTime.now();
          return ad.compareTo(bd);
        });
      });
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
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _cancel(RideModel ride) async {
    final l = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l.cancelScheduledRideTitle),
        content: Text(l.cancelScheduledRideConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.keepIt, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l.cancelRideAction, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

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
          content: Text(l.rideCancelled),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _cancelling.remove(ride.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _fmtDate(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year} · $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return A11yScreen(
      label: l.myScheduledRides,
      child: Scaffold(
      backgroundColor: const Color(0xfff6f7fb),
      appBar: AppBar(
        title: Semantics(header: true, child: Text(l.myScheduledRides)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : RefreshIndicator(
              onRefresh: _load,
              child: _rides.isEmpty ? _emptyState(l) : _list(l),
            ),
    ),
    );
  }

  Widget _emptyState(AppLocalizations l) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l.noScheduledRides,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l.noScheduledRidesHint,
              style: const TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ),
        ],
      );

  Widget _list(AppLocalizations l) => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _rides.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _rideCard(_rides[i], l),
      );

  Widget _rideCard(RideModel ride, AppLocalizations l) {
    final cancelling = _cancelling.contains(ride.id);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_rounded, color: Colors.blue.shade600, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  ride.scheduledAt != null ? _fmtDate(ride.scheduledAt!) : '—',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              if (ride.estimatedFare != null)
                Text(
                  CurrencyUtils.formatSyp(ride.estimatedFare),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: Colors.green.shade700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _locRow(Icons.radio_button_checked_rounded, Colors.green,
              ride.pickupAddress ?? l.pickup),
          const SizedBox(height: 8),
          _locRow(Icons.location_on_rounded, Colors.red,
              ride.dropoffAddress ?? l.destination),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : () => _reschedule(ride),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text(l.rescheduleRideAction),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: cancelling ? null : () => _cancel(ride),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
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
                  label: Text(l.cancelRideAction),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _locRow(IconData icon, Color color, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
}

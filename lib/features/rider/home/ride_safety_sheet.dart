import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/phone_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../account/my_account_all/provider/account_provider.dart';
import '../services/ride_safety_service.dart';

/// Emergency actions during an active ride.
Future<void> showRideSafetySheet(
  BuildContext context, {
  required int rideId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _RideSafetySheet(rideId: rideId),
  );
}

class _RideSafetySheet extends StatefulWidget {
  final int rideId;
  const _RideSafetySheet({required this.rideId});

  @override
  State<_RideSafetySheet> createState() => _RideSafetySheetState();
}

class _RideSafetySheetState extends State<_RideSafetySheet> {
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().loadEmergencyContact();
    });
  }

  Future<void> _callUri(Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sos() async {
    if (_sending) return;
    setState(() => _sending = true);
    HapticFeedback.heavyImpact();

    final pos = await RideSafetyService.instance.currentPosition();
    final ok = await RideSafetyService.instance.triggerSos(
      widget.rideId,
      lat: pos?.latitude,
      lng: pos?.longitude,
    );

    if (!mounted) return;
    setState(() => _sending = false);

    final local = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? local.sosActivated : local.complaintError),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final contact = context.watch<AccountProvider>().emergencyContact;
    final emergencyPhone = normalizePhoneForTel(contact?['phone']?.toString());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              local.safetyDuringRide,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _sending ? null : _sos,
                icon: _sending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sos_rounded),
                label: Text(local.sosButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _callUri(Uri(scheme: 'tel', path: '112')),
                icon: const Icon(Icons.local_police_outlined),
                label: Text(local.callEmergencyServices),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade800,
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ),
            if (emergencyPhone != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _callUri(Uri(scheme: 'tel', path: emergencyPhone)),
                  icon: const Icon(Icons.contact_emergency_outlined),
                  label: Text(local.callEmergencyContact),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

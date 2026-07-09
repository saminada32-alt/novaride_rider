import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import '../../models/ride_model.dart';

class ScheduledRideBar extends StatelessWidget {
  final RideModel ride;
  final String whenLabel;
  final AppLocalizations local;
  final VoidCallback onCancel;
  final VoidCallback onTap;

  const ScheduledRideBar({
    super.key,
    required this.ride,
    required this.whenLabel,
    required this.local,
    required this.onCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.schedule_rounded,
                  color: Colors.indigo.shade700,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      local.scheduledRidesTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${local.when} · $whenLabel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (ride.dropoffAddress?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        ride.dropoffAddress!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.grey.shade600,
                onPressed: onCancel,
                tooltip: local.cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

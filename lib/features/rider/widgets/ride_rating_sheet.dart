import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/a11y.dart';
import '../services/rider_service.dart';

Future<void> showRideRatingSheet(
  BuildContext context, {
  required int rideId,
  double? suggestedFare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => _RideRatingSheet(
      rideId: rideId,
      suggestedFare: suggestedFare,
    ),
  );
}

class _RideRatingSheet extends StatefulWidget {
  final int rideId;
  final double? suggestedFare;

  const _RideRatingSheet({required this.rideId, this.suggestedFare});

  @override
  State<_RideRatingSheet> createState() => _RideRatingSheetState();
}

class _RideRatingSheetState extends State<_RideRatingSheet> {
  int _rating = 5;
  bool _submitting = false;
  final _commentCtrl = TextEditingController();
  final Set<String> _tags = {};
  int _tipIndex = 0;

  static const _tipOptions = [0, 1000, 2000, 5000, 10000];

  List<String> _tagOptions(AppLocalizations l) => [
        l.ratingTagClean,
        l.ratingTagFriendly,
        l.ratingTagOnTime,
        l.ratingTagSafe,
        l.ratingTagNavigation,
        l.ratingTagProfessional,
      ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await RiderService.instance.rateRide(
        widget.rideId,
        _rating,
        comment: _commentCtrl.text.trim(),
        tags: _tags.toList(),
        tipAmount: _tipOptions[_tipIndex] > 0
            ? _tipOptions[_tipIndex].toDouble()
            : null,
      );
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.ratingSubmitted)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tags = _tagOptions(l);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            A11yHeader(
              label: l.rateYourRide,
              child: Text(
                l.rateYourRide,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 6),
            Text(l.howWasYourTrip, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Semantics(
              label: l.ratingStarsLabel,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _rating;
                  return IconButton(
                    onPressed: _submitting
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = i + 1);
                          },
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Text(l.ratingTagsTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final on = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: on,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() {
                            if (on) {
                              _tags.remove(tag);
                            } else {
                              _tags.add(tag);
                            }
                          }),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: l.ratingCommentHint,
              textField: true,
              child: TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l.ratingCommentHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(l.tipTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(_tipOptions.length, (i) {
                final amount = _tipOptions[i];
                final label = amount == 0
                    ? l.tipNone
                    : CurrencyUtils.formatSyp(amount.toDouble());
                return ChoiceChip(
                  label: Text(label),
                  selected: _tipIndex == i,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _tipIndex = i),
                );
              }),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    child: Text(l.skip),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: A11yButton(
                    label: l.submitRating,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(l.submit),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

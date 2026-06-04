import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';

/// Shows Sham Cash transfer instructions and lets the passenger submit a reference.
Future<void> showShamCashPaymentSheet(
  BuildContext context, {
  required int rideId,
  double? estimatedFare,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _ShamCashSheet(rideId: rideId, estimatedFare: estimatedFare),
  );
}

class _ShamCashSheet extends StatefulWidget {
  final int rideId;
  final double? estimatedFare;

  const _ShamCashSheet({required this.rideId, this.estimatedFare});

  @override
  State<_ShamCashSheet> createState() => _ShamCashSheetState();
}

class _ShamCashSheetState extends State<_ShamCashSheet> {
  bool _loading = true;
  bool _submitting = false;
  Map<String, dynamic>? _instructions;
  final _refCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await RiderService.instance.getPaymentInstructions(widget.rideId);
      if (!mounted) return;
      setState(() {
        _instructions = data['instructions'] as Map<String, dynamic>?;
        _loading = false;
      });
      final existing = data['paymentReference']?.toString();
      if (existing != null && existing.isNotEmpty) {
        _refCtrl.text = existing;
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final ref = _refCtrl.text.trim();
    if (ref.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await RiderService.instance.submitPaymentReference(widget.rideId, ref);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رقم المرجع')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final local = AppLocalizations.of(context)!;
    final inst = _instructions;
    final amount = (inst?['amount'] as num?)?.toDouble() ?? widget.estimatedFare;
    final phone = inst?['phone']?.toString() ?? '';
    final account = inst?['accountName']?.toString() ?? '';
    final reference = inst?['reference']?.toString() ?? 'RIDE-${widget.rideId}';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: _loading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.phone_android_rounded, color: Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        local.shamCash,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (amount != null)
                  Text(
                    CurrencyUtils.formatSyp(amount),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                const SizedBox(height: 12),
                _infoRow('الهاتف', phone, copy: phone),
                _infoRow('الحساب', account),
                _infoRow('الملاحظة', reference, copy: reference),
                const SizedBox(height: 16),
                TextField(
                  controller: _refCtrl,
                  decoration: InputDecoration(
                    labelText: 'رقم مرجع التحويل',
                    hintText: 'أدخل رقم العملية من شام كاش',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
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
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'تأكيد التحويل',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _infoRow(String label, String value, {String? copy}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (copy != null && copy.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: copy));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم النسخ')),
                );
              },
            ),
        ],
      ),
    );
  }
}

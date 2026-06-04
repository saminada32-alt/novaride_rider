import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// شارة تسعير الذروة (surge) — لون حسب مستوى الطلب + شرح للراكب.
/// تُستخدم في شاشة الطلب الفوري، الجدولة، وخريطة الطلب.
class SurgeBadge extends StatelessWidget {
  final double multiplier;

  /// أحد: normal | elevated | high | very_high
  final String? level;
  final String? zoneLabel;

  /// true عند العرض فوق خلفية داكنة (بطاقة الملخص).
  final bool dark;

  const SurgeBadge({
    super.key,
    required this.multiplier,
    this.level,
    this.zoneLabel,
    this.dark = false,
  });

  bool get _active => multiplier > 1.01;

  static Color colorFor(String? level) {
    switch (level) {
      case 'very_high':
        return const Color(0xFFef4444);
      case 'high':
        return const Color(0xFFf97316);
      case 'elevated':
        return const Color(0xFFf59e0b);
      default:
        return const Color(0xFFfbbf24);
    }
  }

  /// نص مستوى الطلب المترجم.
  static String levelText(AppLocalizations l, String? level) {
    switch (level) {
      case 'very_high':
        return l.surgeVeryHigh;
      case 'high':
        return l.surgeHigh;
      case 'elevated':
        return l.surgeElevated;
      default:
        return l.surgePricing;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_active) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final c = colorFor(level);
    final hasZone = zoneLabel != null && zoneLabel!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(dark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, color: c, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${levelText(l, level)} · ×${multiplier.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: c,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  hasZone ? l.surgeExplainZone(zoneLabel!) : l.surgeExplain,
                  style: TextStyle(
                    color: dark ? Colors.white60 : Colors.black54,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// يطلب تأكيد الراكب عندما يكون الـ surge مرتفعاً (≥ 1.2×).
  /// يرجّع true للمتابعة، false للإلغاء. عند انخفاض الـ surge يتابع تلقائياً.
  static Future<bool> confirmIfHigh(
    BuildContext context, {
    required double multiplier,
    String? level,
    String? zoneLabel,
  }) async {
    if (multiplier < 1.2) return true;
    final l = AppLocalizations.of(context)!;
    final c = colorFor(level);
    final mult = multiplier.toStringAsFixed(1);
    final hasZone = zoneLabel != null && zoneLabel.isNotEmpty;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.trending_up_rounded, color: c),
            const SizedBox(width: 8),
            Expanded(
              child: Text(l.surgePricing, style: const TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasZone
                  ? l.surgeDialogBodyZone(mult, zoneLabel)
                  : l.surgeDialogBody(mult),
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              l.surgeDialogHint,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            child: Text(
              l.continueLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

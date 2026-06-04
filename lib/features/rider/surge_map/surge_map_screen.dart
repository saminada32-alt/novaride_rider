import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../services/rider_service.dart';
import '../widgets/surge_badge.dart';

/// خريطة الطلب والأسعار للراكب — تعرض مناطق الذروة بألوان حسب مستوى الطلب.
class SurgeMapScreen extends StatefulWidget {
  const SurgeMapScreen({super.key});

  @override
  State<SurgeMapScreen> createState() => _SurgeMapScreenState();
}

class _SurgeMapScreenState extends State<SurgeMapScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _zones = [];
  String? _updatedAt;
  Map<String, dynamic>? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await RiderService.instance.getSurgeMap();
      final zones = (data['zones'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        _zones = zones.map((z) => Map<String, dynamic>.from(z as Map)).toList();
        _updatedAt = data['updatedAt']?.toString();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;

  Set<Polygon> get _polygons => _zones.map((z) {
        final level = z['surgeLevel']?.toString();
        final c = SurgeBadge.colorFor(level);
        final minLat = _d(z['minLat']);
        final maxLat = _d(z['maxLat']);
        final minLng = _d(z['minLng']);
        final maxLng = _d(z['maxLng']);
        return Polygon(
          polygonId: PolygonId(z['code']?.toString() ?? '${z.hashCode}'),
          points: [
            LatLng(minLat, minLng),
            LatLng(minLat, maxLng),
            LatLng(maxLat, maxLng),
            LatLng(maxLat, minLng),
          ],
          fillColor: c.withOpacity(0.30),
          strokeColor: c,
          strokeWidth: 2,
          consumeTapEvents: true,
          onTap: () => setState(() => _selected = z),
        );
      }).toSet();

  Set<Marker> get _markers => _zones
      .where((z) => _d(z['surgeMultiplier']) > 1.01)
      .map((z) => Marker(
            markerId: MarkerId('m_${z['code']}'),
            position: LatLng(_d(z['centerLat']), _d(z['centerLng'])),
            onTap: () => setState(() => _selected = z),
            infoWindow: InfoWindow(
              title: z['labelAr']?.toString() ?? '',
              snippet: '×${_d(z['surgeMultiplier']).toStringAsFixed(1)}',
            ),
          ))
      .toSet();

  bool get _anySurge => _zones.any((z) => _d(z['surgeMultiplier']) > 1.01);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.surgeMapTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(34.6, 37.2),
              zoom: 6.4,
            ),
            polygons: _polygons,
            markers: _markers,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (_) => setState(() => _selected = null),
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.black)),

          // Top subtitle / updated
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _infoBanner(l),
          ),

          // Selected zone detail
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 96,
              child: _zoneCard(_selected!, locale, l),
            ),

          // Legend
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: _legend(l),
          ),
        ],
      ),
    );
  }

  Widget _infoBanner(AppLocalizations l) {
    final text = !_anySurge && !_loading
        ? l.surgeNoZones
        : (_updatedAt != null
            ? l.surgeMapUpdated(_fmtTime(_updatedAt!))
            : l.surgeMapSubtitle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFf97316), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _zoneCard(Map<String, dynamic> z, String locale, AppLocalizations l) {
    final level = z['surgeLevel']?.toString();
    final c = SurgeBadge.colorFor(level);
    final mult = _d(z['surgeMultiplier']);
    final label = locale == 'ar'
        ? (z['labelAr']?.toString() ?? '')
        : (z['labelEn']?.toString() ?? '');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up_rounded, color: c),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  SurgeBadge.levelText(l, level),
                  style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            '×${mult.toStringAsFixed(1)}',
            style: TextStyle(
                color: c, fontWeight: FontWeight.w900, fontSize: 22),
          ),
        ],
      ),
    );
  }

  Widget _legend(AppLocalizations l) {
    final items = <MapEntry<String, String>>[
      MapEntry('normal', l.surgeMapNormal),
      MapEntry('elevated', l.surgeElevated),
      MapEntry('high', l.surgeHigh),
      MapEntry('very_high', l.surgeVeryHigh),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 12,
        runSpacing: 8,
        children: items
            .map((e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: SurgeBadge.colorFor(e.key),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(e.value, style: const TextStyle(fontSize: 11)),
                  ],
                ))
            .toList(),
      ),
    );
  }

  String _fmtTime(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

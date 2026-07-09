import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../core/constants/default_location.dart';
import '../../../core/constants/maps_constants.dart';
import '../../../core/widgets/a11y.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/saved_places_service.dart';

class PlaceResult {
  final String address;
  final double lat;
  final double lng;
  PlaceResult({required this.address, required this.lat, required this.lng});
}

class _Prediction {
  final String placeId, main, secondary;
  _Prediction({
    required this.placeId,
    required this.main,
    required this.secondary,
  });
}

class WhereToScreen extends StatefulWidget {
  final LatLng? pickupLocation;
  final String? title;

  const WhereToScreen({
    super.key,
    this.pickupLocation,
    this.title,
  });

  @override
  State<WhereToScreen> createState() => _WhereToScreenState();
}

class _WhereToScreenState extends State<WhereToScreen> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  List<_Prediction> _preds = [];
  List<SavedPlace> _savedPlaces = [];
  bool _busy = false;
  Timer? _timer;

  List<Map<String, dynamic>> _buildSuggestions(AppLocalizations l) {
    final user = context.read<AuthProvider>().passenger;
    final items = <Map<String, dynamic>>[];

    if (user?.homeAddress?.trim().isNotEmpty == true) {
      items.add({
        'icon': Icons.home_rounded,
        'title': l.home,
        'address': user!.homeAddress!.trim(),
      });
    }
    if (user?.workAddress?.trim().isNotEmpty == true) {
      items.add({
        'icon': Icons.work_rounded,
        'title': l.work,
        'address': user!.workAddress!.trim(),
      });
    }

    for (final p in _savedPlaces) {
      items.add({
        'icon': Icons.bookmark_rounded,
        'title': p.label,
        'address': p.address,
        'lat': p.lat,
        'lng': p.lng,
      });
    }

    return items;
  }

  @override
  void initState() {
    super.initState();
    SavedPlacesService.instance.fetchAll().then((list) {
      if (mounted) setState(() => _savedPlaces = list);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _popResult(PlaceResult result) {
    Navigator.of(context, rootNavigator: true).pop(result);
  }

  void _onChanged(String q) {
    _timer?.cancel();
    if (q.length < 2) {
      setState(() => _preds = []);
      return;
    }
    _timer = Timer(const Duration(milliseconds: 400), () => _search(q));
  }

  Future<void> _search(String q) async {
    setState(() => _busy = true);
    try {
      final anchor = widget.pickupLocation ?? AppDefaultLocation.damascus;
      final res = await http
          .get(
            Uri.parse(
              'https://maps.googleapis.com/maps/api/place/autocomplete/json'
              '?input=${Uri.encodeComponent(q)}'
              '&language=ar&location=${anchor.latitude},${anchor.longitude}'
              '&radius=100000'
              '&key=${GoogleMapsConfig.apiKey}',
            ),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);

      if (!mounted) return;
      if (data['status'] == 'OK') {
        setState(() {
          _preds = (data['predictions'] as List)
              .map(
                (p) => _Prediction(
                  placeId: p['place_id'],
                  main: p['structured_formatting']['main_text'],
                  secondary: p['structured_formatting']['secondary_text'] ?? '',
                ),
              )
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectPrediction(_Prediction p) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _preds = [];
      _busy = true;
    });

    try {
      final res = await http
          .get(
            Uri.parse(
              'https://maps.googleapis.com/maps/api/place/details/json'
              '?place_id=${p.placeId}'
              '&fields=geometry,formatted_address'
              '&key=${GoogleMapsConfig.apiKey}',
            ),
          )
          .timeout(const Duration(seconds: 8));

      final data = jsonDecode(res.body);
      if (!mounted) return;

      if (data['status'] == 'OK') {
        final loc = data['result']['geometry']['location'];
        final addr = data['result']['formatted_address'] as String;
        _popResult(
          PlaceResult(
            address: addr,
            lat: (loc['lat'] as num).toDouble(),
            lng: (loc['lng'] as num).toDouble(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Details error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectSuggestion(Map<String, dynamic> s) async {
    final lat = s['lat'] as double?;
    final lng = s['lng'] as double?;
    final address = (s['address'] as String?) ?? (s['title'] as String);

    if (lat != null && lng != null) {
      _popResult(PlaceResult(address: address, lat: lat, lng: lng));
      return;
    }

    setState(() => _busy = true);
    try {
      final res = await http
          .get(
            Uri.parse(
              'https://maps.googleapis.com/maps/api/geocode/json'
              '?address=${Uri.encodeComponent(address)}'
              '&language=ar&key=${GoogleMapsConfig.apiKey}',
            ),
          )
          .timeout(const Duration(seconds: 8));
      final data = jsonDecode(res.body);
      if (!mounted) return;
      if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        _popResult(
          PlaceResult(
            address: data['results'][0]['formatted_address'] ?? address,
            lat: (loc['lat'] as num).toDouble(),
            lng: (loc['lng'] as num).toDouble(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Geocode error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _useCurrentLocation(AppLocalizations l) {
    final pos = widget.pickupLocation ?? AppDefaultLocation.damascus;
    final code = Localizations.localeOf(context).languageCode;
    _popResult(
      PlaceResult(
        address: AppDefaultLocation.pinToDamascus
            ? AppDefaultLocation.pickupLabel(code)
            : l.currentLocation,
        lat: pos.latitude,
        lng: pos.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final suggestions = _buildSuggestions(l);

    return A11yScreen(
      label: l.whereTo,
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Semantics(header: true, child: Text(
          widget.title ?? l.whereTo,
          style: const TextStyle(fontWeight: FontWeight.bold),
        )),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      onChanged: _onChanged,
                      decoration: InputDecoration(
                        hintText: l.searchDestinationforscudule,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _preds = []);
                      },
                    ),
                ],
              ),
            ),
          ),
          if (_preds.isNotEmpty)
            Expanded(
              child: ListView.separated(
                itemCount: _preds.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) {
                  final p = _preds[i];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        color: Colors.black54,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      p.main,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      p.secondary,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => _selectPrediction(p),
                  );
                },
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.green,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      l.currentLocation,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      widget.title == l.from
                          ? l.shareLocationDesc
                          : '${l.currentLocation} — ${l.shareLocationDesc}',
                    ),
                    onTap: () => _useCurrentLocation(l),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: Text(
                      l.suggestions,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  ...suggestions.map(
                    (s) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          s['icon'] as IconData,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        s['title'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        s['address'] as String,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(s),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
    );
  }
}

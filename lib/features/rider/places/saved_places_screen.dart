import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/services/saved_places_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/widgets/a11y.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  List<SavedPlace> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _places = await SavedPlacesService.instance.fetchAll();
    } catch (_) {
      _places = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<({double lat, double lng})?> _geocode(String address) async {
    try {
      final results = await locationFromAddress(address);
      if (results.isEmpty) return null;
      return (lat: results.first.latitude, lng: results.first.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _addPlace() async {
    final l = AppLocalizations.of(context)!;
    final labelCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.addSavedPlace),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelCtrl,
                decoration: InputDecoration(labelText: l.placeLabel),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(labelText: l.placeAddress),
                textCapitalization: TextCapitalization.sentences,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.save),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    final label = labelCtrl.text.trim();
    final address = addressCtrl.text.trim();
    if (label.isEmpty || address.isEmpty) return;

    final coords = await _geocode(address);
    if (!mounted) return;
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.actionFailed)),
      );
      return;
    }

    try {
      await SavedPlacesService.instance.create(SavedPlace(
        label: label,
        address: address,
        lat: coords.lat,
        lng: coords.lng,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.actionFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return A11yScreen(
      label: l.savedPlaces,
      child: Scaffold(
        appBar: AppBar(
          title: Semantics(header: true, child: Text(l.savedPlaces)),
        ),
        floatingActionButton: A11yButton(
          label: l.addSavedPlace,
          child: FloatingActionButton(
            onPressed: _addPlace,
            child: const Icon(Icons.add),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _places.isEmpty
            ? Center(child: Text(l.noSavedPlaces))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _places.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final p = _places[i];
                  return Semantics(
                    label: '${p.label}, ${p.address}',
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      leading: const Icon(Icons.place_outlined),
                      title: Text(p.label),
                      subtitle: Text(
                        p.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: p.id == null
                            ? null
                            : () async {
                                await SavedPlacesService.instance.delete(p.id!);
                                await _load();
                              },
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

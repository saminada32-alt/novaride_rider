import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class SavedPlace {
  final int? id;
  final String label;
  final String address;
  final double lat;
  final double lng;
  final String? icon;

  const SavedPlace({
    this.id,
    required this.label,
    required this.address,
    required this.lat,
    required this.lng,
    this.icon,
  });

  factory SavedPlace.fromJson(Map<String, dynamic> j) => SavedPlace(
        id: j['id'] as int?,
        label: j['label']?.toString() ?? '',
        address: j['address']?.toString() ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        icon: j['icon']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'label': label,
        'address': address,
        'lat': lat,
        'lng': lng,
        if (icon != null) 'icon': icon,
      };
}

class SavedPlacesService {
  SavedPlacesService._();
  static final instance = SavedPlacesService._();

  static const _storage = FlutterSecureStorage();

  Future<String?> _token() => _storage.read(key: 'passenger_token');

  Future<List<SavedPlace>> fetchAll() async {
    final tok = await _token();
    if (tok == null) return [];
    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.passengerPlaces}'),
          headers: {'Authorization': 'Bearer $tok', 'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (data is! List) return [];
    return data
        .map((e) => SavedPlace.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SavedPlace> create(SavedPlace place) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.passengerPlaces}'),
          headers: {
            'Authorization': 'Bearer $tok',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(place.toJson()),
        )
        .timeout(const Duration(seconds: 12));
    final data = jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(data['message']?.toString() ?? 'Failed');
    }
    return SavedPlace.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    final tok = await _token();
    if (tok == null) throw Exception('Not authenticated');
    final res = await http.delete(
      Uri.parse('${Api.base}${Api.passengerPlace(id)}'),
      headers: {'Authorization': 'Bearer $tok'},
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to delete place');
    }
  }
}

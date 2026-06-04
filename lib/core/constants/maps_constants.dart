/// Centralized Google Maps / Places / Geocoding API key.
///
/// Override per environment with:
///   --dart-define=GOOGLE_MAPS_API_KEY=xxxx
/// (e.g. inside config/prod.json). Falls back to the bundled key for local dev.
class GoogleMapsConfig {
  GoogleMapsConfig._();

  static const String _override =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static const String _default = 'AIzaSyB1gKj8b7uFA7MeENH698IVk_2MnjxwkRY';

  static String get apiKey => _override.isNotEmpty ? _override : _default;
}

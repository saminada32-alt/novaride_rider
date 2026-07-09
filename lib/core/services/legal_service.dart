import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class LegalDocumentView {
  final String slug;
  final String version;
  final String title;
  final String summary;
  final List<LegalSectionView> sections;

  LegalDocumentView({
    required this.slug,
    required this.version,
    required this.title,
    required this.summary,
    required this.sections,
  });

  factory LegalDocumentView.fromJson(Map<String, dynamic> j) => LegalDocumentView(
        slug: j['slug']?.toString() ?? '',
        version: j['version']?.toString() ?? '1.0',
        title: j['title']?.toString() ?? '',
        summary: j['summary']?.toString() ?? '',
        sections: (j['sections'] as List<dynamic>? ?? [])
            .map((s) => LegalSectionView.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class LegalSectionView {
  final String id;
  final String title;
  final List<String> paragraphs;

  LegalSectionView({
    required this.id,
    required this.title,
    required this.paragraphs,
  });

  factory LegalSectionView.fromJson(Map<String, dynamic> j) => LegalSectionView(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        paragraphs: (j['paragraphs'] as List<dynamic>? ?? [])
            .map((p) => p.toString())
            .toList(),
      );
}

class LegalService {
  LegalService._();
  static final instance = LegalService._();

  static const _h = {'Accept': 'application/json'};

  String _lang(bool isAr) => isAr ? 'ar' : 'en';

  Future<List<LegalDocumentView>> fetchPassengerBundle({required bool isAr}) async {
    final privacy = await fetchDocument('passenger-privacy', isAr: isAr);
    final terms = await fetchDocument('passenger-terms', isAr: isAr);
    return [privacy, terms];
  }

  Future<LegalDocumentView> fetchDocument(
    String slug, {
    required bool isAr,
  }) async {
    final uri = Uri.parse(
      '${Api.base}${Api.legalDocument(slug)}?lang=${_lang(isAr)}',
    );
    final res = await http.get(uri, headers: _h).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Failed to load legal document');
    }
    return LegalDocumentView.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  List<Map<String, String>> passengerConsents() => const [
        {'slug': 'passenger-privacy', 'version': '1.0'},
        {'slug': 'passenger-terms', 'version': '1.0'},
      ];

  Future<Map<String, dynamic>> acceptConsents() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'passenger_token');
    if (token == null) throw Exception('Not logged in');

    final res = await http
        .post(
          Uri.parse('${Api.base}${Api.legalConsent}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'consents': passengerConsents()}),
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to record consent');
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> consentStatus() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'passenger_token');
    if (token == null) throw Exception('Not logged in');

    final res = await http
        .get(
          Uri.parse('${Api.base}${Api.legalConsentStatus}'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) throw Exception('Failed to load consent status');
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }
}

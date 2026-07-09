import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';

class ContentFaqItem {
  final int id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final int sortOrder;

  ContentFaqItem({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.sortOrder,
  });

  factory ContentFaqItem.fromJson(Map<String, dynamic> j) => ContentFaqItem(
        id: j['id'] as int? ?? 0,
        questionAr: j['questionAr']?.toString() ?? '',
        questionEn: j['questionEn']?.toString() ?? '',
        answerAr: j['answerAr']?.toString() ?? '',
        answerEn: j['answerEn']?.toString() ?? '',
        sortOrder: j['sortOrder'] as int? ?? 0,
      );

  String question(bool isAr) => isAr ? questionAr : questionEn;
  String answer(bool isAr) => isAr ? answerAr : answerEn;
}

class ContentBanner {
  final int id;
  final String titleAr;
  final String titleEn;
  final String? imageUrl;
  final String? linkUrl;

  ContentBanner({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.imageUrl,
    this.linkUrl,
  });

  factory ContentBanner.fromJson(Map<String, dynamic> j) => ContentBanner(
        id: j['id'] as int? ?? 0,
        titleAr: j['titleAr']?.toString() ?? '',
        titleEn: j['titleEn']?.toString() ?? '',
        imageUrl: j['imageUrl']?.toString(),
        linkUrl: j['linkUrl']?.toString(),
      );

  String title(bool isAr) => isAr ? titleAr : titleEn;
}

class ContentService {
  ContentService._();
  static final instance = ContentService._();

  Future<List<ContentFaqItem>> fetchFaq({String audience = 'passenger'}) async {
    final uri = Uri.parse('${Api.base}${Api.contentFaq}?audience=$audience');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final list = body is List ? body : (body['items'] as List? ?? []);
    return list
        .map((e) => ContentFaqItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<List<ContentBanner>> fetchBanners({String audience = 'passenger'}) async {
    final uri =
        Uri.parse('${Api.base}${Api.contentBanners}?audience=$audience');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return [];
    final body = jsonDecode(utf8.decode(res.bodyBytes));
    final list = body is List ? body : (body['items'] as List? ?? []);
    return list
        .map((e) => ContentBanner.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

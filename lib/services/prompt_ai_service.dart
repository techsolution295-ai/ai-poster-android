import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_keys.dart';

/// Parsed result for "prompt -> template generation".
class PromptDraft {
  final String categoryId;
  final String title;
  final String subtitle;
  final String details;
  final String price;
  final List<String> keywords;

  const PromptDraft({
    required this.categoryId,
    required this.title,
    required this.subtitle,
    required this.details,
    required this.price,
    required this.keywords,
  });
}

/// Optional AI-assisted prompt parser.
///
/// - If [ApiKeys.huggingFace] is configured, tries a free HuggingFace endpoint
///   (can be slow, cold starts are expected).
/// - If unavailable/fails, falls back to a deterministic local parser.
class PromptAiService {
  PromptAiService._();
  static final PromptAiService instance = PromptAiService._();

  Future<PromptDraft> parse(String prompt) async {
    final clean = prompt.trim();
    if (clean.isEmpty) {
      return _localParse('sale offer poster');
    }
    if (ApiKeys.hasHuggingFace) {
      try {
        final ai = await _huggingFaceParse(clean);
        if (ai != null) return ai;
      } catch (e) {
        debugPrint('PromptAiService AI parse failed: $e');
      }
    }
    return _localParse(clean);
  }

  Future<PromptDraft?> _huggingFaceParse(String prompt) async {
    final instruction = '''
Extract poster data as strict JSON only:
{
  "category_id": "one of: umrah,business,college,travel,sale,announcements,social",
  "title": "short catchy title",
  "subtitle": "short subtitle",
  "details": "one line details",
  "price": "offer tag or empty",
  "keywords": ["5 concise image search keywords"]
}
User prompt: "$prompt"
''';
    final uri =
        Uri.parse('https://api-inference.huggingface.co/models/google/flan-t5-base');
    final res = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${ApiKeys.huggingFace}',
            'Content-Type': 'application/json',
          },
          body: json.encode({'inputs': instruction}),
        )
        .timeout(const Duration(seconds: 18));

    if (res.statusCode != 200) return null;
    final raw = res.body;
    final maybeText = _extractFirstText(raw);
    if (maybeText == null) return null;
    final jsonText = _extractJsonObject(maybeText);
    if (jsonText == null) return null;
    final m = json.decode(jsonText) as Map<String, dynamic>;
    final categoryId = _normalizeCategory(m['category_id']?.toString() ?? '');
    final title = (m['title']?.toString() ?? '').trim();
    final subtitle = (m['subtitle']?.toString() ?? '').trim();
    final details = (m['details']?.toString() ?? '').trim();
    final price = (m['price']?.toString() ?? '').trim();
    final keywords = (m['keywords'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    if (title.isEmpty) return null;
    return PromptDraft(
      categoryId: categoryId,
      title: title,
      subtitle: subtitle,
      details: details,
      price: price,
      keywords: keywords.isEmpty ? _defaultKeywords(categoryId) : keywords,
    );
  }

  PromptDraft _localParse(String prompt) {
    final p = prompt.toLowerCase();
    final category = _guessCategory(p);
    final lines = prompt
        .split(RegExp(r'[\n\|,;]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final title = lines.isNotEmpty ? lines.first : _defaultTitle(category);
    final subtitle = lines.length > 1 ? lines[1] : 'Professional design for your campaign';
    final details = lines.length > 2 ? lines[2] : 'Contact now for details';
    final price = _extractPriceTag(prompt);
    return PromptDraft(
      categoryId: category,
      title: _cap(title, 42),
      subtitle: _cap(subtitle, 56),
      details: _cap(details, 80),
      price: price,
      keywords: _keywordsFromPrompt(prompt, category),
    );
  }

  String _guessCategory(String p) {
    if (p.contains('umrah') || p.contains('makkah') || p.contains('madinah')) {
      return 'umrah';
    }
    if (p.contains('college') || p.contains('admission') || p.contains('student')) {
      return 'college';
    }
    if (p.contains('travel') || p.contains('trip') || p.contains('tour')) {
      return 'travel';
    }
    if (p.contains('sale') || p.contains('offer') || p.contains('discount')) {
      return 'sale';
    }
    if (p.contains('announce') || p.contains('notice') || p.contains('event')) {
      return 'announcements';
    }
    if (p.contains('social') || p.contains('instagram') || p.contains('youtube')) {
      return 'social';
    }
    if (p.contains('business') || p.contains('service') || p.contains('company')) {
      return 'business';
    }
    return 'business';
  }

  List<String> _keywordsFromPrompt(String prompt, String category) {
    final words = prompt
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 3)
        .toList();
    final picks = <String>[];
    for (final w in words) {
      if (!picks.contains(w)) picks.add(w);
      if (picks.length == 4) break;
    }
    return picks.isEmpty ? _defaultKeywords(category) : picks;
  }

  List<String> _defaultKeywords(String category) {
    switch (category) {
      case 'umrah':
        return const ['kaaba', 'makkah mosque', 'islamic pattern', 'airport travel'];
      case 'college':
        return const ['students classroom', 'graduation', 'study desk', 'medical college'];
      case 'travel':
        return const ['mountain road', 'adventure travel', 'waterfall', 'forest road'];
      case 'sale':
        return const ['discount sale', 'offer background', 'shopping bags', 'sale background'];
      case 'announcements':
        return const ['modern notice board', 'event announcement', 'blue gradient', 'clean abstract background'];
      case 'social':
        return const ['social media background', 'creative workspace', 'digital marketing', 'content creator'];
      default:
        return const ['business office', 'professional background', 'abstract gradient', 'customer service'];
    }
  }

  String _extractPriceTag(String s) {
    final pct = RegExp(r'(\d{1,2}\s?%[\s\-]?(off|discount)?)', caseSensitive: false)
        .firstMatch(s);
    if (pct != null) return pct.group(1)!.toUpperCase();
    final money = RegExp(r'(\$|rs\.?|pkr)\s?\d+', caseSensitive: false).firstMatch(s);
    if (money != null) return money.group(0)!.toUpperCase();
    return '';
  }

  String _defaultTitle(String category) {
    switch (category) {
      case 'umrah':
        return 'Umrah Package';
      case 'college':
        return 'Admissions Open';
      case 'travel':
        return 'Travel Adventure';
      case 'sale':
        return 'Mega Sale';
      case 'announcements':
        return 'Important Notice';
      case 'social':
        return 'New Post';
      default:
        return 'Business Flyer';
    }
  }

  String _cap(String text, int max) =>
      text.length <= max ? text : '${text.substring(0, max - 1)}…';

  String _normalizeCategory(String raw) {
    const valid = {
      'umrah',
      'business',
      'college',
      'travel',
      'sale',
      'announcements',
      'social',
    };
    return valid.contains(raw) ? raw : _guessCategory(raw);
  }

  String? _extractFirstText(String raw) {
    try {
      final decoded = json.decode(raw);
      if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
        return decoded.first['generated_text']?.toString();
      }
      if (decoded is Map && decoded['generated_text'] != null) {
        return decoded['generated_text'].toString();
      }
    } catch (_) {}
    return null;
  }

  String? _extractJsonObject(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return null;
  }
}


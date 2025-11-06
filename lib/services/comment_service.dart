import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
// No external AI keys required for the non-AI translation/summarization fallbacks.

/// Lightweight prototype CommentService that provides local (mock) implementations
/// of sentiment analysis, summarization and translation. This is intended as a
/// fast prototype so the UI can be wired. Replace with real server calls later.
class CommentService {
  CommentService();

  // Very small sentiment lexicon for a quick heuristic
  static final _positive = <String>{'good','great','love','amazing','nice','awesome','fun','happy','enjoy','wonderful','excellent'};
  static final _negative = <String>{'bad','hate','awful','terrible','sad','angry','disappoint','worst','sucks','annoy'};

  Future<Map<String, dynamic>> analyzeSentiment(String text) async {
    // quick heuristic: count positive and negative tokens
    final t = text.toLowerCase();
    int pos = 0, neg = 0;
    for (final w in _positive) if (t.contains(w)) pos++;
    for (final w in _negative) if (t.contains(w)) neg++;

    double score;
    String label;
    if (pos == 0 && neg == 0) {
      // neutral baseline based on punctuation/emoji
      score = 0.5;
      label = 'neutral';
    } else if (pos >= neg) {
      score = (0.5 + (pos - neg) * 0.1).clamp(0.0, 1.0);
      label = 'positive';
    } else {
      score = (0.5 - (neg - pos) * 0.1).clamp(0.0, 1.0);
      label = 'negative';
    }

    // small artificial delay to mimic network/processing
    await Future.delayed(const Duration(milliseconds: 200));
    return {'label': label, 'score': double.parse(score.toStringAsFixed(2))};
  }

  Future<String> summarizeText(String text, {int maxLength = 140}) async {
    // Non-AI summarizer: extract the first 1-2 sentences and truncate to
    // maxLength so summaries are short and do not require external APIs.
    final sentences = text.split(RegExp(r'(?<=[\.\!\?])\s+'));
    String pick;
    if (sentences.isEmpty) {
      pick = text.trim();
    } else if (sentences.length == 1) {
      pick = sentences.first.trim();
    } else {
      // take first two sentences if they fit
      pick = (sentences.sublist(0, sentences.length >= 2 ? 2 : 1).join(' ')).trim();
    }

    if (pick.length > maxLength) pick = pick.substring(0, maxLength).trim() + '...';
    await Future.delayed(const Duration(milliseconds: 150));
    return pick;
  }

  Future<String> translateText(String text, String targetLang) async {
    // Non-AI translation path: use LibreTranslate public instance only.
    // This ensures translation works without calling OpenAI or Hugging Face.
    try {
      final lt = await _translateWithLibreTranslate(text, targetLang);
      if (lt.trim().isNotEmpty) return lt.trim();
    } catch (e) {
      print('🌐 LibreTranslate failed: $e');
    }

    // final fallback: return a safe prefixed prototype so UI remains usable
    await Future.delayed(const Duration(milliseconds: 200));
    return '[$targetLang] ' + text;
  }

  // Try a simple Hugging Face model fallback for translation if OpenAI quota is exceeded.
  // NOTE: Hugging Face translation helper removed — translation now uses
  // LibreTranslate / MyMemory fallbacks only (no AI services) to match the
  // "non-AI" requirement.

  // Fallback translator using a public LibreTranslate instance. This is a
  // lightweight, no-key translation API useful as a fallback when HF/OpenAI
  // are unavailable. Note: public instances may be rate-limited.
  Future<String> _translateWithLibreTranslate(String text, String targetLang) async {
    // Try a small list of public LibreTranslate-compatible instances. Some
    // instances may redirect (301) or be unavailable; try the next one if an
    // instance fails.
    final endpoints = [
      'https://translate.argosopentech.com/translate',
      'https://libretranslate.de/translate',
      'https://libretranslate.com/translate',
    ];

    Exception? lastError;
    for (final ep in endpoints) {
      final uri = Uri.parse(ep);
      try {
        final resp = await http.post(uri, headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }, body: jsonEncode({
          'q': text,
          'source': 'auto',
          'target': targetLang,
          'format': 'text'
        }));

        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          if (body is Map && body['translatedText'] != null) return (body['translatedText'] as String).trim();
          if (body is Map && body['translated_text'] != null) return (body['translated_text'] as String).trim();
          // Some instances return slightly different keys; best-effort return
          if (body is String) return body.trim();
          return resp.body.toString().trim();
        }

        lastError = Exception('LibreTranslate instance $ep failed (status ${resp.statusCode})');
        // try next endpoint
      } catch (e) {
        lastError = Exception('LibreTranslate instance $ep error: $e');
        // try next endpoint
      }
    }
    // If all LibreTranslate endpoints failed, try MyMemory as an extra fallback.
    try {
      final mm = await _translateWithMyMemory(text, targetLang);
      if (mm.trim().isNotEmpty) return mm.trim();
    } catch (e) {
      // ignore and throw aggregated error below
      lastError = Exception('MyMemory fallback failed: $e');
    }

    throw Exception('LibreTranslate: all endpoints failed. Last error: $lastError');
  }

  // As an additional non-AI fallback, try MyMemory Translated API (public
  // endpoint) which often returns reasonable translations for many language
  // pairs. This is a best-effort fallback when LibreTranslate endpoints fail.
  Future<String> _translateWithMyMemory(String text, String targetLang) async {
    try {
      // Try with English as source first, then with 'auto' if that fails.
      final attempts = ['en', 'auto'];
      for (final src in attempts) {
        final uri = Uri.parse(
            'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(text)}&langpair=$src|$targetLang');
        final resp = await http.get(uri, headers: {'Accept': 'application/json'});
        if (resp.statusCode == 200) {
          final body = jsonDecode(resp.body);
          if (body is Map) {
            final data = body['responseData'];
            if (data != null && data['translatedText'] != null) {
              return (data['translatedText'] as String).trim();
            }
          }
        }
      }
      throw Exception('MyMemory did not return a translatedText');
    } catch (e) {
      throw Exception('MyMemory error: $e');
    }
  }
}

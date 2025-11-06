import 'dart:convert';
import 'package:http/http.dart' as http;

/// Hugging Face API integration for advanced content moderation
/// Uses AI models for toxicity detection, sentiment analysis, and more
class HuggingFaceModeration {
  static final HuggingFaceModeration _instance = HuggingFaceModeration._internal();
  factory HuggingFaceModeration() => _instance;
  HuggingFaceModeration._internal();

  // Get your API key from: https://huggingface.co/settings/tokens
  // For production, store this securely (environment variables, secure storage)
  static const String _apiKey = 'YOUR_HUGGING_FACE_API_KEY_HERE';
  
  // Free models you can use:
  // 1. unitary/toxic-bert (toxicity detection)
  // 2. cardiffnlp/twitter-roberta-base-offensive (offensive language)
  // 3. cardiffnlp/twitter-xlm-roberta-base-sentiment (multilingual sentiment)
  static const String _toxicityModel = 'unitary/toxic-bert';
  static const String _offensiveModel = 'cardiffnlp/twitter-roberta-base-offensive';
  
  final String _baseUrl = 'https://api-inference.huggingface.co/models';

  /// Check if text is toxic using AI model
  Future<ModerationResult> checkToxicity(String text) async {
    if (text.isEmpty) {
      return ModerationResult(
        isToxic: false,
        score: 0.0,
        label: 'clean',
        reason: 'Empty text',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_toxicityModel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body);
        return _parseToxicityResponse(results);
      } else if (response.statusCode == 503) {
        // Model is loading, wait and retry
        await Future.delayed(const Duration(seconds: 2));
        return checkToxicity(text);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to local filter if API fails
      return ModerationResult(
        isToxic: false,
        score: 0.0,
        label: 'error',
        reason: 'API unavailable: $e',
      );
    }
  }

  /// Check if text is offensive
  Future<ModerationResult> checkOffensive(String text) async {
    if (text.isEmpty) {
      return ModerationResult(
        isToxic: false,
        score: 0.0,
        label: 'not-offensive',
        reason: 'Empty text',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_offensiveModel'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'inputs': text}),
      );

      if (response.statusCode == 200) {
        final results = jsonDecode(response.body);
        return _parseOffensiveResponse(results);
      } else if (response.statusCode == 503) {
        await Future.delayed(const Duration(seconds: 2));
        return checkOffensive(text);
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      return ModerationResult(
        isToxic: false,
        score: 0.0,
        label: 'error',
        reason: 'API unavailable: $e',
      );
    }
  }

  /// Complete moderation check (combines multiple models)
  Future<CompleteModerationResult> moderateText(String text) async {
    final toxicityResult = await checkToxicity(text);
    final offensiveResult = await checkOffensive(text);

    final isClean = !toxicityResult.isToxic && !offensiveResult.isToxic;
    final maxScore = [toxicityResult.score, offensiveResult.score].reduce((a, b) => a > b ? a : b);

    return CompleteModerationResult(
      isClean: isClean,
      toxicityResult: toxicityResult,
      offensiveResult: offensiveResult,
      overallScore: maxScore,
      severity: _calculateSeverity(maxScore),
    );
  }

  /// Validate text and return error message if inappropriate
  Future<String?> validateText(String text, {String fieldName = 'Ce champ'}) async {
    final result = await moderateText(text);
    
    if (!result.isClean) {
      if (result.toxicityResult.isToxic) {
        return '$fieldName contient un contenu toxique (score: ${(result.toxicityResult.score * 100).toStringAsFixed(0)}%)';
      }
      if (result.offensiveResult.isToxic) {
        return '$fieldName contient un langage offensant (score: ${(result.offensiveResult.score * 100).toStringAsFixed(0)}%)';
      }
    }
    
    return null;
  }

  ModerationResult _parseToxicityResponse(dynamic response) {
    try {
      if (response is List && response.isNotEmpty) {
        final firstResult = response[0];
        if (firstResult is List && firstResult.isNotEmpty) {
          // Find the toxic label
          final toxicItem = firstResult.firstWhere(
            (item) => item['label'].toString().toLowerCase().contains('toxic'),
            orElse: () => firstResult[0],
          );
          
          final score = toxicItem['score'] as double;
          final label = toxicItem['label'] as String;
          final isToxic = score > 0.5; // Threshold: 50%
          
          return ModerationResult(
            isToxic: isToxic,
            score: score,
            label: label,
            reason: isToxic ? 'Contenu toxique détecté par IA' : 'Contenu propre',
          );
        }
      }
    } catch (e) {
      // Error parsing
    }
    
    return ModerationResult(
      isToxic: false,
      score: 0.0,
      label: 'unknown',
      reason: 'Unable to parse response',
    );
  }

  ModerationResult _parseOffensiveResponse(dynamic response) {
    try {
      if (response is List && response.isNotEmpty) {
        final firstResult = response[0];
        if (firstResult is List && firstResult.isNotEmpty) {
          // Find offensive label
          final offensiveItem = firstResult.firstWhere(
            (item) => item['label'].toString().toLowerCase().contains('offensive'),
            orElse: () => firstResult[0],
          );
          
          final score = offensiveItem['score'] as double;
          final label = offensiveItem['label'] as String;
          final isOffensive = label.toLowerCase().contains('offensive') && score > 0.5;
          
          return ModerationResult(
            isToxic: isOffensive,
            score: score,
            label: label,
            reason: isOffensive ? 'Langage offensant détecté par IA' : 'Contenu acceptable',
          );
        }
      }
    } catch (e) {
      // Error parsing
    }
    
    return ModerationResult(
      isToxic: false,
      score: 0.0,
      label: 'not-offensive',
      reason: 'Unable to parse response',
    );
  }

  String _calculateSeverity(double score) {
    if (score < 0.3) return 'clean';
    if (score < 0.5) return 'mild';
    if (score < 0.7) return 'moderate';
    if (score < 0.9) return 'severe';
    return 'extreme';
  }

  /// Check if API key is configured
  bool isConfigured() {
    return _apiKey != 'YOUR_HUGGING_FACE_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}

/// Result from a single moderation check
class ModerationResult {
  final bool isToxic;
  final double score; // 0.0 to 1.0
  final String label;
  final String reason;

  ModerationResult({
    required this.isToxic,
    required this.score,
    required this.label,
    required this.reason,
  });

  @override
  String toString() {
    return 'ModerationResult(isToxic: $isToxic, score: ${(score * 100).toStringAsFixed(1)}%, label: $label)';
  }
}

/// Complete moderation result combining multiple checks
class CompleteModerationResult {
  final bool isClean;
  final ModerationResult toxicityResult;
  final ModerationResult offensiveResult;
  final double overallScore;
  final String severity; // clean, mild, moderate, severe, extreme

  CompleteModerationResult({
    required this.isClean,
    required this.toxicityResult,
    required this.offensiveResult,
    required this.overallScore,
    required this.severity,
  });

  @override
  String toString() {
    return 'CompleteModerationResult(isClean: $isClean, severity: $severity, score: ${(overallScore * 100).toStringAsFixed(1)}%)';
  }
}

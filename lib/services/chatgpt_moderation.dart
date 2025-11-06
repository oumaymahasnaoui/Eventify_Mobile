import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

/// OpenAI ChatGPT integration for advanced content moderation
/// Uses GPT-4 or GPT-3.5-turbo for intelligent content analysis
class ChatGPTModeration {
  static final ChatGPTModeration _instance = ChatGPTModeration._internal();
  factory ChatGPTModeration() => _instance;
  ChatGPTModeration._internal();

  // Get your API key from: https://platform.openai.com/api-keys
  // For production, store this securely (environment variables, secure storage)
  static const String _apiKey = 'YOUR_OPENAI_API_KEY_HERE';
  
  // Models available:
  // - gpt-4o-mini: Fastest, cheapest, good quality ($0.15/1M input tokens)
  // - gpt-3.5-turbo: Fast and affordable ($0.50/1M input tokens)
  // - gpt-4o: Most powerful ($5/1M input tokens)
  static const String _model = 'gpt-4o-mini';
  
  final String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  final String _moderationUrl = 'https://api.openai.com/v1/moderations';

  /// Check if API key is configured
  bool isConfigured() {
    return _apiKey != 'YOUR_OPENAI_API_KEY_HERE' && _apiKey.isNotEmpty;
  }

  /// Use OpenAI's dedicated Moderation API (FREE and very fast)
  /// This is the recommended approach for content moderation
  Future<ModerationResult> moderateContent(String text) async {
    if (text.isEmpty) {
      return ModerationResult(
        isFlagged: false,
        categories: {},
        categoryScores: {},
        reason: 'Empty text',
      );
    }

    if (!isConfigured()) {
      throw Exception('OpenAI API key not configured');
    }

    try {
      developer.log('🤖 Calling OpenAI Moderation API...');
      
      final response = await http.post(
        Uri.parse(_moderationUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'input': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data['results'][0];
        
        developer.log('✅ OpenAI Moderation response received');
        
        return ModerationResult(
          isFlagged: result['flagged'] ?? false,
          categories: Map<String, bool>.from(result['categories'] ?? {}),
          categoryScores: Map<String, double>.from(
            (result['category_scores'] as Map).map(
              (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
            ),
          ),
          reason: _buildReasonFromCategories(result['categories']),
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      } else if (response.statusCode == 429) {
        developer.log('⚠️ Rate limit hit - too many requests. Wait a moment and try again.');
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 403) {
        developer.log('⚠️ API key not authorized - check billing at platform.openai.com');
        throw Exception('API key not authorized. Check your OpenAI account at platform.openai.com/usage');
      } else {
        throw Exception('OpenAI API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('❌ OpenAI Moderation error: $e');
      rethrow;
    }
  }

  /// Use ChatGPT for more nuanced content analysis with custom rules
  /// This is more expensive but allows custom instructions
  Future<ChatGPTAnalysis> analyzeContentWithGPT(
    String text, {
    String? customInstructions,
  }) async {
    if (text.isEmpty) {
      return ChatGPTAnalysis(
        isAppropriate: true,
        reason: 'Empty text',
        suggestions: [],
        confidence: 1.0,
      );
    }

    if (!isConfigured()) {
      throw Exception('OpenAI API key not configured');
    }

    final systemPrompt = customInstructions ?? '''
You are a content moderator for a community app. Analyze the following text and determine if it's appropriate.

Check for:
- Profanity or vulgar language (French and English)
- Hate speech or discrimination
- Threats or violence
- Sexual content
- Spam or misleading information
- Personal attacks or harassment

Respond in JSON format:
{
  "is_appropriate": true/false,
  "reason": "brief explanation",
  "categories": ["category1", "category2"],
  "severity": "low/medium/high",
  "confidence": 0.0-1.0,
  "suggestions": ["suggestion1", "suggestion2"]
}
''';

    try {
      developer.log('🤖 Calling ChatGPT API for analysis...');
      
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.3, // Lower temperature for more consistent results
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        
        developer.log('✅ ChatGPT response received');
        
        // Parse JSON response from GPT
        final analysis = jsonDecode(content);
        
        return ChatGPTAnalysis(
          isAppropriate: analysis['is_appropriate'] ?? true,
          reason: analysis['reason'] ?? 'No issues detected',
          categories: List<String>.from(analysis['categories'] ?? []),
          severity: analysis['severity'] ?? 'low',
          confidence: (analysis['confidence'] ?? 0.0).toDouble(),
          suggestions: List<String>.from(analysis['suggestions'] ?? []),
        );
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      } else {
        throw Exception('ChatGPT API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('❌ ChatGPT analysis error: $e');
      rethrow;
    }
  }

  /// Quick validation - returns error message if inappropriate, null if ok
  Future<String?> validateText(String text, {String fieldName = 'Ce champ'}) async {
    try {
      final result = await moderateContent(text);
      
      if (result.isFlagged) {
        return '$fieldName contient du contenu inapproprié: ${result.reason}';
      }
      
      return null; // Valid
    } catch (e) {
      developer.log('⚠️ Validation error, allowing content: $e');
      return null; // If API fails, don't block the user
    }
  }

  /// Build human-readable reason from flagged categories
  String _buildReasonFromCategories(Map categories) {
    final flagged = <String>[];
    
    if (categories['hate'] == true) flagged.add('discours haineux');
    if (categories['hate/threatening'] == true) flagged.add('menaces haineuses');
    if (categories['harassment'] == true) flagged.add('harcèlement');
    if (categories['harassment/threatening'] == true) flagged.add('menaces');
    if (categories['self-harm'] == true) flagged.add('automutilation');
    if (categories['self-harm/intent'] == true) flagged.add('intention d\'automutilation');
    if (categories['self-harm/instructions'] == true) flagged.add('instructions d\'automutilation');
    if (categories['sexual'] == true) flagged.add('contenu sexuel');
    if (categories['sexual/minors'] == true) flagged.add('contenu sexuel impliquant des mineurs');
    if (categories['violence'] == true) flagged.add('violence');
    if (categories['violence/graphic'] == true) flagged.add('violence graphique');
    
    if (flagged.isEmpty) {
      return 'Contenu inapproprié détecté';
    }
    
    return flagged.join(', ');
  }
}

/// Result from OpenAI Moderation API
class ModerationResult {
  final bool isFlagged;
  final Map<String, bool> categories;
  final Map<String, double> categoryScores;
  final String reason;

  ModerationResult({
    required this.isFlagged,
    required this.categories,
    required this.categoryScores,
    required this.reason,
  });

  /// Get severity level based on scores
  String getSeverity() {
    if (!isFlagged) return 'clean';
    
    final maxScore = categoryScores.values.reduce((a, b) => a > b ? a : b);
    
    if (maxScore > 0.9) return 'extreme';
    if (maxScore > 0.7) return 'severe';
    if (maxScore > 0.5) return 'moderate';
    return 'mild';
  }

  /// Get the most problematic category
  String? getMostProblematicCategory() {
    if (!isFlagged) return null;
    
    String? worst;
    double maxScore = 0.0;
    
    categoryScores.forEach((category, score) {
      if (score > maxScore) {
        maxScore = score;
        worst = category;
      }
    });
    
    return worst;
  }

  @override
  String toString() {
    return 'ModerationResult(flagged: $isFlagged, severity: ${getSeverity()}, reason: $reason)';
  }
}

/// Result from ChatGPT content analysis
class ChatGPTAnalysis {
  final bool isAppropriate;
  final String reason;
  final List<String> categories;
  final String severity;
  final double confidence;
  final List<String> suggestions;

  ChatGPTAnalysis({
    required this.isAppropriate,
    required this.reason,
    this.categories = const [],
    this.severity = 'low',
    required this.confidence,
    this.suggestions = const [],
  });

  @override
  String toString() {
    return 'ChatGPTAnalysis(appropriate: $isAppropriate, severity: $severity, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}

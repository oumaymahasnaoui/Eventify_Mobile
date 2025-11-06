import 'profanity_filter.dart';
import 'huggingface_moderation.dart';
import 'chatgpt_moderation.dart';

/// Hybrid content moderation combining local profanity filter and AI services
/// Supports: Local filter, Hugging Face, ChatGPT/OpenAI
class ContentModerationService {
  static final ContentModerationService _instance = ContentModerationService._internal();
  factory ContentModerationService() => _instance;
  ContentModerationService._internal();

  final ProfanityFilter _localFilter = ProfanityFilter();
  final HuggingFaceModeration _aiModeration = HuggingFaceModeration();
  final ChatGPTModeration _chatGPT = ChatGPTModeration();

  /// Strategy for moderation
  ModerationStrategy strategy = ModerationStrategy.hybrid;

  /// Validate text using selected strategy
  Future<ValidationResult> validateText(
    String text, {
    String fieldName = 'Ce champ',
  }) async {
    switch (strategy) {
      case ModerationStrategy.localOnly:
        return _validateLocal(text, fieldName);
      
      case ModerationStrategy.aiOnly:
        return await _validateAI(text, fieldName);
      
      case ModerationStrategy.chatgpt:
        return await _validateChatGPT(text, fieldName);
      
      case ModerationStrategy.hybrid:
        return await _validateHybrid(text, fieldName);
    }
  }

  /// Local profanity filter only (fast, offline)
  ValidationResult _validateLocal(String text, String fieldName) {
    final error = _localFilter.validateText(text, fieldName: fieldName);
    
    if (error != null) {
      final badWords = _localFilter.findProfanity(text);
      return ValidationResult(
        isValid: false,
        errorMessage: error,
        method: 'local',
        confidence: 1.0,
        details: 'Mots détectés: ${badWords.join(", ")}',
      );
    }

    return ValidationResult(
      isValid: true,
      errorMessage: null,
      method: 'local',
      confidence: 0.8, // Local filter has ~80% confidence
      details: 'Aucun mot inapproprié trouvé localement',
    );
  }

  /// AI moderation only (slower, requires internet, more accurate)
  Future<ValidationResult> _validateAI(String text, String fieldName) async {
    // Check if API is configured
    if (!_aiModeration.isConfigured()) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'API Hugging Face non configurée',
        method: 'ai',
        confidence: 0.0,
        details: 'Veuillez configurer votre clé API',
      );
    }

    try {
      final result = await _aiModeration.moderateText(text);
      
      if (!result.isClean) {
        String reason = '';
        if (result.toxicityResult.isToxic) {
          reason = 'Contenu toxique (${(result.toxicityResult.score * 100).toStringAsFixed(0)}%)';
        } else if (result.offensiveResult.isToxic) {
          reason = 'Langage offensant (${(result.offensiveResult.score * 100).toStringAsFixed(0)}%)';
        }
        
        return ValidationResult(
          isValid: false,
          errorMessage: '$fieldName contient du contenu inapproprié détecté par IA',
          method: 'ai',
          confidence: result.overallScore,
          details: reason,
        );
      }

      return ValidationResult(
        isValid: true,
        errorMessage: null,
        method: 'ai',
        confidence: 1.0 - result.overallScore,
        details: 'Contenu validé par IA (${result.severity})',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Erreur lors de la vérification IA: $e',
        method: 'ai',
        confidence: 0.0,
        details: 'API non disponible',
      );
    }
  }

  /// ChatGPT/OpenAI moderation (most accurate, fast, FREE for moderation)
  Future<ValidationResult> _validateChatGPT(String text, String fieldName) async {
    // Check if API is configured
    if (!_chatGPT.isConfigured()) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'API ChatGPT/OpenAI non configurée',
        method: 'chatgpt',
        confidence: 0.0,
        details: 'Veuillez configurer votre clé API OpenAI',
      );
    }

    try {
      final result = await _chatGPT.moderateContent(text);
      
      if (result.isFlagged) {
        return ValidationResult(
          isValid: false,
          errorMessage: '$fieldName contient du contenu inapproprié',
          method: 'chatgpt',
          confidence: 1.0,
          details: result.reason,
        );
      }

      return ValidationResult(
        isValid: true,
        errorMessage: null,
        method: 'chatgpt',
        confidence: 1.0,
        details: 'Contenu validé par ChatGPT (${result.getSeverity()})',
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Erreur lors de la vérification ChatGPT: $e',
        method: 'chatgpt',
        confidence: 0.0,
        details: 'API non disponible',
      );
    }
  }

  /// Hybrid approach: Fast local check first, then AI for edge cases
  /// Prioritizes ChatGPT if available (faster and free), falls back to Hugging Face
  Future<ValidationResult> _validateHybrid(String text, String fieldName) async {
    // Step 1: Quick local check (catches obvious bad words)
    final localResult = _validateLocal(text, fieldName);
    
    if (!localResult.isValid) {
      // Found obvious profanity - no need for AI check
      return localResult;
    }

    // Step 2: Try ChatGPT first (faster and free for moderation API)
    if (_chatGPT.isConfigured()) {
      try {
        final chatGPTResult = await _validateChatGPT(text, fieldName);
        
        // Combine results
        return ValidationResult(
          isValid: chatGPTResult.isValid,
          errorMessage: chatGPTResult.errorMessage,
          method: 'hybrid-chatgpt',
          confidence: (localResult.confidence + chatGPTResult.confidence) / 2,
          details: 'Local: ✓, ChatGPT: ${chatGPTResult.isValid ? "✓" : "✗"} - ${chatGPTResult.details}',
        );
      } catch (e) {
        // ChatGPT failed, try Hugging Face as backup
      }
    }

    // Step 3: Fall back to Hugging Face AI
    if (_aiModeration.isConfigured()) {
      try {
        final aiResult = await _validateAI(text, fieldName);
        
        // Combine results
        return ValidationResult(
          isValid: aiResult.isValid,
          errorMessage: aiResult.errorMessage,
          method: 'hybrid-huggingface',
          confidence: (localResult.confidence + aiResult.confidence) / 2,
          details: 'Local: ✓, AI: ${aiResult.isValid ? "✓" : "✗"} - ${aiResult.details}',
        );
      } catch (e) {
        // AI failed, but local passed - accept with lower confidence
        return ValidationResult(
          isValid: true,
          errorMessage: null,
          method: 'hybrid',
          confidence: 0.7,
          details: 'Local: ✓, AI: non disponible',
        );
      }
    } else {
      // No AI configured, use local result only
      return localResult;
    }
  }

  /// Validate multiple fields at once
  Future<Map<String, ValidationResult>> validateMultipleFields(
    Map<String, String> fields,
  ) async {
    final results = <String, ValidationResult>{};
    
    for (final entry in fields.entries) {
      results[entry.key] = await validateText(
        entry.value,
        fieldName: entry.key,
      );
    }
    
    return results;
  }

  /// Get quick validation status (true if valid)
  Future<bool> isTextValid(String text) async {
    final result = await validateText(text);
    return result.isValid;
  }

  /// Get error message or null if valid
  Future<String?> getValidationError(String text, {String fieldName = 'Ce champ'}) async {
    final result = await validateText(text, fieldName: fieldName);
    return result.errorMessage;
  }

  /// Change moderation strategy
  void setStrategy(ModerationStrategy newStrategy) {
    strategy = newStrategy;
  }

  /// Check if Hugging Face AI is available
  bool isAIAvailable() {
    return _aiModeration.isConfigured();
  }

  /// Check if ChatGPT is available
  bool isChatGPTAvailable() {
    return _chatGPT.isConfigured();
  }

  /// Check if any AI service is available
  bool isAnyAIAvailable() {
    return _aiModeration.isConfigured() || _chatGPT.isConfigured();
  }

  /// Get status of all moderation services
  Map<String, bool> getServiceStatus() {
    return {
      'local': true, // Always available
      'huggingface': _aiModeration.isConfigured(),
      'chatgpt': _chatGPT.isConfigured(),
    };
  }
}

/// Moderation strategy options
enum ModerationStrategy {
  /// Fast local profanity filter only (offline, instant)
  localOnly,
  
  /// AI moderation only (requires API key, slower, more accurate)
  aiOnly,
  
  /// ChatGPT/OpenAI moderation (fast, accurate, FREE for moderation API)
  chatgpt,
  
  /// Hybrid: Local first, then AI (best balance)
  hybrid,
}

/// Validation result with detailed information
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String method; // 'local', 'ai', or 'hybrid'
  final double confidence; // 0.0 to 1.0
  final String details;

  ValidationResult({
    required this.isValid,
    required this.errorMessage,
    required this.method,
    required this.confidence,
    required this.details,
  });

  @override
  String toString() {
    return 'ValidationResult(isValid: $isValid, method: $method, confidence: ${(confidence * 100).toStringAsFixed(0)}%)';
  }
}

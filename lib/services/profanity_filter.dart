/// Profanity filter service for content moderation
/// Checks text for inappropriate words in French and English
class ProfanityFilter {
  static final ProfanityFilter _instance = ProfanityFilter._internal();
  factory ProfanityFilter() => _instance;
  ProfanityFilter._internal();

  // List of bad words (French and English)
  // Note: This is a basic list. In production, use a more comprehensive list
  // or integrate with a moderation API
  static final List<String> _badWords = [
    // French bad words
    'merde',
    'putain',
    'con',
    'connard',
    'salaud',
    'salopard',
    'salope',
    'enculé',
    'enculer',
    'bordel',
    'chier',
    'emmerde',
    'foutre',
    'bite',
    'couille',
    'pute',
    'cul',
    
    // English bad words
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'bastard',
    'damn',
    'hell',
    'crap',
    'dick',
    'piss',
    
    // Add more as needed
  ];

  /// Check if text contains profanity
  /// Returns true if profanity found, false otherwise
  bool containsProfanity(String text) {
    if (text.isEmpty) return false;
    
    final cleanText = _normalizeText(text);
    
    for (final badWord in _badWords) {
      // Check for exact word match (with word boundaries)
      final regex = RegExp(r'\b' + RegExp.escape(badWord) + r'\b', 
                           caseSensitive: false);
      if (regex.hasMatch(cleanText)) {
        return true;
      }
    }
    
    return false;
  }

  /// Find all profane words in the text
  /// Returns list of found bad words
  List<String> findProfanity(String text) {
    if (text.isEmpty) return [];
    
    final cleanText = _normalizeText(text);
    final foundWords = <String>[];
    
    for (final badWord in _badWords) {
      final regex = RegExp(r'\b' + RegExp.escape(badWord) + r'\b', 
                           caseSensitive: false);
      if (regex.hasMatch(cleanText)) {
        foundWords.add(badWord);
      }
    }
    
    return foundWords;
  }

  /// Censor profane words by replacing with asterisks
  /// Example: "merde" -> "m***e"
  String censorText(String text) {
    if (text.isEmpty) return text;
    
    String censored = text;
    
    for (final badWord in _badWords) {
      final regex = RegExp(r'\b' + RegExp.escape(badWord) + r'\b', 
                           caseSensitive: false);
      
      censored = censored.replaceAllMapped(regex, (match) {
        final word = match.group(0)!;
        if (word.length <= 2) {
          return '*' * word.length;
        }
        // Keep first and last letter, replace middle with asterisks
        return word[0] + ('*' * (word.length - 2)) + word[word.length - 1];
      });
    }
    
    return censored;
  }

  /// Validate text and return error message if profanity found
  /// Returns null if text is clean
  String? validateText(String text, {String fieldName = 'Ce champ'}) {
    if (containsProfanity(text)) {
      final badWords = findProfanity(text);
      if (badWords.length == 1) {
        return '$fieldName contient un langage inapproprié: "${badWords.first}"';
      } else {
        return '$fieldName contient un langage inapproprié';
      }
    }
    return null;
  }

  /// Normalize text for comparison (remove accents, special chars)
  String _normalizeText(String text) {
    // Convert to lowercase
    String normalized = text.toLowerCase();
    
    // Remove common accent characters
    final accents = {
      'à': 'a', 'â': 'a', 'ä': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i',
      'ô': 'o', 'ö': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u',
      'ç': 'c',
    };
    
    accents.forEach((accent, replacement) {
      normalized = normalized.replaceAll(accent, replacement);
    });
    
    return normalized;
  }

  /// Check if text is clean (no profanity)
  bool isClean(String text) {
    return !containsProfanity(text);
  }

  /// Get severity level of profanity (0-3)
  /// 0 = clean, 1 = mild, 2 = moderate, 3 = severe
  int getProfanitySeverity(String text) {
    final badWords = findProfanity(text);
    
    if (badWords.isEmpty) return 0;
    if (badWords.length == 1) return 1;
    if (badWords.length <= 3) return 2;
    return 3;
  }

  /// Check multiple fields at once
  /// Returns map of field names to error messages
  Map<String, String> validateMultipleFields(Map<String, String> fields) {
    final errors = <String, String>{};
    
    fields.forEach((fieldName, text) {
      final error = validateText(text, fieldName: fieldName);
      if (error != null) {
        errors[fieldName] = error;
      }
    });
    
    return errors;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for interacting with OpenAI ChatGPT API
/// 
/// SETUP INSTRUCTIONS:
/// 1. Get your API key from: https://platform.openai.com/api-keys
/// 2. Click "Create new secret key"
/// 3. Copy the key and replace 'YOUR_OPENAI_API_KEY_HERE' below
/// 4. Keep the key private - don't commit it to Git!
/// 
/// FEATURES:
/// ✨ Generate professional admin responses
/// 📝 Create summaries of complaints
/// 🌐 Translate text between languages
/// 💭 Analyze sentiment of complaints
class ChatGPTService {
  // TODO: Replace with your actual API key from https://platform.openai.com/api-keys
  static const String _apiKey = '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';
  static const String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo'; // or 'gpt-4' for better quality

  /// Generate a professional admin response to a complaint
  Future<String> generateAdminResponse({
    required String title,
    required String description,
  }) async {
    final prompt = '''
Tu es un assistant administratif professionnel. Génère une réponse empathique et professionnelle à cette réclamation:

Titre: $title
Description: $description

La réponse doit:
- Reconnaître le problème
- Présenter des excuses si approprié
- Proposer une solution ou des prochaines étapes
- Être en français
- Faire 3-4 phrases
- Être polie et professionnelle
''';

    return await _callChatGPT(prompt);
  }

  /// Generate a concise summary of a complaint
  Future<String> generateSummary({
    required String title,
    required String description,
  }) async {
    final prompt = '''
Résume cette réclamation en 2-3 phrases courtes et claires:

Titre: $title
Description: $description

Le résumé doit capturer l'essentiel du problème.
''';

    return await _callChatGPT(prompt);
  }

  /// Translate text between languages
  Future<String> translateText({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    final prompt = '''
Traduis le texte suivant de $fromLanguage vers $toLanguage:

$text

Fournis uniquement la traduction, sans explications.
''';

    return await _callChatGPT(prompt);
  }

  /// Analyze sentiment of a complaint
  Future<String> analyzeSentiment({
    required String title,
    required String description,
  }) async {
    final prompt = '''
Analyse le sentiment de cette réclamation et classe-le en une seule catégorie:
- "Neutre" : ton calme et factuel
- "Urgent" : nécessite une action rapide
- "En colère" : ton frustré ou agressif
- "Positif" : ton constructif malgré le problème

Titre: $title
Description: $description

Réponds avec uniquement: Neutre, Urgent, En colère, ou Positif
''';

    return await _callChatGPT(prompt);
  }

  /// Main method to call ChatGPT API with automatic retry on rate limit
  Future<String> _callChatGPT(String prompt, {int retryCount = 0}) async {
    try {
      // Check if API key is configured
      if (_apiKey == 'YOUR_OPENAI_API_KEY_HERE' || _apiKey.isEmpty) {
        return '❌ API Key not configured. Please add your OpenAI API key in lib/services/chatgpt_service.dart';
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': 'Tu es un assistant professionnel pour gérer les réclamations clients.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return content.trim();
      } else if (response.statusCode == 401) {
        return '❌ Erreur d\'authentification. Vérifiez votre clé API OpenAI.';
      } else if (response.statusCode == 429) {
        // Rate limit hit - try to parse retry-after header
        final retryAfter = response.headers['retry-after'];
        final waitSeconds = retryAfter != null ? int.tryParse(retryAfter) ?? 20 : 20;
        
        // Auto-retry once after waiting
        if (retryCount < 1) {
          print('⏳ Rate limit hit. Waiting $waitSeconds seconds before retry...');
          await Future.delayed(Duration(seconds: waitSeconds));
          return await _callChatGPT(prompt, retryCount: retryCount + 1);
        }
        
        return '⚠️ Limite de requêtes atteinte.\n\n💡 Solutions:\n• Attendez 30 secondes\n• Ajoutez \$5 à votre compte OpenAI pour augmenter la limite\n• Compte gratuit: 3 req/min\n• Compte payant: 60 req/min';
      } else {
        print('ChatGPT API Error: ${response.statusCode} - ${response.body}');
        return '❌ Erreur lors de l\'appel à l\'API ChatGPT (${response.statusCode})';
      }
    } catch (e) {
      print('ChatGPT Service Error: $e');
      return '❌ Erreur de connexion: $e';
    }
  }

  /// Test if API is properly configured and working
  Future<bool> testConnection() async {
    try {
      final response = await _callChatGPT('Dis simplement "OK"');
      return !response.startsWith('❌') && !response.startsWith('⚠️');
    } catch (e) {
      return false;
    }
  }
}

import 'package:flutter/material.dart';
import 'services/huggingface_moderation.dart';
import 'services/content_moderation_service.dart';

void main() {
  runApp(const SimpleAITestApp());
}

class SimpleAITestApp extends StatelessWidget {
  const SimpleAITestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple AI Test',
      home: const SimpleAITestScreen(),
    );
  }
}

class SimpleAITestScreen extends StatefulWidget {
  const SimpleAITestScreen({super.key});

  @override
  State<SimpleAITestScreen> createState() => _SimpleAITestScreenState();
}

class _SimpleAITestScreenState extends State<SimpleAITestScreen> {
  final HuggingFaceModeration _aiService = HuggingFaceModeration();
  final ContentModerationService _hybridService = ContentModerationService();
  String _result = 'Click a button to test moderation';
  bool _isLoading = false;

  Future<void> _testAIDirectly() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing AI directly...';
    });

    try {
      print('🔍 Testing Hugging Face API directly...');
      
      // Test 1: Clean text
      print('Test 1: Clean text');
      final cleanResult = await _aiService.checkToxicity('Hello, how are you?');
      print('✅ Clean result: isToxic=${cleanResult.isToxic}, score=${cleanResult.score}');
      
      // Test 2: Toxic text
      print('Test 2: Toxic text');
      final toxicResult = await _aiService.checkToxicity('You are stupid and worthless');
      print('✅ Toxic result: isToxic=${toxicResult.isToxic}, score=${toxicResult.score}');
      
      setState(() {
        _result = '''
✅ AI Test Success!

Test 1 (Clean text):
• Toxic: ${cleanResult.isToxic}
• Score: ${(cleanResult.score * 100).toStringAsFixed(1)}%
• Label: ${cleanResult.label}

Test 2 (Toxic text):
• Toxic: ${toxicResult.isToxic}
• Score: ${(toxicResult.score * 100).toStringAsFixed(1)}%
• Label: ${toxicResult.label}

API Key: ${_aiService.isConfigured() ? "✅ Configured" : "❌ Not configured"}
''';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testHybridService() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing hybrid service...';
    });

    try {
      print('🔍 Testing Hybrid Moderation Service...');
      
      // Test with profanity
      print('Test 1: French profanity');
      final profanityResult = await _hybridService.validateText('C\'est de la merde');
      print('Result: valid=${profanityResult.isValid}, method=${profanityResult.method}');
      
      // Test with toxic content
      print('Test 2: Toxic content');
      final toxicResult = await _hybridService.validateText('You are stupid');
      print('Result: valid=${toxicResult.isValid}, method=${toxicResult.method}');
      
      // Test clean content
      print('Test 3: Clean content');
      final cleanResult = await _hybridService.validateText('Hello world');
      print('Result: valid=${cleanResult.isValid}, method=${cleanResult.method}');
      
      setState(() {
        _result = '''
✅ Hybrid Service Tests!

Test 1 (Profanity):
• Valid: ${profanityResult.isValid ? "✅" : "❌"}
• Method: ${profanityResult.method}
• Confidence: ${(profanityResult.confidence * 100).toStringAsFixed(0)}%
${profanityResult.errorMessage ?? ""}

Test 2 (Toxic):
• Valid: ${toxicResult.isValid ? "✅" : "❌"}
• Method: ${toxicResult.method}
• Confidence: ${(toxicResult.confidence * 100).toStringAsFixed(0)}%
${toxicResult.errorMessage ?? ""}

Test 3 (Clean):
• Valid: ${cleanResult.isValid ? "✅" : "❌"}
• Method: ${cleanResult.method}
• Confidence: ${(cleanResult.confidence * 100).toStringAsFixed(0)}%
''';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _result = '❌ Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple AI Test'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '🤖 AI Moderation Test',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAIDirectly,
              icon: const Icon(Icons.psychology),
              label: const Text('Test AI Directly'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testHybridService,
              icon: const Icon(Icons.merge_type),
              label: const Text('Test Hybrid Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            
            const SizedBox(height: 30),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              )
            else
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _result,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            
            const SizedBox(height: 12),
            
            Text(
              'Check the console (terminal) for detailed logs',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

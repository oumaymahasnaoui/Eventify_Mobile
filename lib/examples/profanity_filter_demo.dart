import 'package:flutter/material.dart';
import '../services/profanity_filter.dart';

/// Demo screen to test the profanity filter
class ProfanityFilterDemo extends StatefulWidget {
  const ProfanityFilterDemo({super.key});

  @override
  State<ProfanityFilterDemo> createState() => _ProfanityFilterDemoState();
}

class _ProfanityFilterDemoState extends State<ProfanityFilterDemo> {
  final TextEditingController _testController = TextEditingController();
  final ProfanityFilter _filter = ProfanityFilter();
  
  String _result = '';
  Color _resultColor = Colors.black;

  void _checkText() {
    final text = _testController.text;
    
    if (text.isEmpty) {
      setState(() {
        _result = 'Entrez du texte pour tester';
        _resultColor = Colors.grey;
      });
      return;
    }

    final containsProfanity = _filter.containsProfanity(text);
    final badWords = _filter.findProfanity(text);
    final censored = _filter.censorText(text);
    final severity = _filter.getProfanitySeverity(text);

    String resultText = '';
    Color color = Colors.green;

    if (containsProfanity) {
      color = Colors.red;
      resultText = '❌ Contient des mots inappropriés!\n\n';
      resultText += 'Mots trouvés: ${badWords.join(", ")}\n';
      resultText += 'Sévérité: $severity/3\n\n';
      resultText += 'Texte censuré:\n"$censored"';
    } else {
      color = Colors.green;
      resultText = '✅ Texte propre - Aucun mot inapproprié détecté';
    }

    setState(() {
      _result = resultText;
      _resultColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test - Contrôle des Mots'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'À propos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Ce filtre détecte et bloque les mots inappropriés en français et en anglais. '
                      'Il est intégré dans le formulaire de réclamation.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test input
            TextField(
              controller: _testController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Texte à tester',
                hintText: 'Entrez du texte pour vérifier...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.text_fields),
              ),
            ),
            const SizedBox(height: 16),

            // Check button
            ElevatedButton.icon(
              onPressed: _checkText,
              icon: const Icon(Icons.check_circle),
              label: const Text('Vérifier le texte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCE1126),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Result
            if (_result.isNotEmpty)
              Card(
                color: _resultColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: 14,
                      color: _resultColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Example tests
            const Text(
              'Exemples à tester:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildExampleCard(
              '✅ Texte propre',
              'Ma réclamation concerne le service client qui ne répond pas',
              Colors.green,
            ),
            _buildExampleCard(
              '❌ Avec mot interdit (français)',
              'Ce service est vraiment merde',
              Colors.red,
            ),
            _buildExampleCard(
              '❌ Avec mot interdit (anglais)',
              'This is fucking terrible',
              Colors.red,
            ),
            _buildExampleCard(
              '❌ Plusieurs mots interdits',
              'Putain ce connard ne répond jamais',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleCard(String title, String text, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
          color == Colors.green ? Icons.check_circle : Icons.warning,
          color: color,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        subtitle: Text(text),
        onTap: () {
          _testController.text = text;
          _checkText();
        },
      ),
    );
  }

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }
}

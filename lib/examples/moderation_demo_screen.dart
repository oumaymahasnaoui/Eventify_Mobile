import 'package:flutter/material.dart';
import '../services/content_moderation_service.dart';

/// Demo screen to test the hybrid content moderation system
class ModerationDemoScreen extends StatefulWidget {
  const ModerationDemoScreen({super.key});

  @override
  State<ModerationDemoScreen> createState() => _ModerationDemoScreenState();
}

class _ModerationDemoScreenState extends State<ModerationDemoScreen> {
  final TextEditingController _textController = TextEditingController();
  final ContentModerationService _moderationService = ContentModerationService();
  
  ValidationResult? _lastResult;
  bool _isValidating = false;
  ModerationStrategy _currentStrategy = ModerationStrategy.hybrid;

  // Test cases
  final Map<String, List<String>> _testCases = {
    '✅ Clean Content': [
      'Problème de connexion WiFi',
      'Le réseau ne fonctionne pas dans la salle 101',
      'Besoin d\'aide pour réparer l\'ascenseur',
      'La lumière est cassée au 3ème étage',
    ],
    '❌ Local Filter (Instant)': [
      'C\'est de la merde',
      'Quel connard',
      'Va te faire foutre',
      'Putain de bordel',
    ],
    '❌ AI Detection (Subtle)': [
      'I hate all people from that country',
      'You are so stupid and worthless',
      'Go kill yourself',
      'This is totally garbage and useless',
    ],
    '⚠️ Borderline Cases': [
      'This is really bad service',
      'I am very angry about this',
      'What a terrible experience',
      'Je suis vraiment énervé',
    ],
  };

  @override
  void initState() {
    super.initState();
    _moderationService.setStrategy(_currentStrategy);
  }

  Future<void> _validateText() async {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer du texte')),
      );
      return;
    }

    setState(() {
      _isValidating = true;
      _lastResult = null;
    });

    try {
      final result = await _moderationService.validateText(
        _textController.text,
        fieldName: 'Test',
      );

      setState(() {
        _lastResult = result;
        _isValidating = false;
      });
    } catch (e) {
      setState(() {
        _isValidating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _changeStrategy(ModerationStrategy? strategy) {
    if (strategy != null) {
      setState(() {
        _currentStrategy = strategy;
        _moderationService.setStrategy(strategy);
        _lastResult = null;
      });
    }
  }

  void _useTestCase(String text) {
    setState(() {
      _textController.text = text;
      _lastResult = null;
    });
  }

  Color _getResultColor(ValidationResult result) {
    if (!result.isValid) return Colors.red;
    if (result.confidence > 0.8) return Colors.green;
    if (result.confidence > 0.6) return Colors.orange;
    return Colors.amber;
  }

  IconData _getResultIcon(ValidationResult result) {
    if (!result.isValid) return Icons.cancel;
    if (result.confidence > 0.8) return Icons.check_circle;
    if (result.confidence > 0.6) return Icons.warning;
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Modération AI'),
        backgroundColor: const Color(0xFFCE1126),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strategy Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Stratégie de Modération',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RadioListTile<ModerationStrategy>(
                      title: const Text('Hybride (Local + AI)'),
                      subtitle: const Text('Rapide et précis (Recommandé)'),
                      value: ModerationStrategy.hybrid,
                      groupValue: _currentStrategy,
                      onChanged: _changeStrategy,
                    ),
                    RadioListTile<ModerationStrategy>(
                      title: const Text('Local uniquement'),
                      subtitle: const Text('Hors ligne, instantané'),
                      value: ModerationStrategy.localOnly,
                      groupValue: _currentStrategy,
                      onChanged: _changeStrategy,
                    ),
                    RadioListTile<ModerationStrategy>(
                      title: const Text('IA uniquement'),
                      subtitle: Text(
                        _moderationService.isAIAvailable()
                            ? 'Plus précis, nécessite internet'
                            : 'API non configurée',
                      ),
                      value: ModerationStrategy.aiOnly,
                      groupValue: _currentStrategy,
                      onChanged: _moderationService.isAIAvailable()
                          ? _changeStrategy
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Text Input
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '✍️ Texte à Valider',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _textController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Entrez du texte pour tester la modération...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isValidating ? null : _validateText,
                        icon: _isValidating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(_isValidating ? 'Validation...' : 'Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCE1126),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            if (_lastResult != null)
              Card(
                color: _getResultColor(_lastResult!).withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getResultIcon(_lastResult!),
                            color: _getResultColor(_lastResult!),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _lastResult!.isValid ? 'Validé ✅' : 'Bloqué ❌',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _getResultColor(_lastResult!),
                                  ),
                                ),
                                Text(
                                  'Méthode: ${_lastResult!.method}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildResultRow(
                        'Confiance',
                        '${(_lastResult!.confidence * 100).toStringAsFixed(0)}%',
                        Icons.assessment,
                      ),
                      if (_lastResult!.errorMessage != null)
                        _buildResultRow(
                          'Erreur',
                          _lastResult!.errorMessage!,
                          Icons.error,
                        ),
                      _buildResultRow(
                        'Détails',
                        _lastResult!.details,
                        Icons.info,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Test Cases
            const Text(
              '🧪 Cas de Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._testCases.entries.map((category) => Card(
              child: ExpansionTile(
                title: Text(
                  category.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                children: category.value
                    .map((testCase) => ListTile(
                          title: Text(testCase),
                          trailing: const Icon(Icons.arrow_forward),
                          onTap: () => _useTestCase(testCase),
                        ))
                    .toList(),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

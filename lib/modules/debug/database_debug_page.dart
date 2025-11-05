import 'package:flutter/material.dart';
import '../../../database/database_helper.dart';

class DatabaseDebugPage extends StatefulWidget {
  const DatabaseDebugPage({Key? key}) : super(key: key);

  @override
  State<DatabaseDebugPage> createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  final _dbHelper = DatabaseHelper();
  bool _isLoading = false;
  String _message = '';

  Future<void> _resetDatabase() async {
    setState(() {
      _isLoading = true;
      _message = 'Réinitialisation en cours...';
    });

    try {
      await _dbHelper.resetDatabase();
      setState(() {
        _message = '✅ Base de données réinitialisée avec succès !';
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Base de données réinitialisée !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _message = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _showDatabaseInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final path = await _dbHelper.getDatabasePath();
      await _dbHelper.debugTableSchema();
      
      setState(() {
        _message = '📍 Chemin: $path\n\nVoir les logs pour le schéma';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = '❌ Erreur: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Base de données'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Outils de débogage',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Utilisez ces outils pour gérer la base de données',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Bouton réinitialiser
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('⚠️ Confirmation'),
                    content: const Text(
                      'Cette action va supprimer toutes les données et recréer la base de données.\n\nContinuer ?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _resetDatabase();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser la base de données'),
            ),

            const SizedBox(height: 16),

            // Bouton info
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _showDatabaseInfo,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Color(0xFFCE1126)),
              ),
              icon: const Icon(Icons.info_outline, color: Color(0xFFCE1126)),
              label: const Text(
                'Afficher les informations',
                style: TextStyle(color: Color(0xFFCE1126)),
              ),
            ),

            const SizedBox(height: 32),

            // Zone de message
            if (_message.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Résultat:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_message),
                  ],
                ),
              ),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),

            const Spacer(),

            // Info importante
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Important',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Si vous rencontrez l\'erreur "table reservations has no column named event_id", vous devez réinitialiser la base de données.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

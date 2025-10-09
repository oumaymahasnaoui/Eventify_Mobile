import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _exportPath = '';
  bool _isExporting = false;

  Future<void> _exportDatabase() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final path = await _dbHelper.exportDatabaseToFile();
      setState(() {
        _exportPath = path;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _exportPath = 'Erreur: $e';
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📤 Exporter Base de Données'),
        backgroundColor: const Color(0xFFCE1126),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export SQLite pour DB Browser',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Cette fonction copie la base de données SQLite vers un emplacement accessible pour DB Browser.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _isExporting ? null : _exportDatabase,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCE1126),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: _isExporting
                  ? const CircularProgressIndicator()
                  : const Text('Exporter la Base de Données'),
            ),

            const SizedBox(height: 20),

            if (_exportPath.isNotEmpty) ...[
              const Text(
                'Chemin d\'export:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _exportPath,
                    style: const TextStyle(fontFamily: 'Courier'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '📋 Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              const Text('1. Ouvrez DB Browser for SQLite'),
              const Text('2. Cliquez sur "Ouvrir une base de données"'),
              const Text('3. Naviguez vers le chemin ci-dessus'),
              const Text('4. Sélectionnez "eventify_export.db"'),
            ],
          ],
        ),
      ),
    );
  }
}
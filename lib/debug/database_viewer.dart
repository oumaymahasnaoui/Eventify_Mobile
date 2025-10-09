import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/user.dart';

class DatabaseViewer extends StatefulWidget {
  const DatabaseViewer({super.key});

  @override
  State<DatabaseViewer> createState() => _DatabaseViewerState();
}

class _DatabaseViewerState extends State<DatabaseViewer> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<User> _users = [];
  bool _isLoading = true;
  String _dbPath = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Récupérer le chemin de la base de données
      final path = await getDatabasesPath();
      setState(() {
        _dbPath = '$path/eventify.db';
      });

      // Charger les utilisateurs
      final users = await _dbHelper.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTestUser() async {
    final testUser = User(
      name: 'Test User ${DateTime.now().millisecond}',
      email: 'test${DateTime.now().millisecond}@eventify.com',
      phone: '+216 00 000 000',
      password: 'test123',
      joinDate: DateTime.now(),
    );

    await _dbHelper.insertUser(testUser);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 Database Viewer'),
        backgroundColor: const Color(0xFFCE1126),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations de la base de données
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📁 Informations Base de Données',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Chemin: $_dbPath'),
                    Text('Nombre d\'utilisateurs: ${_users.length}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Liste des utilisateurs
            const Text(
              '👥 Utilisateurs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            if (_users.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Aucun utilisateur trouvé'),
                ),
              )
            else
              ..._users.map((user) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFCE1126),
                    child: Text(
                      user.name[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email: ${user.email}'),
                      Text('Téléphone: ${user.phone}'),
                      Text('ID: ${user.id}'),
                      Text('Inscrit le: ${_formatDate(user.joinDate)}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (user.id != null) {
                        _dbHelper.deleteUser(user.id!);
                        _loadData();
                      }
                    },
                  ),
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: _loadData,
            backgroundColor: Colors.blue,
            mini: true,
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _addTestUser,
            backgroundColor: const Color(0xFFCE1126),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
}
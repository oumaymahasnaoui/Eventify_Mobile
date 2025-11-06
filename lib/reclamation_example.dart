import 'package:flutter/material.dart';
import 'modules/reclamation/reclamation_screen.dart';
import 'modules/reclamation/reclamations_list_screen.dart';

/// Example: How to use the Reclamation feature
/// 
/// This example demonstrates:
/// 1. Creating a new reclamation (ReclamationScreen)
/// 2. Viewing all reclamations (ReclamationsListScreen)
/// 
/// Navigation examples:
/// 
/// ```dart
/// // To create a new reclamation:
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ReclamationScreen()),
/// );
/// 
/// // To view all reclamations:
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ReclamationsListScreen()),
/// );
/// ```

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify - Réclamations',
      theme: ThemeData(
        primaryColor: const Color(0xFFCE1126),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFCE1126),
        ),
        useMaterial3: true,
      ),
      home: const ReclamationHomePage(),
    );
  }
}

class ReclamationHomePage extends StatelessWidget {
  const ReclamationHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réclamations - Demo'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.report_problem_outlined,
                size: 80,
                color: Color(0xFFCE1126),
              ),
              const SizedBox(height: 24),
              const Text(
                'Gestion des Réclamations',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Testez les fonctionnalités de réclamation',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Button to create new reclamation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReclamationScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle Réclamation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE1126),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Button to view all reclamations
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ReclamationsListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Voir mes Réclamations'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCE1126),
                    side: const BorderSide(color: Color(0xFFCE1126)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

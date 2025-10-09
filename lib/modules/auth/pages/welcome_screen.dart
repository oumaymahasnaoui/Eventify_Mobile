import 'package:eventify/modules/auth/pages/login_page.dart';
import 'package:eventify/modules/auth/pages/signup_page.dart';
import 'package:flutter/material.dart';
// import 'signup_page.dart'; // Décommentez une fois la page d'inscription créée
import '../../../debug/database_viewer.dart';

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const HeaderSection(),
              const SizedBox(height: 50),
              const ButtonSection(),
              const Spacer(),
              const FooterSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.celebration_outlined,
          size: 80,
          color: Color(0xFFCE1126),
        ),
        const SizedBox(height: 16),
        const Text(
          'Eventify',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'by CodeCrafters',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFlagContainer('🇹🇳'),
            const SizedBox(width: 16),
            _buildFlagContainer('🇵🇸'),
          ],
        ),
      ],
    );
  }

  Widget _buildFlagContainer(String emoji) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}

class ButtonSection extends StatelessWidget {
  const ButtonSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCE1126),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Login',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SignUpPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFCE1126),
              side: const BorderSide(color: Color(0xFFCE1126)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  // Dans FooterSection, remplacez par :
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 16),
        const Text(
          'Vivre la Palestine • Vive la Tunisie',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),

        // BOUTON BIEN VISIBLE
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DatabaseViewer()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.storage),
            label: const Text('Voir Base de Données SQLite'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _createTestUser(BuildContext context) {
    // Cette fonction peut appeler directement la base de données
    // pour tester l'insertion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Base de Données'),
        content: const Text('Allez dans "Voir DB" pour vérifier les données.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
// lib/modules/auth/pages/test_verification_page.dart
import 'package:flutter/material.dart';
import '../../../services/auth_service_verification.dart';
import 'login_page.dart';

class TestVerificationPage extends StatefulWidget {
  final String verificationToken;
  final String email;

  const TestVerificationPage({
    super.key,
    required this.verificationToken,
    required this.email,
  });

  @override
  State<TestVerificationPage> createState() => _TestVerificationPageState();
}

class _TestVerificationPageState extends State<TestVerificationPage> {
  final AuthServiceWithVerification _authService = AuthServiceWithVerification();
  bool _isVerifying = false;
  bool _isVerified = false;
  String _message = '';

  void _verifyAccount() async {
    setState(() {
      _isVerifying = true;
      _message = 'Vérification en cours...';
    });

    try {
      final user = await _authService.verifyEmailAndCreateAccount(widget.verificationToken);

      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _message = '✅ Compte vérifié avec succès !\n\nBienvenue ${user?.name} !';
      });

      // Rediriger après 3 secondes
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _message = '❌ Erreur: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Démarrer la vérification automatiquement
    _verifyAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de Vérification'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône dynamique
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: _isVerified
                    ? Colors.green.withOpacity(0.1)
                    : const Color(0xFFCE1126).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isVerified ? Icons.verified : Icons.pending,
                size: 50,
                color: _isVerified ? Colors.green : const Color(0xFFCE1126),
              ),
            ),
            const SizedBox(height: 30),

            Text(
              _isVerified ? 'Compte Activé !' : 'Test de Vérification',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Informations du token
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Informations de test :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Email: ${widget.email}'),
                    const SizedBox(height: 5),
                    Text(
                      'Token: ${widget.verificationToken}',
                      style: const TextStyle(
                        fontFamily: 'Monospace',
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isVerifying)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Création de votre compte...'),
                ],
              ),

            Text(
              _message,
              style: TextStyle(
                fontSize: 16,
                color: _isVerified ? Colors.green : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            if (!_isVerifying && !_isVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCE1126),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Réessayer la vérification'),
                ),
              ),

            if (_isVerified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Se connecter maintenant'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
// lib/modules/auth/pages/verification_pending_page.dart
import 'package:flutter/material.dart';
import '../../../services/auth_service_verification.dart';
import 'login_page.dart';

class VerificationPendingPage extends StatelessWidget {
  final String email;
  final String verificationToken;
  final Function onResendEmail;

  const VerificationPendingPage({
    super.key,
    required this.email,
    required this.verificationToken,
    required this.onResendEmail,
  });

  void _testVerification(BuildContext context) async {
    final authService = AuthServiceWithVerification();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Test de Vérification'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Vérification en cours...'),
            const SizedBox(height: 8),
            Text(
              'Token: ${verificationToken.substring(0, 15)}...',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );

    try {
      final user = await authService.verifyEmailAndCreateAccount(verificationToken);

      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('✅ Succès !'),
          content: Text('Compte vérifié avec succès !\n\nBienvenue ${user?.name} !'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Se connecter'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer le dialog de chargement

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('❌ Erreur'),
          content: Text('Erreur lors de la vérification: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification Email'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône d'email
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFCE1126).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_outlined,
                size: 60,
                color: Color(0xFFCE1126),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'Vérifiez votre email',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Text(
              'Nous avons envoyé un lien de vérification à :',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Text(
              email,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFCE1126),
              ),
            ),
            const SizedBox(height: 20),

            // 🔥 SECTION TEST - BOUTON POUR TESTER MANUELLEMENT
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      '🧪 MODE TEST',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pour tester sans email, cliquez ici :',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _testVerification(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tester la vérification'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Token: ${verificationToken.substring(0, 10)}...',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Cliquez sur le lien dans l\'email pour activer votre compte Eventify.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Bouton renvoyer
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => onResendEmail(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFCE1126)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Color(0xFFCE1126)),
                    SizedBox(width: 8),
                    Text(
                      'Renvoyer l\'email',
                      style: TextStyle(color: Color(0xFFCE1126)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Retour à la connexion
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                'Retour à la connexion',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
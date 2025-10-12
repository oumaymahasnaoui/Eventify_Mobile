import 'package:flutter/material.dart';
import '../../../services/auth_service_verification.dart';
import 'login_page.dart';

class EmailVerificationPage extends StatefulWidget {
  final String? verificationToken;

  const EmailVerificationPage({super.key, this.verificationToken});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final AuthServiceWithVerification _authService = AuthServiceWithVerification();
  bool _isVerifying = false;
  bool _isVerified = false;
  bool _hasError = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    if (widget.verificationToken != null) {
      _verifyEmail(widget.verificationToken!);
    } else {
      _message = 'Aucun token de vérification fourni';
      _hasError = true;
    }
  }

  Future<void> _verifyEmail(String token) async {
    setState(() {
      _isVerifying = true;
      _message = 'Vérification en cours...';
      _hasError = false;
    });

    try {
      print('🔍 Début vérification du token: $token');

      // 1. Vérifier l'email et créer le compte
      final user = await _authService.verifyEmailAndCreateAccount(token);

      setState(() {
        _isVerifying = false;
        _isVerified = true;
        _message = '✅ Votre email a été vérifié avec succès !\n\nBienvenue ${user.name} !';
      });

      print('✅ Compte vérifié avec succès: ${user.email}');

      // 2. Rediriger vers la page de login après 3 secondes
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        _navigateToLogin();
      }

    } catch (e) {
      print('❌ Erreur vérification email: $e');
      setState(() {
        _isVerifying = false;
        _isVerified = false;
        _hasError = true;
        _message = '❌ Erreur: ${e.toString()}';
      });
    }
  }

  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false, // Supprime toutes les routes précédentes
    );
  }

  void _retryVerification() {
    if (widget.verificationToken != null) {
      _verifyEmail(widget.verificationToken!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône dynamique
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isVerified
                      ? Colors.green.withOpacity(0.1)
                      : _hasError
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xFFCE1126).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isVerified
                      ? Icons.verified
                      : _hasError
                      ? Icons.error_outline
                      : Icons.mark_email_read_outlined,
                  size: 60,
                  color: _isVerified
                      ? Colors.green
                      : _hasError
                      ? Colors.red
                      : const Color(0xFFCE1126),
                ),
              ),
              const SizedBox(height: 40),

              // Titre
              Text(
                _isVerified
                    ? 'Email Vérifié !'
                    : _hasError
                    ? 'Erreur de Vérification'
                    : 'Vérification Email',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Indicateur de chargement
              if (_isVerifying) ...[
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCE1126)),
                ),
                const SizedBox(height: 20),
              ],

              // Message
              Text(
                _message,
                style: TextStyle(
                  fontSize: 16,
                  color: _isVerified
                      ? Colors.green
                      : _hasError
                      ? Colors.red
                      : Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Boutons d'action
              if (_isVerified) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCE1126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],

              if (_hasError && !_isVerifying) ...[
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _retryVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCE1126),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Aller à la page de connexion',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFCE1126),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (!_isVerifying && !_isVerified && !_hasError) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFCE1126),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Se connecter'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
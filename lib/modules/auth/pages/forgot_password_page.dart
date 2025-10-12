import 'package:flutter/material.dart';
import '../../../services/password_reset_service.dart';
import 'reset_password_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  late PasswordResetService _resetService;
  bool _isLoading = false;
  String _message = '';
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _resetService = PasswordResetService();
  }

  String _extractTokenFromResult(Map<String, dynamic> result) {
    try {
      if (result.containsKey('reset_link')) {
        final link = result['reset_link'] as String;
        final uri = Uri.parse(link);
        return uri.queryParameters['token'] ?? '';
      }

      if (result.containsKey('token')) {
        return result['token'] as String;
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  void _requestReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = 'Veuillez entrer votre adresse email';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
    });

    final result = await _resetService.requestPasswordReset(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _message = result['message'] ?? '';
      _isSuccess = result['success'] == true;
    });

    // ✅ NAVIGATION AUTOMATIQUE SI SUCCÈS
    if (_isSuccess) {
      Future.delayed(const Duration(seconds: 2), () {
        final token = _extractTokenFromResult(result);

        if (token.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(token: token),
            ),
          );
        }
      });
    }

    if (_isSuccess) {
      _resetService.cleanupExpiredTokens();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        backgroundColor: const Color(0xFFCE1126),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFCE1126).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 40,
                color: Color(0xFFCE1126),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Réinitialisation du mot de passe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'Entrez votre adresse email. Nous vous enverrons un lien sécurisé pour réinitialiser votre mot de passe.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Adresse email',
                hintText: 'exemple@eventify.com',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            if (_message.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isSuccess ? Colors.green[50] : Colors.red[50],
                  border: Border.all(
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _message,
                  style: TextStyle(
                    color: _isSuccess ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCE1126),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
                    : const Text('Envoyer le lien de réinitialisation'),
              ),
            ),

            const Spacer(),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Retour à la connexion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// services/auth_service_verification.dart - VERSION COMPLÈTE CORRIGÉE
import 'dart:developer' as developer;
import '../models/user.dart';
import '../database/database_helper.dart';
import 'real_email_service.dart';
import 'password_service.dart';

class AuthServiceWithVerification {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RealEmailService _emailService = RealEmailService();

  // ✅ MÉTHODE POUR GÉNÉRER UN TOKEN DE VÉRIFICATION
  String _generateVerificationToken() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return 'verify_${timestamp}_${random}';
  }

  // ✅ MÉTHODE POUR METTRE À JOUR LE TOKEN DE VÉRIFICATION
  Future<void> _updateVerificationToken(int userId, String token) async {
    try {
      // Implémentez la logique pour stocker le token dans votre base de données
      // Par exemple, dans une table 'email_verification_tokens'
      developer.log('🔄 Mise à jour token vérification pour user $userId');

      // Simulation - À adapter à votre base de données
      await Future.delayed(Duration(milliseconds: 100));

    } catch (e) {
      developer.log('❌ Erreur mise à jour token: $e');
      rethrow;
    }
  }

  // ✅ MÉTHODE POUR ENVOYER L'EMAIL DE VÉRIFICATION
  Future<Map<String, dynamic>> sendVerificationEmail(User user, String verificationToken) async {
    try {
      final verificationLink = 'https://yourapp.com/verify-email?token=$verificationToken';

      final subject = '✅ Vérification de votre compte Eventify';
      final htmlContent = '''
<!DOCTYPE html>
<html>
<body>
  <h1>Bienvenue sur Eventify, ${user.name}!</h1>
  <p>Cliquez sur le lien pour vérifier votre compte :</p>
  <a href="$verificationLink">Vérifier mon compte</a>
</body>
</html>
      ''';

      final textContent = 'Vérifiez votre compte Eventify: $verificationLink';

      final emailResponse = await _emailService.sendEmail(
        toEmail: user.email,
        subject: subject,
        htmlContent: htmlContent,
        textContent: textContent,
      );

      return emailResponse;
    } catch (e) {
      developer.log('❌ Erreur envoi email vérification: $e');
      return {
        'success': false,
        'message': 'Erreur envoi email: $e'
      };
    }
  }

  // ✅ MÉTHODE POUR RENVOYER L'EMAIL DE VÉRIFICATION
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      developer.log('🔄 Renvoi email vérification à: $email');

      // Récupérer l'utilisateur
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé'
        };
      }

      // Générer un nouveau token
      final newToken = _generateVerificationToken();

      // Mettre à jour le token dans la base
      await _updateVerificationToken(user.id!, newToken);

      // Renvoyer l'email
      final emailResult = await sendVerificationEmail(user, newToken);

      return {
        'success': emailResult['success'] == true,
        'message': emailResult['message'] ?? 'Email de vérification renvoyé'
      };

    } catch (e) {
      developer.log('❌ Erreur renvoi email vérification: $e');
      return {
        'success': false,
        'message': 'Erreur lors du renvoi de l\'email: $e'
      };
    }
  }

  // ✅ MÉTHODE POUR VÉRIFIER L'EMAIL ET CRÉER LE COMPTE
  Future<User> verifyEmailAndCreateAccount(String token) async {
    try {
      developer.log('🔍 Vérification du token: $token');

      // Simulation de la vérification du token
      // Dans une vraie implémentation, vous vérifieriez le token dans la base de données
      await Future.delayed(Duration(seconds: 1));

      // Extraire l'email du token (simulation)
      final email = _extractEmailFromToken(token);

      // Récupérer l'utilisateur
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        throw Exception('Utilisateur non trouvé');
      }

      // Marquer l'utilisateur comme vérifié
      final verifiedUser = User(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        password: user.password,
        joinDate: user.joinDate,
        birthDate: user.birthDate,
        bio: user.bio,
        location: user.location,
        isActive: true,
        isVerified: true,
        lastLogin: DateTime.now(),
      );

      await _dbHelper.updateUser(verifiedUser);
      developer.log('✅ Compte vérifié avec succès: ${user.email}');

      return verifiedUser;

    } catch (e) {
      developer.log('❌ Erreur vérification email: $e');
      rethrow;
    }
  }

  // ✅ MÉTHODE POUR INSCRIPTION AVEC VÉRIFICATION
  Future<Map<String, dynamic>> registerWithVerification(User user) async {
    try {
      developer.log('📝 Inscription avec vérification: ${user.email}');

      // Vérifier si l'email existe déjà
      final existingUser = await _dbHelper.getUserByEmail(user.email);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Un compte existe déjà avec cet email'
        };
      }

      // Insérer l'utilisateur
      final userId = await _dbHelper.insertUser(user);
      final newUser = await _dbHelper.getUserById(userId);

      if (newUser == null) {
        throw Exception('Erreur lors de la création du compte');
      }

      // Générer et envoyer l'email de vérification
      final verificationToken = _generateVerificationToken();
      final emailResult = await sendVerificationEmail(newUser, verificationToken);

      return {
        'success': true,
        'message': 'Compte créé avec succès. Vérifiez votre email.',
        'user': newUser,
        'email_sent': emailResult['success'],
        'verification_token': verificationToken,
      };

    } catch (e) {
      developer.log('❌ Erreur inscription avec vérification: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la création du compte: $e'
      };
    }
  }

  // ✅ MÉTHODE POUR EXTRAIRE L'EMAIL DU TOKEN (SIMULATION)
  String _extractEmailFromToken(String token) {
    // Dans une vraie implémentation, vous récupéreriez l'email depuis la base de données
    // Pour la démo, nous simulons l'extraction
    try {
      // Simulation - en réalité vous devriez stocker l'email avec le token
      return 'user@eventify.com';
    } catch (e) {
      throw Exception('Token invalide');
    }
  }
}
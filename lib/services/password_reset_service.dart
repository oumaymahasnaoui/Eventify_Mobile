import 'dart:math';
import 'dart:convert';
import 'dart:developer' as developer;
import '../database/database_helper.dart';
import '../models/user.dart';
import 'real_email_service.dart';
import 'password_service.dart';

class PasswordResetService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final RealEmailService _emailService = RealEmailService();

  // ✅ GÉNÉRER UN TOKEN SÉCURISÉ INTELLIGENT
  String _generateSecureToken() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = String.fromCharCodes(
      List.generate(16, (i) => random.nextInt(256)),
    );
    return 'reset_${timestamp}_${base64Url.encode(utf8.encode(randomPart))}';
  }

  // ✅ CALCULER LA DATE D'EXPIRATION (15 minutes)
  DateTime _getExpiryDate() {
    return DateTime.now().add(const Duration(minutes: 15));
  }

  // ✅ DEMANDE DE RÉINITIALISATION INTELLIGENTE
  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      developer.log('🔐 Demande réinitialisation mot de passe pour: $email');

      // 1. Vérifier si l'email existe
      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        // ✅ STRATÉGIE INTELLIGENTE : Ne pas révéler si l'email existe
        developer.log('📧 Email non trouvé (sécurité), mais envoi simulé');
        await Future.delayed(const Duration(seconds: 2));
        return {
          'success': true,
          'message': 'Si cet email existe, vous recevrez un lien de réinitialisation',
          'email_sent': true
        };
      }

      // 2. Vérifier si une demande récente existe (prévenir le spam)
      final recentRequest = await _hasRecentResetRequest(user.id!);
      if (recentRequest) {
        return {
          'success': false,
          'message': 'Une demande a déjà été envoyée récemment. Vérifiez vos emails.',
          'too_many_requests': true
        };
      }

      // 3. Générer token sécurisé
      final resetToken = _generateSecureToken();
      final expiryDate = _getExpiryDate();

      // 4. Sauvegarder dans la base (nouvelle table)
      await _saveResetRequest(user.id!, resetToken, expiryDate);

      // 5. Envoyer l'email intelligent
      final emailResult = await _sendResetEmail(user.email, resetToken, user.name);

      if (emailResult['success'] == true) {
        return {
          'success': true,
          'message': 'Lien de réinitialisation envoyé à $email',
          'email_sent': true,
          'reset_link': 'eventify://reset-password?token=$resetToken',
          'token': resetToken,
          'expires_in': '15 minutes'
        };
      } else {
        // En cas d'erreur email, supprimer la demande
        await _deleteResetRequest(user.id!);
        return {
          'success': false,
          'message': 'Erreur envoi email. Réessayez plus tard.'
        };
      }

    } catch (e) {
      developer.log('❌ Erreur demande réinitialisation: $e');
      return {
        'success': false,
        'message': 'Erreur système. Réessayez plus tard.'
      };
    }
  }

  // ✅ VÉRIFIER ET RÉINITIALISER LE MOT DE PASSE
  Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      developer.log('🔄 Tentative réinitialisation avec token: ${token.substring(0, 20)}...');

      // 1. Vérifier le token
      final resetRequest = await _getValidResetRequest(token);
      if (resetRequest == null) {
        return {
          'success': false,
          'message': 'Lien invalide ou expiré',
          'invalid_token': true
        };
      }

      // 2. Vérifier la force du nouveau mot de passe
      final passwordStrength = _checkPasswordStrength(newPassword);
      if (!passwordStrength['strong']) {
        return {
          'success': false,
          'message': passwordStrength['message'],
          'weak_password': true
        };
      }

      // 3. Récupérer l'utilisateur
      final user = await _dbHelper.getUserById(resetRequest['user_id']);
      if (user == null) {
        return {
          'success': false,
          'message': 'Utilisateur non trouvé'
        };
      }

      // 4. Hacher et mettre à jour le mot de passe
      final hashedPassword = PasswordService.hashPassword(newPassword);
      final updatedUser = User(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        password: hashedPassword,
        joinDate: user.joinDate,
        birthDate: user.birthDate,
        bio: user.bio,
        location: user.location,
        isActive: user.isActive,
        isVerified: user.isVerified,
        lastLogin: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser);

      // 5. Marquer le token comme utilisé
      await _markTokenAsUsed(resetRequest['id']);

      // 6. Envoyer email de confirmation
      await _sendPasswordChangedConfirmation(user.email, user.name);

      developer.log('✅ Mot de passe réinitialisé avec succès pour: ${user.email}');

      return {
        'success': true,
        'message': 'Mot de passe réinitialisé avec succès',
        'user_email': user.email
      };

    } catch (e) {
      developer.log('❌ Erreur réinitialisation: $e');
      return {
        'success': false,
        'message': 'Erreur lors de la réinitialisation'
      };
    }
  }

  // ✅ VÉRIFIER LA FORCE DU MOT DE PASSE INTELLIGENTE
  Map<String, dynamic> _checkPasswordStrength(String password) {
    if (password.length < 8) {
      return {
        'strong': false,
        'message': 'Le mot de passe doit contenir au moins 8 caractères'
      };
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return {
        'strong': false,
        'message': 'Ajoutez une majuscule'
      };
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return {
        'strong': false,
        'message': 'Ajoutez une minuscule'
      };
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return {
        'strong': false,
        'message': 'Ajoutez un chiffre'
      };
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return {
        'strong': false,
        'message': 'Ajoutez un caractère spécial'
      };
    }

    // Vérifier les mots de passe faibles courants
    final weakPasswords = [
      'password', '12345678', 'qwerty', 'azerty', 'password123'
    ];
    if (weakPasswords.contains(password.toLowerCase())) {
      return {
        'strong': false,
        'message': 'Ce mot de passe est trop commun'
      };
    }

    return {
      'strong': true,
      'message': 'Mot de passe sécurisé'
    };
  }

  // ============ MÉTHODES BASE DE DONNÉES ============

  // ✅ CRÉER LA TABLE PASSWORD_RESETS
  Future<void> _ensurePasswordResetsTable() async {
    final db = await _dbHelper.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS password_resets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        reset_token TEXT UNIQUE NOT NULL,
        expires_at TEXT NOT NULL,
        used INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
    developer.log('✅ Table password_resets créée');
  }

  Future<void> _saveResetRequest(int userId, String token, DateTime expiresAt) async {
    await _ensurePasswordResetsTable();
    final db = await _dbHelper.database;

    await db.insert('password_resets', {
      'user_id': userId,
      'reset_token': token,
      'expires_at': expiresAt.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> _getValidResetRequest(String token) async {
    await _ensurePasswordResetsTable();
    final db = await _dbHelper.database;

    final requests = await db.query(
      'password_resets',
      where: 'reset_token = ? AND used = 0 AND expires_at > ?',
      whereArgs: [token, DateTime.now().toIso8601String()],
    );

    return requests.isNotEmpty ? requests.first : null;
  }

  Future<bool> _hasRecentResetRequest(int userId) async {
    await _ensurePasswordResetsTable();
    final db = await _dbHelper.database;

    final fifteenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 15));

    final requests = await db.query(
      'password_resets',
      where: 'user_id = ? AND created_at > ?',
      whereArgs: [userId, fifteenMinutesAgo.toIso8601String()],
    );

    return requests.isNotEmpty;
  }

  Future<void> _markTokenAsUsed(int requestId) async {
    final db = await _dbHelper.database;
    await db.update(
      'password_resets',
      {'used': 1},
      where: 'id = ?',
      whereArgs: [requestId],
    );
  }

  Future<void> _deleteResetRequest(int userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'password_resets',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  // ============ MÉTHODES EMAIL INTELLIGENTES ============

  Future<Map<String, dynamic>> _sendResetEmail(String email, String token, String name) async {
    try {
      // Utiliser la nouvelle méthode spécialisée
      return await _emailService.sendPasswordResetEmail(
        toEmail: email,
        userName: name,
        resetToken: token,
      );
    } catch (e) {
      developer.log('❌ Erreur envoi email réinitialisation: $e');
      return {
        'success': false,
        'message': 'Erreur lors de l\'envoi de l\'email'
      };
    }
  }

  Future<void> _sendPasswordChangedConfirmation(String email, String name) async {
    try {
      await _emailService.sendPasswordChangedConfirmation(
        toEmail: email,
        userName: name,
      );
      developer.log('✅ Email de confirmation envoyé à: $email');
    } catch (e) {
      developer.log('❌ Erreur envoi confirmation: $e');
      // Ne pas bloquer le processus si l'email de confirmation échoue
    }
  }

  // ✅ NETTOYAGE AUTOMATIQUE DES TOKENS EXPIRÉS
  Future<void> cleanupExpiredTokens() async {
    try {
      final db = await _dbHelper.database;
      await db.delete(
        'password_resets',
        where: 'expires_at < ? OR used = 1',
        whereArgs: [DateTime.now().toIso8601String()],
      );
      developer.log('🧹 Tokens de réinitialisation expirés nettoyés');
    } catch (e) {
      developer.log('❌ Erreur nettoyage tokens: $e');
    }
  }
}
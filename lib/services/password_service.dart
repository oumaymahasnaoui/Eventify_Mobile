// services/password_service.dart - AVEC CRYPTO
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';

class PasswordService {
  // ✅ Générer un salt aléatoire
  static String _generateSalt([int length = 32]) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }

  // ✅ Hacher un mot de passe avec salt
  static String hashPassword(String plainPassword) {
    try {
      final salt = _generateSalt();
      final bytes = utf8.encode(plainPassword + salt);
      final digest = sha256.convert(bytes);

      // Format: hash:salt pour pouvoir vérifier plus tard
      final hashedPassword = '${digest.toString()}:$salt';

      print('🔐 Mot de passe haché avec succès');
      return hashedPassword;
    } catch (e) {
      print('❌ Erreur lors du hashage: $e');
      throw Exception('Erreur de sécurité lors du hashage');
    }
  }

  // ✅ Vérifier un mot de passe
  static bool verifyPassword(String plainPassword, String hashedPassword) {
    try {
      // Séparer le hash et le salt
      final parts = hashedPassword.split(':');
      if (parts.length != 2) {
        print('❌ Format de mot de passe haché invalide');
        return false;
      }

      final storedHash = parts[0];
      final salt = parts[1];

      // Recréer le hash avec le mot de passe fourni et le salt stocké
      final bytes = utf8.encode(plainPassword + salt);
      final digest = sha256.convert(bytes);
      final computedHash = digest.toString();

      final isValid = storedHash == computedHash;
      print('🔐 Vérification mot de passe: ${isValid ? "✅ Valide" : "❌ Invalide"}');

      return isValid;
    } catch (e) {
      print('❌ Erreur vérification mot de passe: $e');
      return false;
    }
  }

  // ✅ Méthode améliorée avec plusieurs algorithmes (optionnel)
  static String hashPasswordSecure(String plainPassword, {String algorithm = 'sha256'}) {
    try {
      final salt = _generateSalt();
      final bytes = utf8.encode(plainPassword + salt);

      List<int> digestBytes;
      switch (algorithm.toLowerCase()) {
        case 'sha1':
          digestBytes = sha1.convert(bytes).bytes;
          break;
        case 'sha256':
          digestBytes = sha256.convert(bytes).bytes;
          break;
        case 'sha512':
          digestBytes = sha512.convert(bytes).bytes;
          break;
        default:
          digestBytes = sha256.convert(bytes).bytes;
      }

      final digest = digestBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
      final hashedPassword = '$algorithm:$digest:$salt';

      print('🔐 Mot de passe haché avec $algorithm');
      return hashedPassword;
    } catch (e) {
      print('❌ Erreur hashage sécurisé: $e');
      return hashPassword(plainPassword); // Fallback
    }
  }

  // ✅ Vérifier avec support multi-algorithmes
  static bool verifyPasswordSecure(String plainPassword, String hashedPassword) {
    try {
      final parts = hashedPassword.split(':');

      if (parts.length == 2) {
        // Format simple: hash:salt
        return verifyPassword(plainPassword, hashedPassword);
      } else if (parts.length == 3) {
        // Format étendu: algorithm:hash:salt
        final algorithm = parts[0];
        final storedHash = parts[1];
        final salt = parts[2];

        final bytes = utf8.encode(plainPassword + salt);

        List<int> digestBytes;
        switch (algorithm.toLowerCase()) {
          case 'sha1':
            digestBytes = sha1.convert(bytes).bytes;
            break;
          case 'sha256':
            digestBytes = sha256.convert(bytes).bytes;
            break;
          case 'sha512':
            digestBytes = sha512.convert(bytes).bytes;
            break;
          default:
            digestBytes = sha256.convert(bytes).bytes;
        }

        final computedHash = digestBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
        return storedHash == computedHash;
      } else {
        print('❌ Format de hash invalide');
        return false;
      }
    } catch (e) {
      print('❌ Erreur vérification sécurisée: $e');
      return false;
    }
  }

  // ✅ Tester le système de hashage
  static void testHashSystem() {
    final testPassword = 'monMotDePasse123';
    print('🧪 TEST SYSTÈME HASHAGE');
    print('Mot de passe original: $testPassword');

    final hashed = hashPassword(testPassword);
    print('Mot de passe haché: $hashed');

    final isValid = verifyPassword(testPassword, hashed);
    print('Vérification correcte: $isValid');

    final isWrongPassword = verifyPassword('mauvaisMotDePasse', hashed);
    print('Vérification mauvais mot de passe: $isWrongPassword');

    // Test avec méthode sécurisée
    final secureHashed = hashPasswordSecure(testPassword, algorithm: 'sha256');
    print('Mot de passe haché sécurisé: $secureHashed');

    final isSecureValid = verifyPasswordSecure(testPassword, secureHashed);
    print('Vérification sécurisée: $isSecureValid');
  }
}
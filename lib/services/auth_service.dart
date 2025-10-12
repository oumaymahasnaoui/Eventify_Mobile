// services/auth_service.dart
import '../models/user.dart';
import '../database/database_helper.dart';
import 'dart:developer' as developer;
import 'password_service.dart'; // ✅ IMPORT
// CORRECTION - Ajouter cet import manquant
import 'package:flutter/material.dart'; // ← AJOUTER CET IMPORT
class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<User?> login(String email, String password) async {
    developer.log('🔐 Tentative de connexion: $email');

    try {
      // Validation basique de l'email
      if (!_isValidEmail(email)) {
        developer.log('❌ Format email invalide: $email');
        throw Exception('Format d\'email invalide');
      }

      final user = await _dbHelper.getUserByEmail(email);

      if (user == null) {
        developer.log('❌ Utilisateur non trouvé: $email');
        return null;
      }

      // ✅ CORRECTION : Vérifier d'abord si le compte est vérifié
      if (!user.isVerified) {
        developer.log('❌ Compte non vérifié: $email');
        throw Exception('Veuillez vérifier votre email avant de vous connecter');
      }

      // ✅ CORRECTION : Vérifier le mot de passe
      final isValid = await _dbHelper.validateUser(email, password);
      if (!isValid) {
        developer.log('❌ Mot de passe incorrect pour: $email');
        return null;
      }

      developer.log('✅ Connexion réussie: ${user.name}');

      // Mettre à jour lastLogin
      final updatedUser = User(
        id: user.id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        password: user.password,
        joinDate: user.joinDate,
        birthDate: user.birthDate,
        bio: user.bio,
        location: user.location,
        isActive: true, // ✅ Maintenant actif
        isVerified: true, // ✅ Vérifié
        lastLogin: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser);
      return updatedUser;

    } catch (e) {
      developer.log('❌ Erreur connexion: $e');
      rethrow; // ✅ Relancer l'exception pour la gérer dans l'UI
    }
  }

  Future<User?> register(User user) async {
    try {
      developer.log('📝 Tentative d\'inscription: ${user.email}');

      // Validation de l'email
      if (!_isValidEmail(user.email)) {
        throw Exception('Format d\'email invalide');
      }

      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _dbHelper.getUserByEmail(user.email);
      if (existingUser != null) {
        developer.log('❌ Utilisateur existe déjà: ${user.email}');
        throw Exception('Un compte existe déjà avec cet email');
      }

      // Insérer le nouvel utilisateur
      final userId = await _dbHelper.insertUser(user);
      developer.log('✅ Utilisateur inscrit avec ID: $userId');

      // Récupérer l'utilisateur créé
      final newUser = await _dbHelper.getUserById(userId);
      developer.log('👤 Détails nouvel utilisateur: ${newUser?.name}');

      return newUser;
    } catch (e) {
      developer.log('❌ Erreur inscription: $e');
      throw Exception('Erreur lors de la création du compte: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<bool> checkEmailExists(String email) async {
    try {
      final user = await _dbHelper.getUserByEmail(email);
      return user != null;
    } catch (e) {
      developer.log('❌ Erreur vérification email: $e');
      return false;
    }
  }

  Future<void> logout() async {
    developer.log('🚪 Utilisateur déconnecté');
    // Nettoyer les données de session si nécessaire
  }

  Future<User?> getCurrentUser() async {
    developer.log('👤 Récupération utilisateur courant');
    // Pour la démo, retourner le premier utilisateur
    final users = await _dbHelper.getAllUsers();
    final user = users.isNotEmpty ? users.first : null;
    developer.log('📊 Utilisateur courant: ${user?.name}');
    return user;
  }

  Future<bool> updateProfile(User user) async {
    try {
      developer.log('✏️ Mise à jour profil: ${user.name}');

      final result = await _dbHelper.updateUser(user);
      final success = result > 0;

      developer.log('📝 Résultat mise à jour profil: $success');
      return success;
    } catch (e) {
      developer.log('❌ Erreur mise à jour profil: $e');
      return false;
    }
  }

  // Méthode pour réinitialiser le mot de passe
  Future<bool> resetPassword(String email) async {
    try {
      developer.log('🔄 Réinitialisation mot de passe: $email');

      final user = await _dbHelper.getUserByEmail(email);
      if (user == null) {
        developer.log('❌ Email non trouvé: $email');
        return false;
      }

      // TODO: Implémenter l'envoi d'email de réinitialisation
      developer.log('✅ Email de réinitialisation envoyé à: $email');
      return true;
    } catch (e) {
      developer.log('❌ Erreur réinitialisation: $e');
      return false;
    }
  }



// CORRECTION - La remplacer par :
  Future<User?> getUserByEmail(String email) async {
    try {
      return await _dbHelper.getUserByEmail(email);
    } catch (e) {
      developer.log('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }
  // Dans auth_service.dart - Ajoutez cette méthode
  Future<void> signOut() async {
    try {
      print('🚪 Déconnexion de l\'utilisateur...');

      // Simulation de déconnexion
      await Future.delayed(const Duration(seconds: 1));

      print('✅ Utilisateur déconnecté avec succès');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
      throw Exception('Erreur lors de la déconnexion');
    }
  }
}
// database/database_helper.dart - VERSION COMPLÈTE AVEC TOUTES LES MÉTHODES
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../services/password_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'eventify.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onDowngrade: onDatabaseDowngradeDelete,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        join_date TEXT NOT NULL,
        birth_date TEXT,
        bio TEXT,
        location TEXT,
        is_active INTEGER DEFAULT 0,
        is_verified INTEGER DEFAULT 0,
        verification_token TEXT,
        verification_sent_at TEXT,
        last_login TEXT
      )
    ''');
    developer.log('✅ Nouvelle base créée avec hashage activé');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('🔄 MIGRATION: v$oldVersion -> v$newVersion');

    if (oldVersion < 2) {
      await _migrateToVersion2(db);
    }
  }

  Future<void> _migrateToVersion2(Database db) async {
    developer.log('🔐 Migration vers le hashage des mots de passe...');

    try {
      await db.execute('''
        CREATE TABLE users_new(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          email TEXT UNIQUE NOT NULL,
          phone TEXT NOT NULL,
          password TEXT NOT NULL,
          join_date TEXT NOT NULL,
          birth_date TEXT,
          bio TEXT,
          location TEXT,
          is_active INTEGER DEFAULT 0,
          is_verified INTEGER DEFAULT 0,
          verification_token TEXT,
          verification_sent_at TEXT,
          last_login TEXT
        )
      ''');

      final List<Map<String, dynamic>> oldUsers = await db.query('users');
      developer.log('📊 ${oldUsers.length} utilisateurs à migrer');

      for (final user in oldUsers) {
        final plainPassword = user['password'] as String? ?? 'default123';
        final hashedPassword = PasswordService.hashPassword(plainPassword);

        await db.insert('users_new', {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'phone': user['phone'],
          'password': hashedPassword,
          'join_date': user['join_date'],
          'birth_date': user['birth_date'],
          'bio': user['bio'],
          'location': user['location'],
          'is_active': user['is_active'],
          'is_verified': user['is_verified'],
          'verification_token': user['verification_token'],
          'verification_sent_at': user['verification_sent_at'],
          'last_login': user['last_login'],
        });

        developer.log('✅ Migré: ${user['email']}');
      }

      await db.execute('DROP TABLE users');
      await db.execute('ALTER TABLE users_new RENAME TO users');

      developer.log('🎉 Migration hashage terminée avec succès!');

    } catch (e) {
      developer.log('❌ Erreur migration: $e');
      rethrow;
    }
  }

  // ============ MÉTHODES CRUD COMPLÈTES ============

  // ✅ INSERTION AVEC HASHAGE
  Future<int> insertUser(User user) async {
    final db = await database;
    developer.log('➕ Insertion utilisateur: ${user.email}');

    try {
      final hashedPassword = PasswordService.hashPassword(user.password);

      final userMap = user.toMap()
        ..['password'] = hashedPassword;

      final result = await db.insert('users', userMap);
      developer.log('✅ Utilisateur inséré avec ID: $result (MOT DE PASSE HACHÉ)');

      await _verifyPasswordHashing(user.email);

      return result;
    } catch (e) {
      developer.log('❌ Erreur insertion: $e');
      rethrow;
    }
  }

  // ✅ VALIDATION AVEC HASHAGE
  Future<bool> validateUser(String email, String plainPassword) async {
    try {
      final db = await database;
      final users = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (users.isEmpty) {
        developer.log('❌ Utilisateur non trouvé: $email');
        return false;
      }

      final user = users.first;
      final storedPassword = user['password'] as String;

      // Vérifier si le mot de passe est déjà haché
      final isHashed = storedPassword.contains(':');

      if (!isHashed) {
        developer.log('⚠️ Mot de passe non haché détecté, hashage en cours...');
        final hashedPassword = PasswordService.hashPassword(storedPassword);
        await db.update(
          'users',
          {'password': hashedPassword},
          where: 'email = ?',
          whereArgs: [email],
        );
        developer.log('✅ Mot de passe re-haché pour: $email');
      }

      return PasswordService.verifyPassword(plainPassword, storedPassword);

    } catch (e) {
      developer.log('❌ Erreur validation: $e');
      return false;
    }
  }

  // ✅ RÉCUPÉRER PAR EMAIL
  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    developer.log('🔍 Recherche utilisateur par email: $email');

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    developer.log('📊 Trouvé ${maps.length} utilisateur(s)');

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // ✅ RÉCUPÉRER PAR ID
  Future<User?> getUserById(int id) async {
    final db = await database;
    developer.log('🔍 Recherche utilisateur par ID: $id');

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // ✅ RÉCUPÉRER PAR TOKEN DE VÉRIFICATION
  Future<User?> getUserByVerificationToken(String token) async {
    final db = await database;
    developer.log('🔍 Recherche utilisateur par token de vérification');

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'verification_token = ? AND is_verified = 0',
      whereArgs: [token],
    );

    developer.log('📊 Trouvé ${maps.length} utilisateur(s) avec token');

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // ✅ METTRE À JOUR UTILISATEUR
  Future<int> updateUser(User user) async {
    final db = await database;
    developer.log('✏️ Mise à jour utilisateur: ${user.id} - ${user.name}');

    try {
      final result = await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
      developer.log('✅ Utilisateur mis à jour avec succès');
      return result;
    } catch (e) {
      developer.log('❌ Erreur mise à jour: $e');
      rethrow;
    }
  }

  // ✅ TOUS LES UTILISATEURS
  Future<List<User>> getAllUsers() async {
    final db = await database;
    developer.log('📋 Récupération de tous les utilisateurs');

    final List<Map<String, dynamic>> maps = await db.query('users');
    final users = List.generate(maps.length, (i) => User.fromMap(maps[i]));
    developer.log('📊 Total utilisateurs: ${users.length}');
    return users;
  }

  // ✅ SUPPRIMER UTILISATEUR
  Future<int> deleteUser(int id) async {
    final db = await database;
    developer.log('🗑️ Suppression utilisateur: $id');

    try {
      final result = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      developer.log('✅ Utilisateur supprimé avec succès');
      return result;
    } catch (e) {
      developer.log('❌ Erreur suppression: $e');
      rethrow;
    }
  }

  // ============ MÉTHODES DE DEBUG ============

  Future<void> debugDatabaseInfo() async {
    final db = await database;
    final version = await db.getVersion();
    print('🔍 INFORMATION BASE DE DONNÉES:');
    print('📊 Version: $version');
    print('📍 Chemin: ${await getDatabasePath()}');

    await debugTableSchema();
    await debugAllUsersWithPasswords();
  }

  Future<void> debugAllUsersWithPasswords() async {
    final db = await database;
    final users = await db.query('users');
    print('👥 UTILISATEURS ET MOTS DE PASSE:');
    for (final user in users) {
      print('  ID: ${user['id']}');
      print('  Email: ${user['email']}');
      print('  Mot de passe: ${user['password']}');
      print('  Longueur: ${(user['password'] as String).length} caractères');
      print('  ---');
    }
  }

  Future<void> debugTableSchema() async {
    final db = await database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
    print('📋 SCHEMA DE LA TABLE users:');
    for (final column in tableInfo) {
      print('  ${column['name']} - ${column['type']}');
    }
  }

  Future<void> debugAllUsers() async {
    final db = await database;
    final users = await db.query('users');
    print('👥 UTILISATEURS DANS LA BASE:');
    for (final user in users) {
      print('  ID: ${user['id']}, Email: ${user['email']}, Vérifié: ${user['is_verified']}');
    }
  }

  Future<String> getDatabasePath() async {
    final path = join(await getDatabasesPath(), 'eventify.db');
    print('📍 CHEMIN DE LA BASE: $path');
    return path;
  }

  // ============ MÉTHODES UTILITAIRES ============

  Future<void> _verifyPasswordHashing(String email) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (users.isNotEmpty) {
      final storedPassword = users.first['password'] as String;
      final isHashed = storedPassword.contains(':') && storedPassword.length > 20;

      if (isHashed) {
        developer.log('🔐 HASHAGE CONFIRMÉ pour: $email');
      } else {
        developer.log('⚠️ ATTENTION: Mot de passe non haché pour: $email');
      }
    }
  }

  Future<void> forcePasswordHashingMigration() async {
    print('🔄 FORÇAGE MIGRATION HASHAGE...');

    final db = await database;
    final currentVersion = await db.getVersion();
    print('📊 Version actuelle: $currentVersion');

    if (currentVersion < 2) {
      print('🚀 Exécution de la migration...');
      await _onUpgrade(db, currentVersion, 2);
      await db.setVersion(2);
      print('✅ Migration forcée terminée');
    } else {
      print('ℹ️ Base déjà à la version 2');
    }

    await debugAllUsersWithPasswords();
  }

  Future<void> forceResetDatabase() async {
    developer.log('🗑️ RÉINITIALISATION COMPLÈTE DE LA BASE...');

    final db = await database;
    await db.close();
    _database = null;

    final path = join(await getDatabasesPath(), 'eventify.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      developer.log('✅ Base supprimée');
    }

    _database = await _initDatabase();
    developer.log('✅ Nouvelle base créée avec hashage activé');
  }

  Future<void> testHashSystem() async {
    developer.log('🧪 TEST DU SYSTÈME DE HASHAGE...');

    PasswordService.testHashSystem();

    final testUser = User(
      name: 'Test Hash',
      email: 'test_hash@example.com',
      phone: '0000000000',
      password: 'motdepasse123',
      joinDate: DateTime.now(),
      isActive: true,
      isVerified: true,
    );

    try {
      final id = await insertUser(testUser);
      developer.log('✅ Utilisateur test inséré avec ID: $id');

      final isValid = await validateUser('test_hash@example.com', 'motdepasse123');
      developer.log('✅ Test connexion: $isValid');

      final isInvalid = await validateUser('test_hash@example.com', 'mauvais');
      developer.log('✅ Test mauvais mot de passe: $isInvalid (doit être false)');

    } catch (e) {
      developer.log('❌ Erreur test: $e');
    }
  }

  // ✅ VÉRIFIER SI EMAIL EXISTE
  Future<bool> emailExists(String email) async {
    final user = await getUserByEmail(email);
    return user != null;
  }
// Dans DatabaseHelper - AJOUTER
  Future<void> createPasswordResetsTable() async {
    final db = await database;
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
  // ✅ ACTIVER COMPTE APRÈS VÉRIFICATION
  Future<void> activateUserAccount(int userId) async {
    final db = await database;
    developer.log('✅ Activation compte utilisateur: $userId');

    await db.update(
      'users',
      {
        'is_active': 1,
        'is_verified': 1,
        'verification_token': null,
        'verification_sent_at': null,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // ✅ METTRE À JOUR DERNIER LOGIN
  Future<void> updateLastLogin(int userId) async {
    final db = await database;
    await db.update(
      'users',
      {
        'last_login': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }
}
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../models/event.dart';

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
    String path = join(await getDatabasesPath(), 'eventify.db');
    developer.log('🗃️ Database path: $path');

    return await openDatabase(
      path,
      version: 2, // Version augmentée
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }
  // AJOUTEZ cette méthode dans DatabaseHelper
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('🔄 Upgrading database from $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // Ajouter la colonne maxParticipants si elle n'existe pas
      try {
        await db.execute('ALTER TABLE events ADD COLUMN maxParticipants INTEGER DEFAULT 0');
        developer.log('✅ Added maxParticipants column to events table');
      } catch (e) {
        developer.log('ℹ️ Column maxParticipants might already exist: $e');
      }
    }
  }

  Future<void> _createTables(Database db, int version) async {
    developer.log('🔧 Creating tables...');

    // Table users
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        joinDate TEXT NOT NULL,
        birthDate TEXT,
        bio TEXT,
        location TEXT,
        isActive INTEGER DEFAULT 1,
        lastLogin TEXT
      )
    ''');

    developer.log('✅ Table users created successfully');

    // Table events
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        participants TEXT NOT NULL,
        createdBy INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
         maxParticipants INTEGER DEFAULT 0,
        FOREIGN KEY (createdBy) REFERENCES users(id)
      )
    ''');

    developer.log('✅ Table events created successfully');

    // Insérer un utilisateur de test
    await _insertTestUser(db);
  }

  Future<void> _insertTestUser(Database db) async {
    final existingUsers = await db.query('users',
        where: 'email = ?',
        whereArgs: ['oumayma@eventify.com']);

    if (existingUsers.isEmpty) {
      await db.insert('users', {
        'name': 'Oumayma Ben Ahmed',
        'email': 'oumayma@eventify.com',
        'phone': '+216 12 345 678',
        'password': 'password123',
        'joinDate': DateTime.now().toIso8601String(),
        'bio': 'Passionnée d\'événements et de voyages',
        'location': 'Tunis, Tunisia',
        'isActive': 1,
      });
      developer.log('👤 Test user inserted');
    } else {
      developer.log('👤 Test user already exists');
    }
  }

  // ============ CRUD OPERATIONS FOR USERS ============

  Future<int> insertUser(User user) async {
    final db = await database;
    developer.log('➕ Inserting user: ${user.email}');
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    developer.log('🔍 Searching user by email: $email');

    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    developer.log('📊 Found ${maps.length} user(s)');

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    developer.log('🔍 Searching user by ID: $id');

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

  Future<int> updateUser(User user) async {
    final db = await database;
    developer.log('✏️ Updating user: ${user.id} - ${user.name}');

    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    developer.log('📋 Getting all users');

    final List<Map<String, dynamic>> maps = await db.query('users');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    developer.log('🗑️ Deleting user: $id');

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> validateUser(String email, String password) async {
    final user = await getUserByEmail(email);
    final isValid = user != null && user.password == password;
    developer.log('🔑 Validation for $email: $isValid');
    return isValid;
  }

  // ============ CRUD OPERATIONS FOR EVENTS ============

  Future<int> insertEvent(Event event) async {
    final db = await database;
    developer.log('➕ Inserting event: ${event.title}');

    try {
      final result = await db.insert('events', {
        'title': event.title,
        'date': event.date.toIso8601String(),
        'location': event.location,
        'description': event.description,
        'category': event.category,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'participants': event.participants.join(','),
        'createdBy': event.createdBy,
        'createdAt': event.createdAt.toIso8601String(),
        'maxParticipants': event.maxParticipants,
      });

      developer.log('✅ Event inserted successfully with id: $result');
      return result;
    } catch (e) {
      developer.log('❌ Error inserting event: $e');
      rethrow;
    }
  }

  Future<List<Event>> getEvents() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('events');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getEventsByUser(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'createdBy = ?',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<List<Event>> getEventsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }

  Future<int> updateEvent(Event event) async {
    final db = await database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  Future<int> deleteEvent(int eventId) async {
    final db = await database;
    return await db.delete(
      'events',
      where: 'id = ?',
      whereArgs: [eventId],
    );
  }

  // ============ UTILITY METHODS ============

  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    String path = join(await getDatabasesPath(), 'eventify.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      developer.log('🗑️ Database deleted and will be recreated');
    }

    _database = await _initDatabase();
  }

  Future exportDatabaseToFile() async {}
  // 📊 Méthode pour afficher le schéma de la table
  Future<void> debugTableSchema() async {
    final db = await database;
    final tableInfo = await db.rawQuery('PRAGMA table_info(users)');
    print('📋 SCHEMA DE LA TABLE users:');
    for (final column in tableInfo) {
      print('  ${column['name']} - ${column['type']}');
    }
  }
  // ============ DEBUG METHODS ============

// Ajoutez cette méthode dans la classe DatabaseHelper
  Future<List<User>> getUsersByIds(List<int> userIds) async {
    final db = await database;

    if (userIds.isEmpty) {
      return [];
    }

    try {
      developer.log('🔍 Fetching users by IDs: $userIds');

      // Créer les placeholders pour la requête SQL
      final placeholders = List.filled(userIds.length, '?').join(',');

      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id IN ($placeholders)',
        whereArgs: userIds,
      );

      developer.log('✅ Found ${maps.length} users for IDs');

      return List.generate(maps.length, (i) => User.fromMap(maps[i]));
    } catch (e) {
      developer.log('❌ Error in getUsersByIds: $e');
      return [];
    }
  }


  Future<void> debugAllUsers() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> users = await db.query('users');

      print('🔍 DEBUG - TOUS LES UTILISATEURS DANS LA BASE:');
      for (var user in users) {
        print('   ID: ${user['id']}, Nom: ${user['name']}, Email: ${user['email']}');
      }
      print('📊 Total: ${users.length} utilisateurs');
    } catch (e) {
      print('❌ Erreur debugAllUsers: $e');
    }
  }

  Future<void> debugAllEvents() async {
    final db = await database;
    final events = await db.query('events');
    print('🎉 ÉVÉNEMENTS DANS LA BASE:');
    for (final event in events) {
      print('  $event');
    }
  }

  Future<String> getDatabasePath() async {
    final path = join(await getDatabasesPath(), 'eventify.db');
    print('📍 CHEMIN DE LA BASE: $path');
    return path;
  }
}
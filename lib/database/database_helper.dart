import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/user.dart';
import '../models/reservation.dart';

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
      version: 2, // Incrémenté pour la nouvelle table
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    developer.log('🔧 Creating tables...');

    await db.execute('''
    CREATE TABLE users(
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

    await db.execute('''
    CREATE TABLE reservations(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      reservation_date TEXT NOT NULL,
      number_of_people INTEGER NOT NULL,
      status TEXT DEFAULT 'pending',
      notes TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
  ''');

    developer.log('✅ Table reservations created successfully');

    // Insérer un utilisateur de test
    await db.insert('users', {
      'name': 'Oumayma Ben Ahmed',
      'email': 'oumayma@eventify.com',
      'phone': '+216 12 345 678',
      'password': 'password123',
      'joinDate': DateTime.now().toIso8601String(), // Correct
      'bio': 'Passionnée d\'événements et de voyages',
      'location': 'Tunis, Tunisia',
      'isActive': 1,
      // 'birthDate' est manquant, mais c'est OK car il peut être NULL.
    });


    developer.log('👤 Test user inserted');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    developer.log('🔄 Upgrading database from v$oldVersion to v$newVersion');
    
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS reservations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          event_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          reservation_date TEXT NOT NULL,
          number_of_people INTEGER NOT NULL,
          status TEXT DEFAULT 'pending',
          notes TEXT,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      ''');
      developer.log('✅ Reservations table created');
    }
  }

  // CRUD Operations
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

  Future<void> resetDatabase() async {
    final db = await database;
    await db.close();
    _database = null;

    String path = join(await getDatabasesPath(), 'eventify.db');
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
      developer.log('🗑️ Database deleted');
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

// 👥 Méthode pour afficher tous les utilisateurs
  Future<void> debugAllUsers() async {
    final db = await database;
    final users = await db.query('users');
    print('👥 UTILISATEURS DANS LA BASE:');
    for (final user in users) {
      print('  $user');
    }
  }

// 📍 Méthode pour obtenir le chemin de la base
  Future<String> getDatabasePath() async {
    final path = join(await getDatabasesPath(), 'eventify.db');
    print('📍 CHEMIN DE LA BASE: $path');
    return path;
  }

  // ==================== RESERVATIONS CRUD ====================

  // Créer une réservation
  Future<int> createReservation(Reservation reservation) async {
    final db = await database;
    developer.log('➕ Creating reservation for event ${reservation.event_id}');
    return await db.insert('reservations', reservation.toMap());
  }

  // Obtenir toutes les réservations
  Future<List<Reservation>> getAllReservations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reservations');
    developer.log('📋 Retrieved ${maps.length} reservations');
    return List.generate(maps.length, (i) => Reservation.fromMap(maps[i]));
  }

  // Obtenir les réservations d'un utilisateur
  Future<List<Reservation>> getUserReservations(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reservations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'reservation_date DESC',
    );
    developer.log('📋 Retrieved ${maps.length} reservations for user $userId');
    return List.generate(maps.length, (i) => Reservation.fromMap(maps[i]));
  }

  // Obtenir les réservations d'un événement
  Future<List<Reservation>> getEventReservations(int eventId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reservations',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    developer.log('📋 Retrieved ${maps.length} reservations for event $eventId');
    return List.generate(maps.length, (i) => Reservation.fromMap(maps[i]));
  }

  // Obtenir une réservation par ID
  Future<Reservation?> getReservationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'reservations',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    
    if (maps.isEmpty) {
      developer.log('❌ No reservation found with id: $id');
      return null;
    }
    
    developer.log('✅ Reservation found: $id');
    return Reservation.fromMap(maps.first);
  }

  // Mettre à jour une réservation
  Future<int> updateReservation(Reservation reservation) async {
    final db = await database;
    developer.log('🔄 Updating reservation ${reservation.id}');
    return await db.update(
      'reservations',
      reservation.toMap(),
      where: 'id = ?',
      whereArgs: [reservation.id],
    );
  }

  // Supprimer une réservation
  Future<int> deleteReservation(int id) async {
    final db = await database;
    developer.log('🗑️ Deleting reservation $id');
    return await db.delete(
      'reservations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Mettre à jour le statut d'une réservation
  Future<int> updateReservationStatus(int id, String status) async {
    final db = await database;
    developer.log('🔄 Updating reservation $id status to $status');
    return await db.update(
      'reservations',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Compter les réservations par statut pour un utilisateur
  Future<Map<String, int>> getUserReservationStats(int userId) async {
    final db = await database;
    final pending = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM reservations WHERE user_id = ? AND status = ?',
        [userId, 'pending'],
      ),
    ) ?? 0;

    final confirmed = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM reservations WHERE user_id = ? AND status = ?',
        [userId, 'confirmed'],
      ),
    ) ?? 0;

    final cancelled = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM reservations WHERE user_id = ? AND status = ?',
        [userId, 'cancelled'],
      ),
    ) ?? 0;

    return {
      'pending': pending,
      'confirmed': confirmed,
      'cancelled': cancelled,
      'total': pending + confirmed + cancelled,
    };
  }
}
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:developer' as developer;
import '../models/reclamation.dart';
import '../models/reservation.dart';
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
      version: 10, // Version augmentée pour les tables album
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

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
    if (oldVersion < 11) {
      try {
        await db.execute('ALTER TABLE events ADD COLUMN price REAL');
        developer.log('✅ Added price column to events table');
      } catch (e) {
        developer.log('ℹ️ Column price might already exist: $e');
      }
    }

    if (oldVersion < 10) {
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
    if (oldVersion < 9) { // or whatever your current version is
      try {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS reclamations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          imagePath TEXT,
          createdAt TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'pending',
          userId INTEGER,
          reponseAdmin TEXT,
          FOREIGN KEY (userId) REFERENCES users (id)
        )
      ''');
        developer.log('✅ Reclamations table created during upgrade');
      } catch (e) {
        developer.log('❌ Error creating reclamations table: $e');
      }
    }

    if (oldVersion < 3) {
      // Créer les tables pour le module album
      try {



        // Create photos table for album module
        await db.execute('''
        CREATE TABLE photos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          url TEXT NOT NULL,
          legend TEXT,
          user TEXT,
          likes INTEGER DEFAULT 0,
          comments INTEGER DEFAULT 0,
          createdAt TEXT,
          event_id INTEGER
        )
        ''');
        developer.log('✅ Table photos created successfully');




        await db.execute('''
        CREATE TABLE IF NOT EXISTS photo_likes(
          photo_id INTEGER NOT NULL,
          user_id INTEGER NOT NULL,
          PRIMARY KEY (photo_id, user_id),
          FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
        ''');
        developer.log('✅ Table photo_likes created successfully');

        // Comments table
        await db.execute('''
        CREATE TABLE IF NOT EXISTS comments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          photoId INTEGER NOT NULL,
          user TEXT,
          text TEXT NOT NULL,
          createdAt TEXT
        )
        ''');
        developer.log('✅ Table comments created successfully');
      } catch (e) {
        developer.log('❌ Error creating album tables: $e');
        rethrow;
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

    // Create reclamations table
    await db.execute('''
      CREATE TABLE reclamations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        imagePath TEXT,
        createdAt TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        userId INTEGER,
        reponseAdmin TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    developer.log('✅ Table reclamations created successfully');

    // Photo likes table to track which user liked which photo (for toggling)
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

    // Create photos table for album module
    await db.execute('''
    CREATE TABLE IF NOT EXISTS photos(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      url TEXT NOT NULL,
      legend TEXT,
      user TEXT,
      likes INTEGER DEFAULT 0,
      comments INTEGER DEFAULT 0,
      createdAt TEXT,
      event_id INTEGER
    )
    ''');
    developer.log('✅ Table photos created successfully');

    // Photo likes table to track which user liked which photo (for toggling)
    await db.execute('''
    CREATE TABLE IF NOT EXISTS photo_likes(
      photo_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      PRIMARY KEY (photo_id, user_id),
      FOREIGN KEY (photo_id) REFERENCES photos(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )
    ''');
    developer.log('✅ Table photo_likes created successfully');

    // Comments table
    await db.execute('''
    CREATE TABLE IF NOT EXISTS comments(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      photoId INTEGER NOT NULL,
      user TEXT,
      text TEXT NOT NULL,
      createdAt TEXT
    )
    ''');
    developer.log('✅ Table comments created successfully');

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

  // ============ ALBUM MODULE OPERATIONS ============

  // --- Photos CRUD ---
  Future<int> insertPhoto(Map<String, dynamic> photo) async {
    final db = await database;
    developer.log('➕ Inserting photo for event: ${photo['event_id']}');
    return await db.insert('photos', photo);
  }

  Future<List<Map<String, dynamic>>> getPhotosByEventId(int eventId) async {
    final db = await database;
    return await db.query('photos',
        where: 'event_id = ?',
        whereArgs: [eventId],
        orderBy: 'createdAt DESC'
    );
  }

  Future<List<Map<String, dynamic>>> getAllPhotos() async {
    final db = await database;
    return await db.query('photos', orderBy: 'createdAt DESC');
  }

// In DatabaseHelper class - CORRECTED VERSION
  Future<int> updatePhoto(int photoId, Map<String, dynamic> photoData) async {
    final db = await database;
    return await db.update(
      'photos',
      photoData,
      where: 'id = ?',
      whereArgs: [photoId],
    );
  }


  Future<Map<String, dynamic>?> getEventById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
  Future<void> unlikePhoto(int photoId, int userId) async {
    final db = await database;
    developer.log('➖ Unliking photo $photoId for user $userId');
    try {
      final deleted = await db.delete('photo_likes', where: 'photo_id = ? AND user_id = ?', whereArgs: [photoId, userId]);
      developer.log('✅ Deleted $deleted photo_likes rows for $photoId/$userId');
    } catch (e) {
      developer.log('🔴 Failed to delete photo_likes for $photoId/$userId: $e');
      rethrow;
    }

    try {
      final res = await db.rawUpdate('UPDATE photos SET likes = (SELECT COUNT(*) FROM photo_likes WHERE photo_id = ?) WHERE id = ?', [photoId, photoId]);
      developer.log('🔁 Updated photos.likes for photo $photoId (rawUpdate result: $res)');
    } catch (e) {
      developer.log('🔴 Failed to update photos.likes for $photoId: $e');
      rethrow;
    }
  }


  Future<void> likePhoto(int photoId, int userId) async {
    final db = await database;
    developer.log('➕ Liking photo $photoId for user $userId');
    try {
      await db.insert('photo_likes', {'photo_id': photoId, 'user_id': userId});
      developer.log('✅ Inserted photo_likes row for photo $photoId / user $userId');
    } catch (e) {
      // If it's a unique constraint violation, bubble up so caller can decide
      developer.log('🔴 Failed to insert photo_likes for $photoId/$userId: $e');
      rethrow;
    }

    try {
      final res = await db.rawUpdate('UPDATE photos SET likes = (SELECT COUNT(*) FROM photo_likes WHERE photo_id = ?) WHERE id = ?', [photoId, photoId]);
      developer.log('🔁 Updated photos.likes for photo $photoId (rawUpdate result: $res)');
    } catch (e) {
      developer.log('🔴 Failed to update photos.likes for $photoId: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPhotosRaw({int? eventId}) async {
    final db = await database;
    if (eventId != null) {
      return await db.query('photos',
          where: 'event_id = ?',
          whereArgs: [eventId],
          orderBy: 'createdAt DESC'
      );
    }
    return await db.query('photos', orderBy: 'createdAt DESC');
  }
  // --- Photo likes helpers ---
  Future<List<int>> getLikedPhotoIdsForUser(int userId) async {
    final db = await database;
    try {
      developer.log('🔍 Fetching liked photo ids for user $userId');
      final rows = await db.query('photo_likes', where: 'user_id = ?', whereArgs: [userId]);
      final ids = rows.map<int>((r) => r['photo_id'] as int).toList();
      developer.log('✅ Found liked photo ids: $ids');
      return ids;
    } catch (e) {
      developer.log('🔴 Failed to fetch liked ids for user $userId: $e');
      rethrow;
    }
  }
  Future<int> updateComment(int id, Map<String, dynamic> values) async {
    final db = await database;
    return await db.update('comments', values, where: 'id = ?', whereArgs: [id]);
  }


  Future<Map<String, dynamic>?> getPhotoById(int id) async {
    final db = await database;
    final rows = await db.query('photos', where: 'id = ?', whereArgs: [id]);
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<int> deletePhoto(int photoId) async {
    final db = await database;
    return await db.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  // --- Photo Likes Management ---
  Future<bool> togglePhotoLike(int photoId, int userId) async {
    final db = await database;

    // Check if like exists
    final existingLikes = await db.query(
      'photo_likes',
      where: 'photo_id = ? AND user_id = ?',
      whereArgs: [photoId, userId],
    );

    if (existingLikes.isEmpty) {
      // Add like
      await db.insert('photo_likes', {
        'photo_id': photoId,
        'user_id': userId,
      });
      await db.rawUpdate('UPDATE photos SET likes = likes + 1 WHERE id = ?', [photoId]);
      developer.log('✅ Like added for photo $photoId by user $userId');
      return true;
    } else {
      // Remove like
      await db.delete(
        'photo_likes',
        where: 'photo_id = ? AND user_id = ?',
        whereArgs: [photoId, userId],
      );
      await db.rawUpdate('UPDATE photos SET likes = likes - 1 WHERE id = ?', [photoId]);
      developer.log('✅ Like removed for photo $photoId by user $userId');
      return false;
    }
  }

  Future<bool> isPhotoLikedByUser(int photoId, int userId) async {
    final db = await database;
    final likes = await db.query(
      'photo_likes',
      where: 'photo_id = ? AND user_id = ?',
      whereArgs: [photoId, userId],
    );
    return likes.isNotEmpty;
  }

  Future<int> getPhotoLikesCount(int photoId) async {
    final db = await database;
    final result = await db.rawQuery('SELECT likes FROM photos WHERE id = ?', [photoId]);
    return result.isNotEmpty ? result.first['likes'] as int : 0;
  }

  // --- Comments CRUD ---
  Future<int> insertComment(Map<String, dynamic> comment) async {
    final db = await database;
    final id = await db.insert('comments', comment);

    // Update photo comment count
    final int photoId = comment['photoId'] as int;
    await db.rawUpdate('UPDATE photos SET comments = (SELECT COUNT(*) FROM comments WHERE photoId = ?) WHERE id = ?', [photoId, photoId]);

    return id;
  }

  Future<List<Map<String, dynamic>>> getCommentsByPhotoId(int photoId) async {
    final db = await database;
    return await db.query('comments', where: 'photoId = ?', whereArgs: [photoId], orderBy: 'createdAt DESC');
  }

  Future<int> deleteComment(int id) async {
    final db = await database;
    // Optionally update photo comments count after deletion
    final rows = await db.query('comments', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return 0;
    final photoId = rows.first['photoId'] as int;
    final res = await db.delete('comments', where: 'id = ?', whereArgs: [id]);
    await db.rawUpdate('UPDATE photos SET comments = (SELECT COUNT(*) FROM comments WHERE photoId = ?) WHERE id = ?', [photoId, photoId]);
    return res;
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

  Future<void> debugAllPhotos() async {
    final db = await database;
    final photos = await db.query('photos');
    print('📸 PHOTOS DANS LA BASE:');
    for (final photo in photos) {
      print('  $photo');
    }
  }

  Future<String> getDatabasePath() async {
    final path = join(await getDatabasesPath(), 'eventify.db');
    print('📍 CHEMIN DE LA BASE: $path');
    return path;
  }

  /********** Syrine Related ************/
  Future<List<Map<String, dynamic>>> getAllEvents() async {
    final db = await database;
    return await db.query('events', orderBy: 'date DESC');
  }


  // ==================== RECLAMATIONS CRUD ====================

  /// Insert a new reclamation
  Future<int> insertReclamation(Reclamation reclamation) async {
    final db = await database;
    developer.log('➕ Inserting reclamation: ${reclamation.title}');
    return await db.insert('reclamations', reclamation.toMap());
  }

  /// Get a reclamation by ID
  Future<Reclamation?> getReclamationById(int id) async {
    final db = await database;
    developer.log('🔍 Searching reclamation by ID: $id');

    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Reclamation.fromMap(maps.first);
    }
    return null;
  }

  /// Get all reclamations
  Future<List<Reclamation>> getAllReclamations() async {
    final db = await database;
    developer.log('📋 Getting all reclamations');

    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => Reclamation.fromMap(maps[i]));
  }

  /// Get reclamations by status
  Future<List<Reclamation>> getReclamationsByStatus(String status) async {
    final db = await database;
    developer.log('📋 Getting reclamations with status: $status');

    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => Reclamation.fromMap(maps[i]));
  }

  /// Get reclamations by user
  Future<List<Reclamation>> getReclamationsByUserId(int userId) async {
    final db = await database;
    developer.log('📋 Getting reclamations for user: $userId');

    final List<Map<String, dynamic>> maps = await db.query(
      'reclamations',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => Reclamation.fromMap(maps[i]));
  }

  /// Update a reclamation
  Future<int> updateReclamation(Reclamation reclamation) async {
    final db = await database;
    developer.log('✏️ Updating reclamation: ${reclamation.id} - ${reclamation.title}');

    return await db.update(
      'reclamations',
      reclamation.toMap(),
      where: 'id = ?',
      whereArgs: [reclamation.id],
    );
  }

  /// Update only the status of a reclamation
  Future<int> updateReclamationStatus(int id, String newStatus) async {
    final db = await database;
    developer.log('🔄 Updating reclamation status: $id -> $newStatus');

    return await db.update(
      'reclamations',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a reclamation
  Future<int> deleteReclamation(int id) async {
    final db = await database;
    developer.log('🗑️ Deleting reclamation: $id');

    return await db.delete(
      'reclamations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get count of reclamations by status
  Future<int> getReclamationsCountByStatus(String status) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM reclamations WHERE status = ?',
      [status],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Debug: Display all reclamations
  Future<void> debugAllReclamations() async {
    final db = await database;
    final reclamations = await db.query('reclamations');
    print('📋 RÉCLAMATIONS DANS LA BASE:');
    for (final reclamation in reclamations) {
      print('  $reclamation');
    }
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
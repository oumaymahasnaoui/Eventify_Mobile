// lib/models/event.dart
class Event {
  final int id;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final String category;
  final double? latitude;
  final double? longitude;
  final List<int> participants;
  final int createdBy;
  final DateTime createdAt; // 11 champs au total
  final int maxParticipants; // NOUVEAU CHAMP


  Event({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.category,
    this.latitude,
    this.longitude,
    required this.participants,
    required this.createdBy,
    required this.createdAt,
    required this.maxParticipants, // AJOUTÉ
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'participants': participants.join(','), // Convertir la liste en string
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'maxParticipants': maxParticipants, // AJOUTÉ
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      location: map['location'],
      description: map['description'],
      category: map['category'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      participants: (map['participants'] as String).split(',').where((e) => e.isNotEmpty).map(int.parse).toList(),
      createdBy: map['createdBy'],
      createdAt: DateTime.parse(map['createdAt']),
      maxParticipants: map['maxParticipants'] ?? 0,
    );
  }

  // Pour créer un nouvel événement (sans ID)
  factory Event.createNew({
    required String title,
    required DateTime date,
    required String location,
    required String description,
    required String category,
    double? latitude,
    double? longitude,
    required int createdBy,
    required int maxParticipants,
  }) {
    return Event(
      id: 0, // Sera auto-incrémenté par la base
      title: title,
      date: date,
      location: location,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      participants: [createdBy], // Le créateur est automatiquement participant
      createdBy: createdBy,
      createdAt: DateTime.now(),
      maxParticipants: maxParticipants,
    );

  }
  // Méthode utilitaire pour vérifier si l'événement est complet
  bool get isFull {
    return maxParticipants > 0 && participants.length >= maxParticipants;
  }

  // Vérifie si un utilisateur peut participer
  bool canParticipate(int userId) {
    return !isFull && !participants.contains(userId);
  }
}
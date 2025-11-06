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
  final DateTime createdAt;
  final int maxParticipants;
  final double price; // ✅ NOUVEAU CHAMP

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
    required this.maxParticipants,
    required this.price, // ✅ AJOUTÉ AU CONSTRUCTEUR
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
      'participants': participants.join(','),
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'maxParticipants': maxParticipants,
      'price': price, // ✅ AJOUTÉ
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
      participants: (map['participants'] as String)
          .split(',')
          .where((e) => e.isNotEmpty)
          .map(int.parse)
          .toList(),
      createdBy: map['createdBy'],
      createdAt: DateTime.parse(map['createdAt']),
      maxParticipants: map['maxParticipants'] ?? 0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,    );
  }

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
    required double price, // ✅ AJOUTÉ
  }) {
    return Event(
      id: 0,
      title: title,
      date: date,
      location: location,
      description: description,
      category: category,
      latitude: latitude,
      longitude: longitude,
      participants: [createdBy],
      createdBy: createdBy,
      createdAt: DateTime.now(),
      maxParticipants: maxParticipants,
      price: price, // ✅ AJOUTÉ
    );
  }

  bool get isFull => maxParticipants > 0 && participants.length >= maxParticipants;

  bool canParticipate(int userId) => !isFull && !participants.contains(userId);
}

class Event {
  final int event_id;
  final String title;
  final DateTime date;
  final String location;
  final String description;
  final String category;
  final double? latitude;
  final double? longitude;
  final List<int> participants;
  final double price; // Prix en euros

  Event({
    required this.event_id,
    required this.title,
    required this.date,
    required this.location,
    required this.description,
    required this.category,
    this.latitude,
    this.longitude,
    this.participants = const [],
    required this.price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': event_id,
      'title': title,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'participants': participants.join(','),
      'price': price,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      event_id: map['id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      description: map['description'] as String,
      category: map['category'] as String,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      participants: map['participants'] != null && map['participants'].toString().isNotEmpty
          ? (map['participants'] as String).split(',').map((e) => int.parse(e)).toList()
          : [],
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Event copyWith({
    int? id,
    String? title,
    DateTime? date,
    String? location,
    String? description,
    String? category,
    double? latitude,
    double? longitude,
    List<int>? participants,
    double? price,
  }) {
    return Event(
      event_id: id ?? this.event_id,
      title: title ?? this.title,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      category: category ?? this.category,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      participants: participants ?? this.participants,
      price: price ?? this.price,
    );
  }
}

class Reservation {
  final int? id;
  final int event_id;
  final int userId;
  final DateTime reservationDate;
  final int numberOfPeople;
  final String status; // 'pending', 'confirmed', 'cancelled'
  final String? notes;

  Reservation({
    this.id,
    required this.event_id,
    required this.userId,
    required this.reservationDate,
    required this.numberOfPeople,
    this.status = 'pending',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': event_id,
      'user_id': userId,
      'reservation_date': reservationDate.toIso8601String(),
      'number_of_people': numberOfPeople,
      'status': status,
      'notes': notes,
    };
  }

  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'] as int?,
      event_id: map['event_id'] as int,
      userId: map['user_id'] as int,
      reservationDate: DateTime.parse(map['reservation_date'] as String),
      numberOfPeople: map['number_of_people'] as int,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
    );
  }

  Reservation copyWith({
    int? id,
    int? eventId,
    int? userId,
    DateTime? reservationDate,
    int? numberOfPeople,
    String? status,
    String? notes,
  }) {
    return Reservation(
      id: id ?? this.id,
      event_id: eventId ?? this.event_id,
      userId: userId ?? this.userId,
      reservationDate: reservationDate ?? this.reservationDate,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

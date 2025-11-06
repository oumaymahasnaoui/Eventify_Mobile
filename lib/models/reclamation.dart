class Reclamation {
  final int? id;
  final String title;
  final String description;
  final String? imagePath;
  final DateTime createdAt;
  final String status; // 'pending', 'in_progress', 'resolved', 'rejected'
  final int? userId; // Optional: if you want to link to a user
  final String? reponseAdmin; // Admin response

  Reclamation({
    this.id,
    required this.title,
    required this.description,
    this.imagePath,
    required this.createdAt,
    this.status = 'pending',
    this.userId,
    this.reponseAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'userId': userId,
      'reponseAdmin': reponseAdmin,
    };
  }

  factory Reclamation.fromMap(Map<String, dynamic> map) {
    return Reclamation(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'],
      userId: map['userId'],
      reponseAdmin: map['reponseAdmin'],
    );
  }

  // Get a human-readable time since creation
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  // Get status in French
  String get statusText {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'resolved':
        return 'Résolu';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  // Copy with method for updates
  Reclamation copyWith({
    int? id,
    String? title,
    String? description,
    String? imagePath,
    DateTime? createdAt,
    String? status,
    int? userId,
    String? reponseAdmin,
  }) {
    return Reclamation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      reponseAdmin: reponseAdmin ?? this.reponseAdmin,
    );
  }
}

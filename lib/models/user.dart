class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final DateTime joinDate;
  final DateTime? birthDate;
  final String? bio;
  final String? location;
  final bool isActive;
  final DateTime? lastLogin;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.joinDate,
    this.birthDate,
    this.bio,
    this.location,
    this.isActive = true,
    this.lastLogin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'joinDate': joinDate.toIso8601String(),
      'birthDate': birthDate?.toIso8601String(),
      'bio': bio,
      'location': location,
      'isActive': isActive ? 1 : 0,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      joinDate: DateTime.parse(map['joinDate']),
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      bio: map['bio'],
      location: map['location'],
      isActive: map['isActive'] == 1,
      lastLogin: map['lastLogin'] != null ? DateTime.parse(map['lastLogin']) : null,
    );
  }

  // Méthode pour afficher l'âge
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year - birthDate!.year - (now.isBefore(DateTime(now.year, birthDate!.month, birthDate!.day)) ? 1 : 0);
  }

  // Méthode pour la durée depuis l'inscription
  String get membershipDuration {
    final now = DateTime.now();
    final difference = now.difference(joinDate);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years an${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months mois';
    } else {
      return '${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    }
  }
}
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
  final bool isVerified;
  final String? verificationToken;
  final DateTime? verificationSentAt;

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
    this.isVerified = false,
    this.verificationToken,
    this.verificationSentAt,
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
      'isVerified': isVerified ? 1 : 0,
      'verificationToken': verificationToken,
      'verificationSentAt': verificationSentAt?.toIso8601String(),
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
      isVerified: map['isVerified'] == 1,
      verificationToken: map['verificationToken'],
      verificationSentAt: map['verificationSentAt'] != null
          ? DateTime.parse(map['verificationSentAt'])
          : null,
    );
  }

  // Getters
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return now.year - birthDate!.year - (now.isBefore(DateTime(now.year, birthDate!.month, birthDate!.day)) ? 1 : 0);
  }

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

  // Méthodes de vérification
  User generateVerificationToken() {
    final token = _generateRandomToken();
    return User(
      id: id,
      name: name,
      email: email,
      phone: phone,
      password: password,
      joinDate: joinDate,
      birthDate: birthDate,
      bio: bio,
      location: location,
      isActive: isActive,
      lastLogin: lastLogin,
      isVerified: isVerified,
      verificationToken: token,
      verificationSentAt: DateTime.now(),
    );
  }

  String _generateRandomToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'token_${random.substring(random.length - 8)}';
  }

  bool isVerificationTokenValid() {
    if (verificationSentAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(verificationSentAt!);
    return difference.inHours <= 24;
  }
}
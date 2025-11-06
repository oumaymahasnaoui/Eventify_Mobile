/// Model for Réclamation (Complaint)
class ReclamationModel {
  final int id;
  final String userName;
  final String sujet;
  final String description;
  final ReclamationStatus statut;
  final DateTime date;
  final String? reponseAdmin;

  ReclamationModel({
    required this.id,
    required this.userName,
    required this.sujet,
    required this.description,
    required this.statut,
    required this.date,
    this.reponseAdmin,
  });

  /// Create a copy with updated fields
  ReclamationModel copyWith({
    int? id,
    String? userName,
    String? sujet,
    String? description,
    ReclamationStatus? statut,
    DateTime? date,
    String? reponseAdmin,
  }) {
    return ReclamationModel(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      sujet: sujet ?? this.sujet,
      description: description ?? this.description,
      statut: statut ?? this.statut,
      date: date ?? this.date,
      reponseAdmin: reponseAdmin ?? this.reponseAdmin,
    );
  }
}

/// Status enum for réclamations
enum ReclamationStatus {
  enAttente,  // Waiting
  enCours,    // In Progress
  resolue,    // Resolved
}

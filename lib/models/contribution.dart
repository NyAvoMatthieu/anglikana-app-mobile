class Contribution {
  final int? id;
  final String typeEntite;
  final int entiteId;
  final String action;
  final DateTime? dateContribution;
  final String? statut;
  final String? commentaire;
  final DateTime? dateValidation;
  final int? utilisateurId;
  final int? validateurId;

  Contribution({
    this.id,
    required this.typeEntite,
    required this.entiteId,
    required this.action,
    this.dateContribution,
    this.statut,
    this.commentaire,
    this.dateValidation,
    this.utilisateurId,
    this.validateurId,
  });

  Contribution copyWith({
    int? id,
    String? typeEntite,
    int? entiteId,
    String? action,
    DateTime? dateContribution,
    String? statut,
    String? commentaire,
    DateTime? dateValidation,
    int? utilisateurId,
    int? validateurId,
  }) {
    return Contribution(
      id: id ?? this.id,
      typeEntite: typeEntite ?? this.typeEntite,
      entiteId: entiteId ?? this.entiteId,
      action: action ?? this.action,
      dateContribution: dateContribution ?? this.dateContribution,
      statut: statut ?? this.statut,
      commentaire: commentaire ?? this.commentaire,
      dateValidation: dateValidation ?? this.dateValidation,
      utilisateurId: utilisateurId ?? this.utilisateurId,
      validateurId: validateurId ?? this.validateurId,
    );
  }

  factory Contribution.fromJson(Map<String, dynamic> json) {
    return Contribution(
      id: json['id'] as int?,
      typeEntite: json['type_entite'] as String,
      entiteId: json['entite_id'] as int,
      action: json['action'] as String,
      dateContribution: json['date_contribution'] != null
          ? DateTime.parse(json['date_contribution'] as String)
          : null,
      statut: json['statut'] as String?,
      commentaire: json['commentaire'] as String?,
      dateValidation: json['date_validation'] != null
          ? DateTime.parse(json['date_validation'] as String)
          : null,
      utilisateurId: json['utilisateur_id'] as int?,
      validateurId: json['validateur_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type_entite': typeEntite,
      'entite_id': entiteId,
      'action': action,
      'date_contribution': dateContribution?.toIso8601String(),
      'statut': statut,
      'commentaire': commentaire,
      'date_validation': dateValidation?.toIso8601String(),
      'utilisateur_id': utilisateurId,
      'validateur_id': validateurId,
    };
  }

  @override
  String toString() =>
      'Contribution(id: $id, typeEntite: $typeEntite, entiteId: $entiteId, action: $action, '
      'dateContribution: $dateContribution, statut: $statut, commentaire: $commentaire, '
      'dateValidation: $dateValidation, utilisateurId: $utilisateurId, validateurId: $validateurId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contribution &&
        other.id == id &&
        other.typeEntite == typeEntite &&
        other.entiteId == entiteId &&
        other.action == action &&
        other.dateContribution == dateContribution &&
        other.statut == statut &&
        other.commentaire == commentaire &&
        other.dateValidation == dateValidation &&
        other.utilisateurId == utilisateurId &&
        other.validateurId == validateurId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        typeEntite,
        entiteId,
        action,
        dateContribution,
        statut,
        commentaire,
        dateValidation,
        utilisateurId,
        validateurId,
      );
}

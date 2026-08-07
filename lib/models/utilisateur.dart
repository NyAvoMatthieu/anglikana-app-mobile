class Utilisateur {
  final int? id;
  final String nomUtilisateur;
  final String motDePasse;
  final bool actif;
  final int? clergeId;

  Utilisateur({
    this.id,
    required this.nomUtilisateur,
    required this.motDePasse,
    this.actif = true,
    this.clergeId,
  });

  Utilisateur copyWith({
    int? id,
    String? nomUtilisateur,
    String? motDePasse,
    bool? actif,
    int? clergeId,
  }) {
    return Utilisateur(
      id: id ?? this.id,
      nomUtilisateur: nomUtilisateur ?? this.nomUtilisateur,
      motDePasse: motDePasse ?? this.motDePasse,
      actif: actif ?? this.actif,
      clergeId: clergeId ?? this.clergeId,
    );
  }

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'] as int?,
      nomUtilisateur: json['nom_utilisateur'] as String,
      motDePasse: json['mot_de_passe'] as String,
      actif: json['actif'] as bool? ?? true,
      clergeId: json['clerge_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom_utilisateur': nomUtilisateur,
      'mot_de_passe': motDePasse,
      'actif': actif,
      'clerge_id': clergeId,
    };
  }

  @override
  String toString() =>
      'Utilisateur(id: $id, nomUtilisateur: $nomUtilisateur, actif: $actif, '
      'clergeId: $clergeId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Utilisateur &&
        other.id == id &&
        other.nomUtilisateur == nomUtilisateur &&
        other.motDePasse == motDePasse &&
        other.actif == actif &&
        other.clergeId == clergeId;
  }

  @override
  int get hashCode =>
      Object.hash(id, nomUtilisateur, motDePasse, actif, clergeId);
}

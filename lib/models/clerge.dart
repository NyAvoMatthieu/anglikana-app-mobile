class Clerge {
  final int? id;
  final String nom;
  final String prenom;
  final DateTime? dateNaissance;
  final String? hierarchie;
  final String? telephone;
  final String? email;
  final int? roleId;

  Clerge({
    this.id,
    required this.nom,
    required this.prenom,
    this.dateNaissance,
    this.hierarchie,
    this.telephone,
    this.email,
    this.roleId,
  });

  Clerge copyWith({
    int? id,
    String? nom,
    String? prenom,
    DateTime? dateNaissance,
    String? hierarchie,
    String? telephone,
    String? email,
    int? roleId,
  }) {
    return Clerge(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      hierarchie: hierarchie ?? this.hierarchie,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      roleId: roleId ?? this.roleId,
    );
  }

  factory Clerge.fromJson(Map<String, dynamic> json) {
    return Clerge(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      prenom: json['prenom'] as String,
      dateNaissance: json['date_naissance'] != null
          ? DateTime.parse(json['date_naissance'] as String)
          : null,
      hierarchie: json['hierarchie'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      roleId: json['role_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'date_naissance': dateNaissance?.toIso8601String(),
      'hierarchie': hierarchie,
      'telephone': telephone,
      'email': email,
      'role_id': roleId,
    };
  }

  @override
  String toString() =>
      'Clerge(id: $id, nom: $nom, prenom: $prenom, dateNaissance: $dateNaissance, '
      'hierarchie: $hierarchie, telephone: $telephone, email: $email, roleId: $roleId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Clerge &&
        other.id == id &&
        other.nom == nom &&
        other.prenom == prenom &&
        other.dateNaissance == dateNaissance &&
        other.hierarchie == hierarchie &&
        other.telephone == telephone &&
        other.email == email &&
        other.roleId == roleId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        prenom,
        dateNaissance,
        hierarchie,
        telephone,
        email,
        roleId,
      );
}

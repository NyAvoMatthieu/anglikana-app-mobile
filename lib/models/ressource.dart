class Ressource {
  final int? id;
  final String nom;
  final String? adresse;
  final String? localisation;
  final int? typeId;
  final int? egliseId;
  final int? responsableId;

  Ressource({
    this.id,
    required this.nom,
    this.adresse,
    this.localisation,
    this.typeId,
    this.egliseId,
    this.responsableId,
  });

  Ressource copyWith({
    int? id,
    String? nom,
    String? adresse,
    String? localisation,
    int? typeId,
    int? egliseId,
    int? responsableId,
  }) {
    return Ressource(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      localisation: localisation ?? this.localisation,
      typeId: typeId ?? this.typeId,
      egliseId: egliseId ?? this.egliseId,
      responsableId: responsableId ?? this.responsableId,
    );
  }

  factory Ressource.fromJson(Map<String, dynamic> json) {
    return Ressource(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      adresse: json['adresse'] as String?,
      localisation: json['localisation'] as String?,
      typeId: json['type_id'] as int?,
      egliseId: json['eglise_id'] as int?,
      responsableId: json['responsable_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'localisation': localisation,
      'type_id': typeId,
      'eglise_id': egliseId,
      'responsable_id': responsableId,
    };
  }

  @override
  String toString() =>
      'Ressource(id: $id, nom: $nom, adresse: $adresse, localisation: $localisation, '
      'typeId: $typeId, egliseId: $egliseId, responsableId: $responsableId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Ressource &&
        other.id == id &&
        other.nom == nom &&
        other.adresse == adresse &&
        other.localisation == localisation &&
        other.typeId == typeId &&
        other.egliseId == egliseId &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        adresse,
        localisation,
        typeId,
        egliseId,
        responsableId,
      );
}

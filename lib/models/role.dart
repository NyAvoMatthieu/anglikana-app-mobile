class Role {
  final int? id;
  final String nom;
  final int niveau;
  final String? description;

  Role({
    this.id,
    required this.nom,
    required this.niveau,
    this.description,
  });

  Role copyWith({
    int? id,
    String? nom,
    int? niveau,
    String? description,
  }) {
    return Role(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      niveau: niveau ?? this.niveau,
      description: description ?? this.description,
    );
  }

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      niveau: json['niveau'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'niveau': niveau,
      'description': description,
    };
  }

  @override
  String toString() =>
      'Role(id: $id, nom: $nom, niveau: $niveau, description: $description)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Role &&
        other.id == id &&
        other.nom == nom &&
        other.niveau == niveau &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, nom, niveau, description);
}

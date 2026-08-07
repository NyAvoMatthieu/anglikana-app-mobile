class TypeRessource {
  final int? id;
  final String nom;

  TypeRessource({
    this.id,
    required this.nom,
  });

  TypeRessource copyWith({
    int? id,
    String? nom,
  }) {
    return TypeRessource(
      id: id ?? this.id,
      nom: nom ?? this.nom,
    );
  }

  factory TypeRessource.fromJson(Map<String, dynamic> json) {
    return TypeRessource(
      id: json['id'] as int?,
      nom: json['nom'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
    };
  }

  @override
  String toString() => 'TypeRessource(id: $id, nom: $nom)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TypeRessource && other.id == id && other.nom == nom;
  }

  @override
  int get hashCode => Object.hash(id, nom);
}

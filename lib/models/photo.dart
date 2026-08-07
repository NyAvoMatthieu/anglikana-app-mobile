class Photo {
  final int? id;
  final String url;
  final String? description;
  final DateTime? dateAjout;
  final String typeEntite;
  final int entiteId;

  Photo({
    this.id,
    required this.url,
    this.description,
    this.dateAjout,
    required this.typeEntite,
    required this.entiteId,
  });

  Photo copyWith({
    int? id,
    String? url,
    String? description,
    DateTime? dateAjout,
    String? typeEntite,
    int? entiteId,
  }) {
    return Photo(
      id: id ?? this.id,
      url: url ?? this.url,
      description: description ?? this.description,
      dateAjout: dateAjout ?? this.dateAjout,
      typeEntite: typeEntite ?? this.typeEntite,
      entiteId: entiteId ?? this.entiteId,
    );
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as int?,
      url: json['url'] as String,
      description: json['description'] as String?,
      dateAjout: json['date_ajout'] != null
          ? DateTime.parse(json['date_ajout'] as String)
          : null,
      typeEntite: json['type_entite'] as String,
      entiteId: json['entite_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'description': description,
      'date_ajout': dateAjout?.toIso8601String(),
      'type_entite': typeEntite,
      'entite_id': entiteId,
    };
  }

  @override
  String toString() =>
      'Photo(id: $id, url: $url, description: $description, dateAjout: $dateAjout, '
      'typeEntite: $typeEntite, entiteId: $entiteId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Photo &&
        other.id == id &&
        other.url == url &&
        other.description == description &&
        other.dateAjout == dateAjout &&
        other.typeEntite == typeEntite &&
        other.entiteId == entiteId;
  }

  @override
  int get hashCode =>
      Object.hash(id, url, description, dateAjout, typeEntite, entiteId);
}

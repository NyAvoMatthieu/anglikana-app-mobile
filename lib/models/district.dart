import 'paroisse.dart';

class District {
  final int? id;
  final String nom;
  final String? carteQgis;
  final int? regionId;
  final int? responsableId;
  final List<Paroisse>? paroisses;

  District({
    this.id,
    required this.nom,
    this.carteQgis,
    this.regionId,
    this.responsableId,
    this.paroisses,
  });

  District copyWith({
    int? id,
    String? nom,
    String? carteQgis,
    int? regionId,
    int? responsableId,
    List<Paroisse>? paroisses,
  }) {
    return District(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      carteQgis: carteQgis ?? this.carteQgis,
      regionId: regionId ?? this.regionId,
      responsableId: responsableId ?? this.responsableId,
      paroisses: paroisses ?? this.paroisses,
    );
  }

  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      carteQgis: json['carte_qgis'] as String?,
      regionId: json['region_id'] as int?,
      responsableId: json['responsable_id'] as int?,
      paroisses: json['paroisses'] != null
          ? (json['paroisses'] as List)
              .map((e) => Paroisse.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'carte_qgis': carteQgis,
      'region_id': regionId,
      'responsable_id': responsableId,
      if (paroisses != null)
        'paroisses': paroisses!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'District(id: $id, nom: $nom, carteQgis: $carteQgis, regionId: $regionId, '
      'responsableId: $responsableId, paroisses: $paroisses)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is District &&
        other.id == id &&
        other.nom == nom &&
        other.carteQgis == carteQgis &&
        other.regionId == regionId &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode =>
      Object.hash(id, nom, carteQgis, regionId, responsableId);
}

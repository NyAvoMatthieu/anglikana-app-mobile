import 'region.dart';

class Diocese {
  final int? id;
  final String nom;
  final String? carteQgis;
  final String? presentation;
  final String? coordonnees;
  final int? responsableId;
  final List<Region>? regions;

  Diocese({
    this.id,
    required this.nom,
    this.carteQgis,
    this.presentation,
    this.coordonnees,
    this.responsableId,
    this.regions,
  });

  Diocese copyWith({
    int? id,
    String? nom,
    String? carteQgis,
    String? presentation,
    String? coordonnees,
    int? responsableId,
    List<Region>? regions,
  }) {
    return Diocese(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      carteQgis: carteQgis ?? this.carteQgis,
      presentation: presentation ?? this.presentation,
      coordonnees: coordonnees ?? this.coordonnees,
      responsableId: responsableId ?? this.responsableId,
      regions: regions ?? this.regions,
    );
  }

  factory Diocese.fromJson(Map<String, dynamic> json) {
    return Diocese(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      carteQgis: json['carte_qgis'] as String?,
      presentation: json['presentation'] as String?,
      coordonnees: json['coordonnees'] as String?,
      responsableId: json['responsable_id'] as int?,
      regions: json['regions'] != null
          ? (json['regions'] as List)
              .map((e) => Region.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'carte_qgis': carteQgis,
      'presentation': presentation,
      'coordonnees': coordonnees,
      'responsable_id': responsableId,
      if (regions != null) 'regions': regions!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Diocese(id: $id, nom: $nom, carteQgis: $carteQgis, presentation: $presentation, '
      'coordonnees: $coordonnees, responsableId: $responsableId, regions: $regions)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Diocese &&
        other.id == id &&
        other.nom == nom &&
        other.carteQgis == carteQgis &&
        other.presentation == presentation &&
        other.coordonnees == coordonnees &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        carteQgis,
        presentation,
        coordonnees,
        responsableId,
      );
}

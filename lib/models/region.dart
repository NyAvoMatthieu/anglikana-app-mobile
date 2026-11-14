import 'district.dart';

class Region {
  final int? id;
  final String nom;
  final String? carteQgis;
  final int? dioceseId;
  final int? responsableId;
  final List<District>? districts;

  Region({
    this.id,
    required this.nom,
    this.carteQgis,
    this.dioceseId,
    this.responsableId,
    this.districts,
  });

  Region copyWith({
    int? id,
    String? nom,
    String? carteQgis,
    int? dioceseId,
    int? responsableId,
    List<District>? districts,
  }) {
    return Region(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      carteQgis: carteQgis ?? this.carteQgis,
      dioceseId: dioceseId ?? this.dioceseId,
      responsableId: responsableId ?? this.responsableId,
      districts: districts ?? this.districts,
    );
  }

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      carteQgis: json['carte_qgis'] as String?,
      dioceseId: json['diocese_id'] as int?,
      responsableId: json['responsable_id'] as int?,
      districts: json['districts'] != null
          ? (json['districts'] as List)
                .map((e) => District.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'carte_qgis': carteQgis,
      'diocese_id': dioceseId,
      'responsable_id': responsableId,
      if (districts != null)
        'districts': districts!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Region(id: $id, nom: $nom, carteQgis: $carteQgis, dioceseId: $dioceseId, '
      'responsableId: $responsableId, districts: $districts)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Region &&
        other.id == id &&
        other.nom == nom &&
        other.carteQgis == carteQgis &&
        other.dioceseId == dioceseId &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode => Object.hash(id, nom, carteQgis, dioceseId, responsableId);
}

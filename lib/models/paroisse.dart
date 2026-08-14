import 'eglise.dart';

class Paroisse {
  final int? id;
  final String nom;
  final String? carteQgis;
  final int? districtId;
  final int? responsableId;
  final List<Eglise>? eglises;

  Paroisse({
    this.id,
    required this.nom,
    this.carteQgis,
    this.districtId,
    this.responsableId,
    this.eglises,
  });

  Paroisse copyWith({
    int? id,
    String? nom,
    String? carteQgis,
    int? districtId,
    int? responsableId,
    List<Eglise>? eglises,
  }) {
    return Paroisse(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      carteQgis: carteQgis ?? this.carteQgis,
      districtId: districtId ?? this.districtId,
      responsableId: responsableId ?? this.responsableId,
      eglises: eglises ?? this.eglises,
    );
  }

  factory Paroisse.fromJson(Map<String, dynamic> json) {
    return Paroisse(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      carteQgis: json['carte_qgis'] as String?,
      districtId: json['district_id'] as int?,
      responsableId: json['responsable_id'] as int?,
      eglises: json['eglises'] != null
          ? (json['eglises'] as List)
              .map((e) => Eglise.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'carte_qgis': carteQgis,
      'district_id': districtId,
      'responsable_id': responsableId,
      if (eglises != null) 'eglises': eglises!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Paroisse(id: $id, nom: $nom, carteQgis: $carteQgis, districtId: $districtId, '
      'responsableId: $responsableId, eglises: $eglises)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Paroisse &&
        other.id == id &&
        other.nom == nom &&
        other.carteQgis == carteQgis &&
        other.districtId == districtId &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode =>
      Object.hash(id, nom, carteQgis, districtId, responsableId);
}

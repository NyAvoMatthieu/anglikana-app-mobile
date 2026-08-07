import 'horaire_culte.dart';
import 'ressource.dart';

class Eglise {
  final int? id;
  final String nom;
  final String? adresse;
  final String? localisation;
  final String? historique;
  final String? lienFacebook;
  final int? paroisseId;
  final int? responsableId;
  final List<HoraireCulte>? horairesCulte;
  final List<Ressource>? ressources;

  Eglise({
    this.id,
    required this.nom,
    this.adresse,
    this.localisation,
    this.historique,
    this.lienFacebook,
    this.paroisseId,
    this.responsableId,
    this.horairesCulte,
    this.ressources,
  });

  Eglise copyWith({
    int? id,
    String? nom,
    String? adresse,
    String? localisation,
    String? historique,
    String? lienFacebook,
    int? paroisseId,
    int? responsableId,
    List<HoraireCulte>? horairesCulte,
    List<Ressource>? ressources,
  }) {
    return Eglise(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      adresse: adresse ?? this.adresse,
      localisation: localisation ?? this.localisation,
      historique: historique ?? this.historique,
      lienFacebook: lienFacebook ?? this.lienFacebook,
      paroisseId: paroisseId ?? this.paroisseId,
      responsableId: responsableId ?? this.responsableId,
      horairesCulte: horairesCulte ?? this.horairesCulte,
      ressources: ressources ?? this.ressources,
    );
  }

  factory Eglise.fromJson(Map<String, dynamic> json) {
    return Eglise(
      id: json['id'] as int?,
      nom: json['nom'] as String,
      adresse: json['adresse'] as String?,
      localisation: json['localisation'] as String?,
      historique: json['historique'] as String?,
      lienFacebook: json['lien_facebook'] as String?,
      paroisseId: json['paroisse_id'] as int?,
      responsableId: json['responsable_id'] as int?,
      horairesCulte: json['horaires_culte'] != null
          ? (json['horaires_culte'] as List)
              .map((e) => HoraireCulte.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      ressources: json['ressources'] != null
          ? (json['ressources'] as List)
              .map((e) => Ressource.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'localisation': localisation,
      'historique': historique,
      'lien_facebook': lienFacebook,
      'paroisse_id': paroisseId,
      'responsable_id': responsableId,
      if (horairesCulte != null)
        'horaires_culte': horairesCulte!.map((e) => e.toJson()).toList(),
      if (ressources != null)
        'ressources': ressources!.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() =>
      'Eglise(id: $id, nom: $nom, adresse: $adresse, localisation: $localisation, '
      'historique: $historique, lienFacebook: $lienFacebook, paroisseId: $paroisseId, '
      'responsableId: $responsableId, horairesCulte: $horairesCulte, ressources: $ressources)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Eglise &&
        other.id == id &&
        other.nom == nom &&
        other.adresse == adresse &&
        other.localisation == localisation &&
        other.historique == historique &&
        other.lienFacebook == lienFacebook &&
        other.paroisseId == paroisseId &&
        other.responsableId == responsableId;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nom,
        adresse,
        localisation,
        historique,
        lienFacebook,
        paroisseId,
        responsableId,
      );
}

class HoraireCulte {
  final int? id;
  final String jour;
  final String? libelle;
  final String debut;
  final String fin;
  final int? egliseId;

  HoraireCulte({
    this.id,
    required this.jour,
    this.libelle,
    required this.debut,
    required this.fin,
    this.egliseId,
  });

  HoraireCulte copyWith({
    int? id,
    String? jour,
    String? libelle,
    String? debut,
    String? fin,
    int? egliseId,
  }) {
    return HoraireCulte(
      id: id ?? this.id,
      jour: jour ?? this.jour,
      libelle: libelle ?? this.libelle,
      debut: debut ?? this.debut,
      fin: fin ?? this.fin,
      egliseId: egliseId ?? this.egliseId,
    );
  }

  factory HoraireCulte.fromJson(Map<String, dynamic> json) {
    return HoraireCulte(
      id: json['id'] as int?,
      jour: json['jour'] as String,
      libelle: json['libelle'] as String?,
      debut: json['debut'] as String,
      fin: json['fin'] as String,
      egliseId: json['eglise_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jour': jour,
      'libelle': libelle,
      'debut': debut,
      'fin': fin,
      'eglise_id': egliseId,
    };
  }

  @override
  String toString() =>
      'HoraireCulte(id: $id, jour: $jour, libelle: $libelle, debut: $debut, '
      'fin: $fin, egliseId: $egliseId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HoraireCulte &&
        other.id == id &&
        other.jour == jour &&
        other.libelle == libelle &&
        other.debut == debut &&
        other.fin == fin &&
        other.egliseId == egliseId;
  }

  @override
  int get hashCode => Object.hash(id, jour, libelle, debut, fin, egliseId);
}

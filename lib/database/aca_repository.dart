import '../models/clerge.dart';
import '../models/clerge_details.dart';
import '../models/diocese.dart';
import '../models/district.dart';
import '../models/eglise.dart';
import '../models/eglise_details.dart';
import '../models/horaire_culte.dart';
import '../models/photo.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import '../models/ressource.dart';
import 'database_helper.dart';

/// Charge les listes à plat depuis SQLite pour alimenter l'UI, ainsi que les
/// détails d'une église avec ses relations horaires et responsable.
class AcaRepository {
  AcaRepository._();

  static Future<List<Diocese>> chargerDioceses() async {
    final lignes = await DatabaseHelper.instance.tout(
      'diocese',
      orderBy: 'nom',
    );
    return lignes.map(Diocese.fromJson).toList();
  }

  static Future<List<Region>> chargerRegions() async {
    final lignes = await DatabaseHelper.instance.tout('region', orderBy: 'nom');
    return lignes.map(Region.fromJson).toList();
  }

  static Future<List<District>> chargerDistricts() async {
    final lignes = await DatabaseHelper.instance.tout(
      'district',
      orderBy: 'nom',
    );
    return lignes.map(District.fromJson).toList();
  }

  static Future<List<Paroisse>> chargerParoisses() async {
    final lignes = await DatabaseHelper.instance.tout(
      'paroisse',
      orderBy: 'nom',
    );
    return lignes.map(Paroisse.fromJson).toList();
  }

  static Future<List<Eglise>> chargerEglises() async {
    final lignes = await DatabaseHelper.instance.tout('eglise', orderBy: 'nom');
    return lignes.map(Eglise.fromJson).toList();
  }

  static const _ordreJours = [
    'lundi',
    'mardi',
    'mercredi',
    'jeudi',
    'vendredi',
    'samedi',
    'dimanche',
  ];

  /// Tri par jour de la semaine (lundi -> dimanche) puis par heure de début ;
  /// un jour inconnu passe en dernier. Le tri SQL « ORDER BY h.jour » ne
  /// donnait que l'ordre alphabétique (Dimanche, Jeudi, Mercredi...).
  static int _comparerHoraires(HoraireCulte a, HoraireCulte b) {
    int rang(String jour) {
      final i = _ordreJours.indexOf(jour.trim().toLowerCase());
      return i < 0 ? _ordreJours.length : i;
    }

    final parJour = rang(a.jour).compareTo(rang(b.jour));
    return parJour != 0 ? parJour : a.debut.compareTo(b.debut);
  }

  static Future<EgliseDetails?> chargerDetailsEglise(int egliseId) async {
    final lignes = await (await DatabaseHelper.instance.database).rawQuery(
      '''
      SELECT
        e.*,
        c.nom AS responsable_nom,
        c.prenom AS responsable_prenom,
        h.id AS horaire_id,
        h.jour AS horaire_jour,
        h.libelle AS horaire_libelle,
        h.debut AS horaire_debut,
        h.fin AS horaire_fin,
        h.eglise_id AS horaire_eglise_id
      FROM eglise e
      LEFT JOIN clerge c ON c.id = e.responsable_id
      LEFT JOIN horaire_culte h ON h.eglise_id = e.id
      WHERE e.id = ?
      ORDER BY h.jour, h.debut
      ''',
      [egliseId],
    );
    if (lignes.isEmpty) return null;

    final premiere = Map<String, dynamic>.from(lignes.first);
    final horaires = lignes
        .where((ligne) => ligne['horaire_id'] != null)
        .map(
          (ligne) => HoraireCulte(
            id: ligne['horaire_id'] as int,
            jour: ligne['horaire_jour'] as String,
            libelle: ligne['horaire_libelle'] as String?,
            debut: ligne['horaire_debut'] as String,
            fin: ligne['horaire_fin'] as String,
            egliseId: ligne['horaire_eglise_id'] as int?,
          ),
        )
        .toList()
      ..sort(_comparerHoraires);
    premiere.removeWhere((key, _) => key.startsWith('horaire_'));

    final responsableNom = [
      premiere.remove('responsable_prenom'),
      premiere.remove('responsable_nom'),
    ].whereType<String>().where((value) => value.isNotEmpty).join(' ');
    final eglise = Eglise.fromJson(premiere);
    final lignesPhotos = await (await DatabaseHelper.instance.database).query(
      'photo',
      where: 'type_entite = ? AND entite_id = ?',
      whereArgs: ['eglise', egliseId],
      orderBy: 'date_ajout DESC, id ASC',
    );
    final photos = lignesPhotos.map(Photo.fromJson).toList();

    return EgliseDetails(
      eglise: eglise,
      responsableNom: responsableNom.isEmpty ? null : responsableNom,
      horaires: horaires,
      photos: photos,
    );
  }

  /// Charge un membre du clergé par son id (null s'il n'existe pas).
  static Future<Clerge?> chargerClerge(int clergeId) async {
    final lignes = await DatabaseHelper.instance.tout(
      'clerge',
      where: 'id = ?',
      whereArgs: [clergeId],
    );
    if (lignes.isEmpty) return null;
    return Clerge.fromJson(lignes.first);
  }

  /// Charge la fiche complète d'un membre du clergé : identité, libellé du
  /// rôle et photos (`type_entite = 'clerge'`).
  static Future<ClergeDetails?> chargerDetailsClerge(int clergeId) async {
    final db = await DatabaseHelper.instance.database;
    final lignes = await db.rawQuery(
      '''
      SELECT c.*, r.nom AS role_nom
      FROM clerge c
      LEFT JOIN role r ON r.id = c.role_id
      WHERE c.id = ?
      ''',
      [clergeId],
    );
    if (lignes.isEmpty) return null;

    final ligne = Map<String, dynamic>.from(lignes.first);
    final roleNom = ligne.remove('role_nom') as String?;
    final lignesPhotos = await db.query(
      'photo',
      where: 'type_entite = ? AND entite_id = ?',
      whereArgs: ['clerge', clergeId],
      orderBy: 'date_ajout DESC, id ASC',
    );
    final lignesEglises = await db.query(
      'eglise',
      where: 'responsable_id = ?',
      whereArgs: [clergeId],
      orderBy: 'nom',
    );
    return ClergeDetails(
      clerge: Clerge.fromJson(ligne),
      roleNom: roleNom,
      photos: lignesPhotos.map(Photo.fromJson).toList(),
      eglises: lignesEglises.map(Eglise.fromJson).toList(),
    );
  }

  static Future<List<Ressource>> chargerRessources() async {
    final lignes = await DatabaseHelper.instance.tout(
      'ressource',
      orderBy: 'nom',
    );
    return lignes.map(Ressource.fromJson).toList();
  }
}

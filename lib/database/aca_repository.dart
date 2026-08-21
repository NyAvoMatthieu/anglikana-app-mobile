import '../models/diocese.dart';
import '../models/district.dart';
import '../models/eglise.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import '../models/ressource.dart';
import 'database_helper.dart';

/// Charge les listes à plat depuis SQLite pour alimenter l'UI (CarteScreen,
/// recherche, filtres). Pas de jointures ni de listes imbriquées : chaque
/// entité est chargée séparément, la mise en relation se fait via les FK
/// côté UI (déjà le fonctionnement de FiltreHierarchieService).
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

  static Future<List<Ressource>> chargerRessources() async {
    final lignes = await DatabaseHelper.instance.tout(
      'ressource',
      orderBy: 'nom',
    );
    return lignes.map(Ressource.fromJson).toList();
  }
}

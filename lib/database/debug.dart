import 'database_helper.dart';

/// Utilitaire de diagnostic TEMPORAIRE : inspecte le contenu réel de la
/// colonne carte_qgis (Diocese, District, Paroisse) pour déterminer son
/// format (WKT ? GeoJSON ? autre chose ?) avant de coder le parsing du
/// polygone dans GeoUtils.
///
/// À supprimer une fois le format confirmé. Pas destiné à rester en
/// production.
class DebugQgis {
  DebugQgis._();

  static const _tables = ['diocese', 'district', 'paroisse'];

  /// Affiche dans la console un résumé de ce que contient carte_qgis pour
  /// chaque table concernée : nombre de lignes non-nulles, longueur,
  /// premiers caractères, et une détection grossière de format.
  static Future<void> inspecter() async {
    final db = DatabaseHelper.instance;

    for (final table in _tables) {
      final lignes = await db.tout(table);
      final avecQgis = lignes.where((l) => l['carte_qgis'] != null).toList();

      // ignore: avoid_print
      print('--- $table : ${avecQgis.length}/${lignes.length} lignes avec carte_qgis non-null ---');

      for (final ligne in avecQgis) {
        final valeur = ligne['carte_qgis'] as String;
        final apercu = valeur.length > 80 ? '${valeur.substring(0, 80)}...' : valeur;
        final format = _detecterFormat(valeur);

        // ignore: avoid_print
        print(
          '  id=${ligne['id']} nom=${ligne['nom']} '
          'longueur=${valeur.length} format~=$format apercu="$apercu"',
        );
      }
    }
  }

  static String _detecterFormat(String valeur) {
    final v = valeur.trim();
    if (v.isEmpty) return 'vide';
    if (v.startsWith('{')) return 'probablement GeoJSON';
    if (v.toUpperCase().startsWith('POLYGON') ||
        v.toUpperCase().startsWith('MULTIPOLYGON')) {
      return 'probablement WKT';
    }
    if (v.startsWith('http://') || v.startsWith('https://')) {
      return 'probablement une URL (pas une géométrie inline)';
    }
    if (v.endsWith('.qgs') || v.endsWith('.geojson') || v.endsWith('.shp')) {
      return 'probablement un chemin/nom de fichier QGIS';
    }
    return 'format non reconnu - inspecter manuellement';
  }
}
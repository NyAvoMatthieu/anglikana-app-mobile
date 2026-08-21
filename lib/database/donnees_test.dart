import '../models/diocese.dart';
import '../models/district.dart';
import '../models/eglise.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import 'database_helper.dart';

/// Insère un petit jeu de données de test (Église Épiscopale Anglicane de
/// Madagascar, région d'Antananarivo) si la base est vide.
///
/// Sert uniquement à vérifier la chaîne complète SQLite -> modèles ->
/// CarteScreen -> recherche/filtre/zoom/cache offline. À retirer (ou à
/// laisser en dev uniquement) une fois le module de synchronisation
/// PostgreSQL en place.
class DonneesTest {
  DonneesTest._();
  static Future<void> insererSiVide() async {
    final db = DatabaseHelper.instance;
    final diocesesExistants = await db.tout('diocese');
    if (diocesesExistants.isNotEmpty) return; // déjà peuplé, ne rien faire
    final dioceseId = await db.inserer(
      'diocese',
      Diocese(
        nom: 'Église Épiscopale Anglicane de Madagascar',
        presentation: 'Données de test',
      ).toJson(),
    );
    final regionId = await db.inserer(
      'region',
      Region(nom: 'Analamanga', dioceseId: dioceseId).toJson(),
    );
    final districtId = await db.inserer(
      'district',
      District(nom: 'District Antananarivo', regionId: regionId).toJson(),
    );
    final paroisseCentreId = await db.inserer(
      'paroisse',
      Paroisse(
        nom: 'Paroisse Antananarivo-Centre',
        districtId: districtId,
      ).toJson(),
    );
    final paroisseAmbatoId = await db.inserer(
      'paroisse',
      Paroisse(nom: 'Paroisse Ambatonakanga', districtId: districtId).toJson(),
    );
    await db.inserer(
      'eglise',
      Eglise(
        nom: 'Cathédrale Anglicane Saint-Laurent',
        adresse: 'Ambohimanga, Antananarivo',
        localisation: 'POINT(47.5563 -18.7614)',
        paroisseId: paroisseCentreId,
      ).toJson(),
    );
    await db.inserer(
      'eglise',
      Eglise(
        nom: 'Église Anglicane Ambatonakanga',
        adresse: 'Ambatonakanga, Antananarivo',
        localisation: 'POINT(47.5250 -18.9089)',
        paroisseId: paroisseAmbatoId,
      ).toJson(),
    );
    await db.inserer(
      'eglise',
      Eglise(
        nom: 'Église Anglicane Faravohitra',
        adresse: 'Faravohitra, Antananarivo',
        localisation: 'POINT(47.5280 -18.9060)',
        paroisseId: paroisseAmbatoId,
      ).toJson(),
    );
  }
}

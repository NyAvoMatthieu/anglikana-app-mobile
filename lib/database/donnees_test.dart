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

  static const _nomDioceseTest = 'Église Épiscopale Anglicane de Madagascar';
  static const _polygoneDioceseTest =
      'POLYGON((45.4 -18.4, 44.60 -18.4, 44.60 -19.4, 45.4 -19.4, 45.4 -18.4))';
  static const _nomEgliseDioceseTest = 'Église Anglicane du Diocèse';
  static const _polygoneDistrictTest =
      'POLYGON((45.0 -19.2, 45.3 -19.2, 45.3 -19.0, 45.0 -19.0, 45.0 -19.2))';
  static const _polygoneRegionTest =
      'POLYGON((44.8 -19.5, 45.5 -19.5, 45.5 -18.5, 44.8 -18.5, 44.8 -19.5))';

  static Future<void> insererSiVide() async {
    final db = DatabaseHelper.instance;
    await (await db.database).update(
      'region',
      {'carte_qgis': _polygoneRegionTest},
      where: 'nom = ?',
      whereArgs: ['Analamanga'],
    );
    final diocesesExistants = await db.tout('diocese');
    if (diocesesExistants.isNotEmpty) {
      final dioceseTest = await db.tout(
        'diocese',
        where: 'nom = ?',
        whereArgs: [_nomDioceseTest],
      );
      if (dioceseTest.isNotEmpty) {
        await (await db.database).update(
          'diocese',
          {'carte_qgis': _polygoneDioceseTest},
          where: 'nom = ?',
          whereArgs: [_nomDioceseTest],
        );
        final paroisse = await db.tout(
          'paroisse',
          where: 'nom = ?',
          whereArgs: ['Paroisse Antananarivo-Centre'],
        );
        if (paroisse.isNotEmpty) {
          await _insererEgliseTestSiAbsente(db, paroisse.first['id'] as int);
        }
        await (await db.database).update(
          'district',
          {'carte_qgis': _polygoneDistrictTest},
          where: 'nom = ?',
          whereArgs: ['District Antananarivo'],
        );
      }
      await _insererDioceseAvecEgliseSiAbsent(
        db,
        nomDiocese: 'Diocèse de Toamasina',
        polygone:
            'POLYGON((49.8 -17.8, 50.8 -17.8, 50.8 -18.8, 49.8 -18.8, 49.8 -17.8))',
        nomRegion: 'Atsinanana',
        polygoneRegion:
            'POLYGON((49.5 -19.0, 51.0 -19.0, 51.0 -17.5, 49.5 -17.5, 49.5 -19.0))',
        nomDistrict: 'District Toamasina',
        polygoneDistrict:
            'POLYGON((50.0 -18.3, 50.4 -18.3, 50.4 -18.0, 50.0 -18.0, 50.0 -18.3))',
        nomParoisse: 'Paroisse Toamasina-Centre',
        nomEglise: 'Église Anglicane de Toamasina',
        localisation: 'POINT(50.2 -18.15)',
      );
      await _insererDioceseAvecEgliseSiAbsent(
        db,
        nomDiocese: 'Diocèse de Fianarantsoa',
        polygone:
            'POLYGON((46.7 -21.0, 47.2 -20.8, 47.7 -21.0, 47.7 -22.0, 47.2 -22.2, 46.7 -22.0, 46.7 -21.0))',
        nomRegion: 'Haute Matsiatra',
        polygoneRegion:
            'POLYGON((46.4 -22.3, 48.0 -22.3, 48.0 -20.7, 46.4 -20.7, 46.4 -22.3))',
        nomDistrict: 'District Fianarantsoa',
        polygoneDistrict:
            'POLYGON((46.9 -21.6, 47.3 -21.6, 47.3 -21.3, 46.9 -21.3, 46.9 -21.6))',
        nomParoisse: 'Paroisse Fianarantsoa-Centre',
        nomEglise: 'Église Anglicane de Fianarantsoa',
        localisation: 'POINT(47.1 -21.45)',
      );
      return;
    }

    final dioceseId = await db.inserer(
      'diocese',
      Diocese(
        nom: _nomDioceseTest,
        carteQgis: _polygoneDioceseTest,
        presentation: 'Données de test',
      ).toJson(),
    );
    final regionId = await db.inserer(
      'region',
      Region(
        nom: 'Analamanga',
        carteQgis: _polygoneRegionTest,
        dioceseId: dioceseId,
      ).toJson(),
    );
    final districtId = await db.inserer(
      'district',
      District(
        nom: 'District Antananarivo',
        carteQgis: _polygoneDistrictTest,
        regionId: regionId,
      ).toJson(),
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
    await _insererEgliseTestSiAbsente(db, paroisseCentreId);
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
    await _insererDioceseAvecEgliseSiAbsent(
      db,
      nomDiocese: 'Diocèse de Toamasina',
      polygone:
          'POLYGON((49.8 -17.8, 50.8 -17.8, 50.8 -18.8, 49.8 -18.8, 49.8 -17.8))',
      nomRegion: 'Atsinanana',
      polygoneRegion:
          'POLYGON((49.5 -19.0, 51.0 -19.0, 51.0 -17.5, 49.5 -17.5, 49.5 -19.0))',
      nomDistrict: 'District Toamasina',
      polygoneDistrict:
          'POLYGON((50.0 -18.3, 50.4 -18.3, 50.4 -18.0, 50.0 -18.0, 50.0 -18.3))',
      nomParoisse: 'Paroisse Toamasina-Centre',
      nomEglise: 'Église Anglicane de Toamasina',
      localisation: 'POINT(50.2 -18.15)',
    );
    await _insererDioceseAvecEgliseSiAbsent(
      db,
      nomDiocese: 'Diocèse de Fianarantsoa',
      polygone:
          'POLYGON((46.7 -21.0, 47.2 -20.8, 47.7 -21.0, 47.7 -22.0, 47.2 -22.2, 46.7 -22.0, 46.7 -21.0))',
      nomRegion: 'Haute Matsiatra',
      polygoneRegion:
          'POLYGON((46.4 -22.3, 48.0 -22.3, 48.0 -20.7, 46.4 -20.7, 46.4 -22.3))',
      nomDistrict: 'District Fianarantsoa',
      polygoneDistrict:
          'POLYGON((46.9 -21.6, 47.3 -21.6, 47.3 -21.3, 46.9 -21.3, 46.9 -21.6))',
      nomParoisse: 'Paroisse Fianarantsoa-Centre',
      nomEglise: 'Église Anglicane de Fianarantsoa',
      localisation: 'POINT(47.1 -21.45)',
    );
  }

  static Future<void> _insererEgliseTestSiAbsente(
    DatabaseHelper db,
    int paroisseId,
  ) async {
    final egliseExistante = await db.tout(
      'eglise',
      where: 'nom = ?',
      whereArgs: [_nomEgliseDioceseTest],
    );
    if (egliseExistante.isNotEmpty) return;

    await db.inserer(
      'eglise',
      Eglise(
        nom: _nomEgliseDioceseTest,
        adresse: 'Dans le diocèse de test',
        localisation: 'POINT(45.00 -19.00)',
        paroisseId: paroisseId,
      ).toJson(),
    );
  }

  static Future<void> _insererDioceseAvecEgliseSiAbsent(
    DatabaseHelper db, {
    required String nomDiocese,
    required String polygone,
    required String nomRegion,
    required String polygoneRegion,
    required String nomDistrict,
    required String polygoneDistrict,
    required String nomParoisse,
    required String nomEglise,
    required String localisation,
  }) async {
    final diocese = await db.tout(
      'diocese',
      where: 'nom = ?',
      whereArgs: [nomDiocese],
    );
    if (diocese.isNotEmpty) {
      // await (await db.database).update(
      //   'diocese',
      //   {'carte_qgis': polygone},
      //   where: 'id = ?',
      //   whereArgs: [diocese.first['id']],
      // );
      await (await db.database).update(
        'region',
        {'carte_qgis': polygoneRegion},
        where: 'nom = ?',
        whereArgs: [nomRegion],
      );
      final district = await db.tout(
        'district',
        where: 'nom = ?',
        whereArgs: [nomDistrict],
      );
      if (district.isNotEmpty) {
        await (await db.database).update(
          'district',
          {'carte_qgis': polygoneDistrict},
          where: 'id = ?',
          whereArgs: [district.first['id']],
        );
        final paroisses = await db.tout(
          'paroisse',
          where: 'district_id = ?',
          whereArgs: [district.first['id']],
        );
        if (paroisses.isNotEmpty) {
          final eglises = await db.tout(
            'eglise',
            where: 'nom = ?',
            whereArgs: [nomEglise],
          );
          if (eglises.isEmpty) {
            await db.inserer(
              'eglise',
              Eglise(
                nom: nomEglise,
                adresse: 'Dans le diocèse de test',
                localisation: localisation,
                paroisseId: paroisses.first['id'] as int,
              ).toJson(),
            );
          }
        }
      }
      return;
    }

    final dioceseId = await db.inserer(
      'diocese',
      Diocese(
        nom: nomDiocese,
        carteQgis: polygone,
        presentation: 'Données de test',
      ).toJson(),
    );
    final regionId = await db.inserer(
      'region',
      Region(
        nom: nomRegion,
        carteQgis: polygoneRegion,
        dioceseId: dioceseId,
      ).toJson(),
    );
    final districtId = await db.inserer(
      'district',
      District(
        nom: nomDistrict,
        carteQgis: polygoneDistrict,
        regionId: regionId,
      ).toJson(),
    );
    final paroisseId = await db.inserer(
      'paroisse',
      Paroisse(nom: nomParoisse, districtId: districtId).toJson(),
    );
    await db.inserer(
      'eglise',
      Eglise(
        nom: nomEglise,
        adresse: 'Dans le diocèse de test',
        localisation: localisation,
        paroisseId: paroisseId,
      ).toJson(),
    );
  }
}

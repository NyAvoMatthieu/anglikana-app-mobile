import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:anglikana_app_mobile/models/district.dart';
import 'package:anglikana_app_mobile/models/eglise.dart';
import 'package:anglikana_app_mobile/models/paroisse.dart';
import 'package:anglikana_app_mobile/models/region.dart';
import 'package:anglikana_app_mobile/services/filtre_hierarchie_service.dart';
import 'package:anglikana_app_mobile/utils/geo_utils.dart';

void main() {
  group('GeoUtils.parsePolygons', () {
    test('POLYGON simple (anneau fermé -> dernier point retiré)', () {
      final p = GeoUtils.parsePolygons(
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
      )!;
      expect(p, hasLength(1));
      expect(p.first.exterieur, hasLength(4));
      expect(p.first.trous, isEmpty);
    });

    test('POLYGON avec trou', () {
      final p = GeoUtils.parsePolygons(
        'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(4 4, 6 4, 6 6, 4 6, 4 4))',
      )!;
      expect(p.first.trous, hasLength(1));
    });

    test('MULTIPOLYGON avec 2 polygones, dont un avec trou, Z et SRID', () {
      final p = GeoUtils.parsePolygons(
        'SRID=4326;MULTIPOLYGON Z (((0 0 5, 10 0 5, 10 10 5, 0 10 5, 0 0 5),'
        '(4 4 5, 6 4 5, 6 6 5, 4 6 5, 4 4 5)),'
        '((20 20 5, 30 20 5, 30 30 5, 20 30 5, 20 20 5)))',
      )!;
      expect(p, hasLength(2));
      expect(p.first.trous, hasLength(1));
      expect(p.last.trous, isEmpty);
    });

    test('GeoJSON Polygon, MultiPolygon et FeatureCollection', () {
      expect(
        GeoUtils.parsePolygons(
          '{"type":"Polygon","coordinates":[[[0,0],[10,0],[10,10],[0,0]]]}',
        ),
        hasLength(1),
      );
      expect(
        GeoUtils.parsePolygons(
          '{"type":"MultiPolygon","coordinates":['
          '[[[0,0],[10,0],[10,10],[0,0]]],'
          '[[[20,20],[30,20],[30,30],[20,20]]]]}',
        ),
        hasLength(2),
      );
      expect(
        GeoUtils.parsePolygons(
          '{"type":"FeatureCollection","features":[{"type":"Feature",'
          '"geometry":{"type":"Polygon","coordinates":'
          '[[[0,0],[10,0],[10,10],[0,0]]]}}]}',
        ),
        hasLength(1),
      );
    });

    test('entrées invalides -> null', () {
      for (final raw in [
        null,
        '',
        'POLYGON EMPTY',
        'POLYGON((0 0, 1 1))',
        'POLYGON((a b, 1 1, 2 2))',
        'POINT(1 2)',
        'n importe quoi',
      ]) {
        expect(GeoUtils.parsePolygons(raw), isNull, reason: '$raw');
      }
    });

    test('parsePolygon reste compatible (anneau extérieur)', () {
      expect(
        GeoUtils.parsePolygon('POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))'),
        hasLength(4),
      );
    });
  });

  group('GeoUtils.contient (point dans polygone)', () {
    final carre = GeoUtils.parsePolygons(
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0))',
    )!;
    final avecTrou = GeoUtils.parsePolygons(
      'POLYGON((0 0, 10 0, 10 10, 0 10, 0 0),(4 4, 6 4, 6 6, 4 6, 4 4))',
    )!;
    final multi = GeoUtils.parsePolygons(
      'MULTIPOLYGON(((0 0, 10 0, 10 10, 0 10, 0 0)),'
      '((20 20, 30 20, 30 30, 20 30, 20 20)))',
    )!;

    // Attention : LatLng(lat, lon) alors que le WKT est (lon lat).
    test('dedans / dehors', () {
      expect(GeoUtils.contient(carre, const LatLng(5, 5)), isTrue);
      expect(GeoUtils.contient(carre, const LatLng(15, 5)), isFalse);
      expect(GeoUtils.contient(carre, const LatLng(5, -1)), isFalse);
    });

    test('un trou exclut le point', () {
      expect(GeoUtils.contient(avecTrou, const LatLng(5, 5)), isFalse);
      expect(GeoUtils.contient(avecTrou, const LatLng(2, 2)), isTrue);
    });

    test('multipolygone : n’importe quelle partie', () {
      expect(GeoUtils.contient(multi, const LatLng(25, 25)), isTrue);
      expect(GeoUtils.contient(multi, const LatLng(15, 15)), isFalse);
    });

    test('formes concaves (en L)', () {
      final l = GeoUtils.parsePolygons(
        'POLYGON((0 0, 10 0, 10 2, 2 2, 2 10, 0 10, 0 0))',
      )!;
      expect(GeoUtils.contient(l, const LatLng(1, 8)), isTrue);
      expect(GeoUtils.contient(l, const LatLng(8, 8)), isFalse);
    });
  });

  group('Diocèse d’une église', () {
    test('remonte Église > Paroisse > District > Région > Diocèse', () {
      final ids = FiltreHierarchieService.dioceseIdsDesEglises(
        eglises: [
          Eglise(id: 1, nom: 'A', paroisseId: 10),
          Eglise(id: 2, nom: 'B', paroisseId: 11),
          Eglise(id: 3, nom: 'Orpheline'),
        ],
        paroisses: [
          Paroisse(id: 10, nom: 'P1', districtId: 100),
          Paroisse(id: 11, nom: 'P2', districtId: 101),
        ],
        districts: [
          District(id: 100, nom: 'D1', regionId: 1000),
          District(id: 101, nom: 'D2', regionId: 1001),
        ],
        regions: [
          Region(id: 1000, nom: 'R1', dioceseId: 7),
          Region(id: 1001, nom: 'R2', dioceseId: 8),
        ],
      );
      expect(ids, {7, 8});
    });
  });
}

import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Un polygone avec son anneau extérieur et ses éventuels trous
/// (« îles » vides : enclaves, lacs, autre diocèse enclavé...).
class GeoPolygon {
  final List<LatLng> exterieur;
  final List<List<LatLng>> trous;

  const GeoPolygon(this.exterieur, [this.trous = const []]);
}

/// Utilitaires de conversion géométrie <-> flutter_map.
///
/// Formats acceptés pour `carte_qgis` :
///  * WKT : POLYGON, MULTIPOLYGON (avec trous, avec ou sans Z, avec préfixe
///    `SRID=4326;`) ;
///  * GeoJSON : Polygon, MultiPolygon, Feature, FeatureCollection
///    (export « GeoJSON » de QGIS).
/// Les coordonnées sont attendues en (longitude latitude), WGS84.
class GeoUtils {
  GeoUtils._();

  static LatLng? parsePoint(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    try {
      if (value.startsWith('{')) return _parseGeoJsonPoint(value);
      final sansSrid = _sansSrid(value);
      if (sansSrid.toUpperCase().startsWith('POINT')) {
        return _parseWktPoint(sansSrid);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Retourne tous les polygones de [raw] (1 pour un POLYGON, n pour un
  /// MULTIPOLYGON), ou `null` si la géométrie est absente/invalide.
  static List<GeoPolygon>? parsePolygons(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    try {
      final polygons = value.startsWith('{')
          ? _parseGeoJsonPolygons(jsonDecode(value))
          : _parseWktPolygons(_sansSrid(value));
      if (polygons == null || polygons.isEmpty) return null;
      return polygons;
    } catch (_) {
      return null;
    }
  }

  /// Anneau extérieur du premier polygone (compatibilité avec l'ancien code
  /// et pour les validations « le polygone est-il lisible ? »).
  static List<LatLng>? parsePolygon(String? raw) =>
      parsePolygons(raw)?.first.exterieur;

  /// Tous les points (extérieurs) d'un ensemble de polygones : utile pour
  /// calculer l'emprise / le zoom.
  static List<LatLng> pointsDe(Iterable<GeoPolygon> polygons) =>
      [for (final p in polygons) ...p.exterieur];

  // ---------------------------------------------------------------------
  // Point dans polygone
  // ---------------------------------------------------------------------

  /// Vrai si [point] est dans au moins un des [polygons] (en tenant compte
  /// des trous). Algorithme du rayon (even-odd) ; un point exactement sur la
  /// frontière peut être classé dedans ou dehors.
  static bool contient(Iterable<GeoPolygon> polygons, LatLng point) {
    for (final polygon in polygons) {
      if (!_dansAnneau(polygon.exterieur, point)) continue;
      final dansUnTrou = polygon.trous.any((t) => _dansAnneau(t, point));
      if (!dansUnTrou) return true;
    }
    return false;
  }

  static bool _dansAnneau(List<LatLng> anneau, LatLng p) {
    var dedans = false;
    final n = anneau.length;
    for (var i = 0, j = n - 1; i < n; j = i++) {
      final xi = anneau[i].longitude, yi = anneau[i].latitude;
      final xj = anneau[j].longitude, yj = anneau[j].latitude;
      final coupe =
          (yi > p.latitude) != (yj > p.latitude) &&
          p.longitude < (xj - xi) * (p.latitude - yi) / (yj - yi) + xi;
      if (coupe) dedans = !dedans;
    }
    return dedans;
  }

  // ---------------------------------------------------------------------
  // WKT
  // ---------------------------------------------------------------------

  static String _sansSrid(String value) =>
      value.replaceFirst(RegExp(r'^SRID=\d+;', caseSensitive: false), '').trim();

  static List<GeoPolygon>? _parseWktPolygons(String wkt) {
    final upper = wkt.toUpperCase();
    // Retire un éventuel « Z », « M » ou « ZM » après le type.
    final enTete = RegExp(
      r'^(MULTIPOLYGON|POLYGON)\s*(?:ZM|Z|M)?\s*',
    ).firstMatch(upper);
    if (enTete == null) return null;
    final corps = wkt.substring(enTete.end).trim();
    if (corps.toUpperCase() == 'EMPTY') return null;

    if (enTete.group(1) == 'POLYGON') {
      final polygon = _parseWktPolygonBody(corps);
      return polygon == null ? null : [polygon];
    }

    // MULTIPOLYGON(((...)),((...)))
    if (!corps.startsWith('(') || !corps.endsWith(')')) return null;
    final interieur = corps.substring(1, corps.length - 1);
    final resultat = <GeoPolygon>[];
    for (final morceau in _groupesParentheses(interieur)) {
      final polygon = _parseWktPolygonBody(morceau);
      if (polygon == null) return null;
      resultat.add(polygon);
    }
    return resultat;
  }

  /// Corps d'un polygone : `((x y, x y, ...),(trou...))`.
  static GeoPolygon? _parseWktPolygonBody(String body) {
    final b = body.trim();
    if (!b.startsWith('(') || !b.endsWith(')')) return null;
    final anneaux = <List<LatLng>>[];
    for (final morceau in _groupesParentheses(b.substring(1, b.length - 1))) {
      final anneau = _parseWktRing(morceau);
      if (anneau == null) return null;
      anneaux.add(anneau);
    }
    if (anneaux.isEmpty) return null;
    return GeoPolygon(anneaux.first, anneaux.skip(1).toList());
  }

  /// Découpe `(a),(b),(c)` au niveau 0 de parenthèses et retourne les
  /// contenus *avec* leurs parenthèses extérieures : `(a)`, `(b)`, `(c)`.
  static List<String> _groupesParentheses(String s) {
    final groupes = <String>[];
    var profondeur = 0;
    var debut = -1;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') {
        if (profondeur == 0) debut = i;
        profondeur++;
      } else if (c == ')') {
        profondeur--;
        if (profondeur == 0 && debut >= 0) {
          groupes.add(s.substring(debut, i + 1));
          debut = -1;
        }
        if (profondeur < 0) return const [];
      }
    }
    return profondeur == 0 ? groupes : const [];
  }

  static List<LatLng>? _parseWktRing(String ring) {
    final r = ring.trim();
    if (!r.startsWith('(') || !r.endsWith(')')) return null;
    final points = <LatLng>[];
    for (final pair in r.substring(1, r.length - 1).split(',')) {
      final values = pair.trim().split(RegExp(r'\s+'));
      if (values.length < 2) return null;
      final lon = double.tryParse(values[0]);
      final lat = double.tryParse(values[1]);
      if (lon == null || lat == null) return null;
      points.add(LatLng(lat, lon));
    }
    return _anneauValide(points);
  }

  /// Un anneau valide a au moins 3 sommets distincts ; si le dernier point
  /// répète le premier (convention WKT/GeoJSON), on le retire.
  static List<LatLng>? _anneauValide(List<LatLng> points) {
    if (points.length >= 2 &&
        points.first.latitude == points.last.latitude &&
        points.first.longitude == points.last.longitude) {
      points = points.sublist(0, points.length - 1);
    }
    return points.length >= 3 ? points : null;
  }

  static LatLng? _parseWktPoint(String wkt) {
    final match = RegExp(
      r'POINT\s*(?:ZM|Z|M)?\s*\(\s*([-+\d.eE]+)\s+([-+\d.eE]+)(?:\s+[-+\d.eE]+)*\s*\)',
      caseSensitive: false,
    ).firstMatch(wkt);
    if (match == null) return null;

    final lon = double.tryParse(match.group(1)!);
    final lat = double.tryParse(match.group(2)!);
    if (lon == null || lat == null) return null;
    return LatLng(lat, lon);
  }

  // ---------------------------------------------------------------------
  // GeoJSON
  // ---------------------------------------------------------------------

  static LatLng? _parseGeoJsonPoint(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map || decoded['type'] != 'Point') return null;

    final coords = decoded['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    return LatLng(lat, lon);
  }

  static List<GeoPolygon>? _parseGeoJsonPolygons(dynamic decoded) {
    if (decoded is! Map) return null;
    switch (decoded['type']) {
      case 'Polygon':
        final p = _geoJsonPolygon(decoded['coordinates']);
        return p == null ? null : [p];
      case 'MultiPolygon':
        final coords = decoded['coordinates'];
        if (coords is! List) return null;
        final result = <GeoPolygon>[];
        for (final c in coords) {
          final p = _geoJsonPolygon(c);
          if (p == null) return null;
          result.add(p);
        }
        return result;
      case 'Feature':
        return _parseGeoJsonPolygons(decoded['geometry']);
      case 'FeatureCollection':
        final features = decoded['features'];
        if (features is! List) return null;
        final result = <GeoPolygon>[];
        for (final f in features) {
          final sub = _parseGeoJsonPolygons(f);
          if (sub != null) result.addAll(sub);
        }
        return result;
    }
    return null;
  }

  static GeoPolygon? _geoJsonPolygon(dynamic coords) {
    if (coords is! List || coords.isEmpty) return null;
    final anneaux = <List<LatLng>>[];
    for (final ring in coords) {
      if (ring is! List) return null;
      final points = <LatLng>[];
      for (final c in ring) {
        if (c is! List || c.length < 2) return null;
        points.add(LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()));
      }
      final valide = _anneauValide(points);
      if (valide == null) return null;
      anneaux.add(valide);
    }
    return GeoPolygon(anneaux.first, anneaux.skip(1).toList());
  }

  static LatLngBounds? boundsOf(Iterable<LatLng> points) {
    final list = points.toList();
    if (list.isEmpty) return null;
    return LatLngBounds.fromPoints(list);
  }
}

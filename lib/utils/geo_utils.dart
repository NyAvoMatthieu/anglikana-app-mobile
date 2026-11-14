import 'dart:convert';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Utilitaires de conversion géométrie <-> flutter_map.
class GeoUtils {
  GeoUtils._();

  static LatLng? parsePoint(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    try {
      if (value.startsWith('{')) return _parseGeoJsonPoint(value);
      if (value.toUpperCase().startsWith('POINT')) {
        return _parseWktPoint(value);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static List<LatLng>? parsePolygon(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    try {
      final match = RegExp(
        r'^POLYGON\s*\(\(\s*(.*?)\s*\)\)$',
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(value);
      if (match == null) return null;

      final points = <LatLng>[];
      for (final pair in match.group(1)!.split(',')) {
        final values = pair.trim().split(RegExp(r'\s+'));
        if (values.length < 2) return null;
        final lon = double.tryParse(values[0]);
        final lat = double.tryParse(values[1]);
        if (lon == null || lat == null) return null;
        points.add(LatLng(lat, lon));
      }
      return points.length >= 3 ? points : null;
    } catch (_) {
      return null;
    }
  }

  static LatLng? _parseWktPoint(String wkt) {
    final match = RegExp(
      r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)',
      caseSensitive: false,
    ).firstMatch(wkt);
    if (match == null) return null;

    final lon = double.tryParse(match.group(1)!);
    final lat = double.tryParse(match.group(2)!);
    if (lon == null || lat == null) return null;
    return LatLng(lat, lon);
  }

  static LatLng? _parseGeoJsonPoint(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map || decoded['type'] != 'Point') return null;

    final coords = decoded['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();
    return LatLng(lat, lon);
  }

  static LatLngBounds? boundsOf(Iterable<LatLng> points) {
    final list = points.toList();
    if (list.isEmpty) return null;
    return LatLngBounds.fromPoints(list);
  }
}

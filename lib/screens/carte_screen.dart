import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/diocese.dart';
import '../models/district.dart';
import '../models/eglise.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import '../models/ressource.dart';
import '../services/filtre_hierarchie_service.dart';
import '../services/offline_map_service.dart';
import '../services/recherche_service.dart';
import '../utils/geo_utils.dart';
import '../widgets/filtre_hierarchie_bar.dart';

/// Écran d'affichage de la carte interactive, avec recherche d'églises,
/// filtres hiérarchiques et zoom automatique sur les résultats.
///
/// Les données sont reçues en paramètres (listes déjà chargées en mémoire) :
/// la source réelle (SQLite / synchro API) sera branchée par les modules
/// suivants sans changer cette interface.
class CarteScreen extends StatefulWidget {
  final List<Eglise> eglises;
  final List<Ressource> ressources;
  final List<Diocese> dioceses;
  final List<Region> regions;
  final List<District> districts;
  final List<Paroisse> paroisses;

  const CarteScreen({
    super.key,
    this.eglises = const [],
    this.ressources = const [],
    this.dioceses = const [],
    this.regions = const [],
    this.districts = const [],
    this.paroisses = const [],
  });

  @override
  State<CarteScreen> createState() => _CarteScreenState();
}

class _CarteScreenState extends State<CarteScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  static const LatLng _defaultCenter = LatLng(
    -18.8792,
    45.5079,
  ); // Antananarivo
  static const double _defaultZoom = 7;
  static const String _tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  FiltreHierarchieSelection _selection = const FiltreHierarchieSelection();
  String _query = '';
  String _dioceseQuery = '';
  String _regionQuery = '';
  String _districtQuery = '';
  Diocese? _dioceseSelectionne;
  Diocese? _dioceseValide;
  Region? _regionSelectionnee;
  Region? _regionValidee;
  District? _districtSelectionne;
  District? _districtValide;
  int? _derniereSignature;

  List<Diocese> get _diocesesCorrespondants {
    final query = RechercheService.normaliser(_dioceseQuery.trim());
    if (query.isEmpty) return const [];
    return widget.dioceses
        .where(
          (diocese) => RechercheService.normaliser(diocese.nom).contains(query),
        )
        .toList();
  }

  List<LatLng>? get _polygoneDiocese =>
      GeoUtils.parsePolygon(_dioceseValide?.carteQgis);

  List<Region> get _regionsCorrespondantes {
    final query = RechercheService.normaliser(_regionQuery.trim());
    if (query.isEmpty) return const [];
    return widget.regions
        .where(
          (region) => RechercheService.normaliser(region.nom).contains(query),
        )
        .toList();
  }

  List<LatLng>? get _polygoneRegion =>
      GeoUtils.parsePolygon(_regionValidee?.carteQgis);

  List<District> get _districtsCorrespondants {
    final query = RechercheService.normaliser(_districtQuery.trim());
    if (query.isEmpty) return const [];
    return widget.districts
        .where(
          (district) =>
              RechercheService.normaliser(district.nom).contains(query),
        )
        .toList();
  }

  List<LatLng>? get _polygoneDistrict =>
      GeoUtils.parsePolygon(_districtValide?.carteQgis);

  bool get _dioceseEstSeulFiltre =>
      _selection.dioceseId != null &&
      _selection.regionId == null &&
      _selection.districtId == null &&
      _selection.paroisseId == null;

  List<LatLng>? get _polygoneAffiche => _query.trim().isNotEmpty
      ? null
      : _polygoneDistrict ??
            (_selection.districtId == null && _selection.regionId != null
                ? _polygoneRegion
                : (_dioceseEstSeulFiltre ? _polygoneDiocese : null));

  Color get _couleurPolygone {
    if (_polygoneDistrict != null) return Colors.green;
    if (_selection.regionId != null) return Colors.yellow;
    return Colors.blue;
  }

  List<Eglise> get _eglisesFiltrees {
    final parHierarchie = FiltreHierarchieService.appliquerSurEglises(
      eglises: widget.eglises,
      paroisses: widget.paroisses,
      districts: widget.districts,
      regions: widget.regions,
      selection: _selection,
    );
    return RechercheService.rechercherEglises(parHierarchie, _query);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _zoomAutoSiNecessaire(List<Eglise> resultats, List<LatLng>? polygone) {
    final points =
        polygone ??
        resultats
            .map((e) => GeoUtils.parsePoint(e.localisation))
            .whereType<LatLng>()
            .toList();
    if (points.isEmpty) return;

    // Évite de refaire le zoom en boucle sur les mêmes résultats.
    final signature = Object.hashAll([
      ...resultats.map((e) => e.id),
      ...points.map((point) => Object.hash(point.latitude, point.longitude)),
    ]);
    if (signature == _derniereSignature) return;
    _derniereSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (polygone != null) {
        final center = LatLng(
          points.map((point) => point.latitude).reduce((a, b) => a + b) /
              points.length,
          points.map((point) => point.longitude).reduce((a, b) => a + b) /
              points.length,
        );
        final zoom = _selection.districtId != null
            ? 11.0
            : _selection.regionId != null
            ? 9.0
            : 8.0;
        _mapController.move(center, zoom);
        return;
      }
      if (points.length == 1) {
        _mapController.move(points.first, 15);
        return;
      }
      final bounds = GeoUtils.boundsOf(points);
      if (bounds == null) return;
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultats = _eglisesFiltrees;
    final polygone = _polygoneAffiche;
    _zoomAutoSiNecessaire(resultats, polygone);

    final markers = resultats
        .map((e) {
          final point = GeoUtils.parsePoint(e.localisation);
          if (point == null) return null;
          return Marker(
            point: point,
            width: 40,
            height: 40,
            child: Tooltip(
              message: e.nom,
              child: const Icon(Icons.church, color: Colors.deepPurple),
            ),
          );
        })
        .whereType<Marker>()
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Rechercher une église...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un diocèse',
                    hintText: 'Nom du diocèse',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    _dioceseQuery = value;
                    _dioceseSelectionne = null;
                  }),
                ),
                if (_dioceseSelectionne == null &&
                    _diocesesCorrespondants.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView(
                      shrinkWrap: true,
                      children: _diocesesCorrespondants
                          .map(
                            (diocese) => ListTile(
                              dense: true,
                              title: Text(diocese.nom),
                              onTap: () => setState(() {
                                _dioceseSelectionne = diocese;
                                _dioceseQuery = diocese.nom;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (_dioceseSelectionne != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _validerDiocese,
                      child: const Text('Valider le diocèse'),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher une région',
                    hintText: 'Nom de la région',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    _regionQuery = value;
                    _regionSelectionnee = null;
                  }),
                ),
                if (_regionSelectionnee == null &&
                    _regionsCorrespondantes.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView(
                      shrinkWrap: true,
                      children: _regionsCorrespondantes
                          .map(
                            (region) => ListTile(
                              dense: true,
                              title: Text(region.nom),
                              onTap: () => setState(() {
                                _regionSelectionnee = region;
                                _regionQuery = region.nom;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (_regionSelectionnee != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _validerRegion,
                      child: const Text('Valider la région'),
                    ),
                  ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Rechercher un district',
                    hintText: 'Nom du district',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => setState(() {
                    _districtQuery = value;
                    _districtSelectionne = null;
                  }),
                ),
                if (_districtSelectionne == null &&
                    _districtsCorrespondants.isNotEmpty)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: ListView(
                      shrinkWrap: true,
                      children: _districtsCorrespondants
                          .map(
                            (district) => ListTile(
                              dense: true,
                              title: Text(district.nom),
                              onTap: () => setState(() {
                                _districtSelectionne = district;
                                _districtQuery = district.nom;
                              }),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                if (_districtSelectionne != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _validerDistrict,
                      child: const Text('Valider le district'),
                    ),
                  ),
              ],
            ),
          ),
          FiltreHierarchieBar(
            dioceses: widget.dioceses,
            regions: widget.regions,
            districts: widget.districts,
            paroisses: widget.paroisses,
            selection: _selection,
            onChanged: _appliquerSelectionHierarchie,
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _defaultZoom,
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: _tileUrlTemplate,
                  userAgentPackageName: 'com.anglikana.aca',
                  maxNativeZoom: 19,
                  tileProvider: OfflineMapService.tileProvider,
                ),
                if (polygone != null)
                  PolygonLayer(
                    polygons: [
                      Polygon(
                        points: polygone,
                        color: _couleurPolygone.withValues(alpha: 0.25),
                        borderColor: _couleurPolygone,
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('© OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validerDiocese() {
    final diocese = _dioceseSelectionne;
    if (diocese == null) return;
    if (GeoUtils.parsePolygon(diocese.carteQgis) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les coordonnées du polygone de ce diocèse sont invalides.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _dioceseValide = diocese;
      _selection = FiltreHierarchieSelection(dioceseId: diocese.id);
    });
  }

  void _appliquerSelectionHierarchie(FiltreHierarchieSelection selection) {
    Diocese? diocese;
    for (final candidat in widget.dioceses) {
      if (candidat.id == selection.dioceseId) {
        diocese = candidat;
        break;
      }
    }
    setState(() {
      _selection = selection;
      _dioceseValide = diocese;
      _regionValidee = null;
      _regionSelectionnee = null;
      _regionQuery = '';
      _districtValide = null;
      _districtSelectionne = null;
      _districtQuery = '';
      if (selection.districtId != null) {
        for (final candidat in widget.districts) {
          if (candidat.id == selection.districtId) {
            _districtValide = candidat;
            _districtSelectionne = candidat;
            _districtQuery = candidat.nom;
            break;
          }
        }
      }
      if (selection.regionId != null) {
        for (final candidat in widget.regions) {
          if (candidat.id == selection.regionId) {
            _regionValidee = candidat;
            _regionSelectionnee = candidat;
            _regionQuery = candidat.nom;
            break;
          }
        }
      }
      if (diocese != null) {
        _dioceseQuery = diocese.nom;
        _dioceseSelectionne = diocese;
      } else {
        _dioceseQuery = '';
        _dioceseSelectionne = null;
      }
    });
  }

  void _validerDistrict() {
    final district = _districtSelectionne;
    if (district == null) return;
    if (GeoUtils.parsePolygon(district.carteQgis) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les coordonnées du polygone de ce district sont invalides.',
          ),
        ),
      );
      return;
    }

    Region? region;
    for (final candidat in widget.regions) {
      if (candidat.id == district.regionId) {
        region = candidat;
        break;
      }
    }
    _appliquerSelectionHierarchie(
      FiltreHierarchieSelection(
        dioceseId: region?.dioceseId,
        regionId: region?.id,
        districtId: district.id,
      ),
    );
  }

  void _validerRegion() {
    final region = _regionSelectionnee;
    if (region == null) return;
    if (GeoUtils.parsePolygon(region.carteQgis) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Les coordonnées du polygone de cette région sont invalides.',
          ),
        ),
      );
      return;
    }

    _appliquerSelectionHierarchie(
      FiltreHierarchieSelection(
        dioceseId: region.dioceseId,
        regionId: region.id,
      ),
    );
  }
}

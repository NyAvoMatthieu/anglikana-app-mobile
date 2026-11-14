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
  Diocese? _dioceseSelectionne;
  Diocese? _dioceseValide;
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

  bool get _dioceseEstSeulFiltre =>
      _selection.dioceseId != null &&
      _selection.regionId == null &&
      _selection.districtId == null &&
      _selection.paroisseId == null;

  List<LatLng>? get _polygoneAffiche =>
      _query.trim().isEmpty && _dioceseEstSeulFiltre ? _polygoneDiocese : null;

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
              ],
            ),
          ),
          FiltreHierarchieBar(
            dioceses: widget.dioceses,
            regions: widget.regions,
            districts: widget.districts,
            paroisses: widget.paroisses,
            selection: _selection,
            onChanged: (selection) => setState(() => _selection = selection),
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
                        color: Colors.blue.withValues(alpha: 0.25),
                        borderColor: Colors.blue,
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
}

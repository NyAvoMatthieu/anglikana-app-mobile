import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../database/aca_repository.dart';
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
import 'eglise_details_screen.dart';

/// Un ou plusieurs polygones à dessiner, avec leur couleur.
class _Zone {
  final List<GeoPolygon> polygones;
  final Color couleur;

  const _Zone(this.polygones, this.couleur);
}

/// Écran d'affichage de la carte interactive, avec recherche d'églises,
/// filtres hiérarchiques et zoom automatique sur les résultats.
///
/// Règles d'affichage des polygones QGIS :
///  * filtre district / région / diocèse choisi -> polygone du niveau le plus
///    précis disponible (district > région > diocèse) ;
///  * recherche texte d'une église -> polygone du (ou des) diocèse(s) qui
///    contiennent les églises trouvées ;
///  * une église dont le point GPS tombe hors du polygone de référence est
///    marquée en orange (incohérence entre la hiérarchie et la géométrie).
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
  final TextEditingController _dioceseController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  static const LatLng _defaultCenter = LatLng(
    -18.8792,
    45.5079,
  ); // Antananarivo
  static const double _defaultZoom = 7;
  static const String _tileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Couleurs utilisées quand une recherche tombe sur plusieurs diocèses.
  static const List<Color> _couleursDioceses = [
    Colors.blue,
    Colors.teal,
    Colors.indigo,
    Colors.cyan,
    Colors.purple,
  ];

  FiltreHierarchieSelection _selection = const FiltreHierarchieSelection();
  String _query = '';
  String _dioceseQuery = '';
  String _regionQuery = '';
  String _districtQuery = '';
  Diocese? _dioceseSelectionne;
  Region? _regionSelectionnee;
  District? _districtSelectionne;
  int? _derniereSignature;

  // -------------------------------------------------------------------
  // Suggestions des champs texte Diocèse / Région / District
  // -------------------------------------------------------------------

  List<Diocese> get _diocesesCorrespondants {
    final query = RechercheService.normaliser(_dioceseQuery.trim());
    if (query.isEmpty) return const [];
    return widget.dioceses
        .where(
          (diocese) => RechercheService.normaliser(diocese.nom).contains(query),
        )
        .toList();
  }

  List<Region> get _regionsCorrespondantes {
    final query = RechercheService.normaliser(_regionQuery.trim());
    if (query.isEmpty) return const [];
    return widget.regions
        .where(
          (region) => RechercheService.normaliser(region.nom).contains(query),
        )
        .toList();
  }

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

  // -------------------------------------------------------------------
  // Polygones
  // -------------------------------------------------------------------

  T? _parId<T>(List<T> liste, int? id, int? Function(T) idDe) {
    if (id == null) return null;
    for (final item in liste) {
      if (idDe(item) == id) return item;
    }
    return null;
  }

  /// Polygone du filtre géographique courant : district, sinon région,
  /// sinon diocèse (lorsque le niveau choisi n'a pas de géométrie lisible,
  /// on retombe sur le niveau supérieur).
  _Zone? _zoneSelection() {
    final district = _parId(
      widget.districts,
      _selection.districtId,
      (d) => d.id,
    );
    final polyDistrict = GeoUtils.parsePolygons(district?.carteQgis);
    if (polyDistrict != null) return _Zone(polyDistrict, Colors.green);

    final region = _parId(widget.regions, _selection.regionId, (r) => r.id);
    final polyRegion = GeoUtils.parsePolygons(region?.carteQgis);
    if (polyRegion != null) return _Zone(polyRegion, Colors.amber.shade800);

    final diocese = _parId(widget.dioceses, _selection.dioceseId, (d) => d.id);
    final polyDiocese = GeoUtils.parsePolygons(diocese?.carteQgis);
    if (polyDiocese != null) return _Zone(polyDiocese, Colors.blue);

    return null;
  }

  /// Quand on cherche une église par texte : polygone du diocèse de chaque
  /// église trouvée (un seul le plus souvent).
  List<_Zone> _zonesRecherche(List<Eglise> resultats) {
    if (_query.trim().isEmpty || resultats.isEmpty) return const [];

    final ids = FiltreHierarchieService.dioceseIdsDesEglises(
      eglises: resultats,
      paroisses: widget.paroisses,
      districts: widget.districts,
      regions: widget.regions,
    );
    final zones = <_Zone>[];
    for (final diocese in widget.dioceses) {
      if (diocese.id == null || !ids.contains(diocese.id)) continue;
      final polygones = GeoUtils.parsePolygons(diocese.carteQgis);
      if (polygones == null) continue;
      zones.add(
        _Zone(polygones, _couleursDioceses[zones.length % _couleursDioceses.length]),
      );
    }
    return zones;
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
    _dioceseController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------
  // Zoom
  // -------------------------------------------------------------------

  void _zoomAutoSiNecessaire(
    List<Eglise> resultats,
    List<_Zone> zones,
    List<LatLng> pointsEglises,
  ) {
    final pointsZones = [
      for (final zone in zones) ...GeoUtils.pointsDe(zone.polygones),
    ];
    // Avec une recherche texte, on cadre polygone ET églises trouvées ;
    // avec un simple filtre, on cadre le polygone ; sans rien, les églises.
    final points = _query.trim().isNotEmpty
        ? [...pointsZones, ...pointsEglises]
        : (pointsZones.isNotEmpty ? pointsZones : pointsEglises);
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
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(40),
          maxZoom: 15,
        ),
      );
    });
  }

  // -------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final resultats = _eglisesFiltrees;
    final zoneSelection = _zoneSelection();
    final zonesRecherche = _zonesRecherche(resultats);
    final zones = [...zonesRecherche, ?zoneSelection];

    // Polygone de référence pour le test « église dans la zone » : le filtre
    // choisi s'il existe, sinon le(s) diocèse(s) de la recherche.
    final zonesReference = zoneSelection != null
        ? [zoneSelection]
        : zonesRecherche;
    final polygonesReference = [
      for (final zone in zonesReference) ...zone.polygones,
    ];

    final pointsEglises = <LatLng>[];
    var horsZone = 0;
    final markers = <Marker>[];
    for (final eglise in resultats) {
      final point = GeoUtils.parsePoint(eglise.localisation);
      if (point == null) continue;
      pointsEglises.add(point);
      final estHorsZone =
          polygonesReference.isNotEmpty &&
          !GeoUtils.contient(polygonesReference, point);
      if (estHorsZone) horsZone++;
      markers.add(
        Marker(
          point: point,
          width: 40,
          height: 40,
          child: Tooltip(
            message: estHorsZone
                ? '${eglise.nom} (hors du polygone)'
                : eglise.nom,
            child: GestureDetector(
              onTap: () => _afficherDetailsEglise(eglise),
              child: Icon(
                Icons.church,
                color: estHorsZone ? Colors.orange.shade800 : Colors.deepPurple,
              ),
            ),
          ),
        ),
      );
    }

    _zoomAutoSiNecessaire(resultats, zones, pointsEglises);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carte'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une église...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  tooltip: 'Valider la recherche',
                  onPressed: _validerRecherche,
                ),
                filled: true,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _query = value),
              onSubmitted: (_) => _validerRecherche(),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Card(
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    // Replié par défaut : sur téléphone, les filtres ouverts
                    // laissaient très peu de place à la carte.
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    title: const Text(
                      'Filtres géographiques',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Diocèse, région et district'),
                    leading: const Icon(Icons.filter_alt),
                    children: [
                      _buildRechercheHierarchie<Diocese>(
                        label: 'Diocèse',
                        hint: 'Nom du diocèse',
                        controller: _dioceseController,
                        selection: _dioceseSelectionne,
                        suggestions: _diocesesCorrespondants,
                        nomDe: (diocese) => diocese.nom,
                        onChanged: (value) => setState(() {
                          _dioceseQuery = value;
                          _dioceseSelectionne = null;
                        }),
                        onSelected: (diocese) {
                          setState(() {
                            _dioceseSelectionne = diocese;
                            _dioceseQuery = diocese.nom;
                            _dioceseController.text = diocese.nom;
                          });
                          _validerDiocese();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildRechercheHierarchie<Region>(
                        label: 'Région',
                        hint: 'Nom de la région',
                        controller: _regionController,
                        selection: _regionSelectionnee,
                        suggestions: _regionsCorrespondantes,
                        nomDe: (region) => region.nom,
                        onChanged: (value) => setState(() {
                          _regionQuery = value;
                          _regionSelectionnee = null;
                        }),
                        onSelected: (region) {
                          setState(() {
                            _regionSelectionnee = region;
                            _regionQuery = region.nom;
                            _regionController.text = region.nom;
                          });
                          _validerRegion();
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildRechercheHierarchie<District>(
                        label: 'District',
                        hint: 'Nom du district',
                        controller: _districtController,
                        selection: _districtSelectionne,
                        suggestions: _districtsCorrespondants,
                        nomDe: (district) => district.nom,
                        onChanged: (value) => setState(() {
                          _districtQuery = value;
                          _districtSelectionne = null;
                        }),
                        onSelected: (district) {
                          setState(() {
                            _districtSelectionne = district;
                            _districtQuery = district.nom;
                            _districtController.text = district.nom;
                          });
                          _validerDistrict();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
            ),
            child: FiltreHierarchieBar(
              dioceses: widget.dioceses,
              regions: widget.regions,
              districts: widget.districts,
              paroisses: widget.paroisses,
              selection: _selection,
              onChanged: _appliquerSelectionHierarchie,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
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
                    if (zones.isNotEmpty)
                      PolygonLayer(
                        polygons: [
                          for (final zone in zones)
                            for (final polygone in zone.polygones)
                              Polygon(
                                points: polygone.exterieur,
                                holePointsList: polygone.trous.isEmpty
                                    ? null
                                    : polygone.trous,
                                color: zone.couleur.withValues(alpha: 0.2),
                                borderColor: zone.couleur,
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
                if (horsZone > 0)
                  Positioned(
                    top: 8,
                    left: 8,
                    right: 8,
                    child: Center(
                      child: Chip(
                        avatar: Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade800,
                          size: 18,
                        ),
                        label: Text(
                          horsZone == 1
                              ? '1 église hors du polygone (en orange)'
                              : '$horsZone églises hors du polygone (en orange)',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Widgets / actions
  // -------------------------------------------------------------------

  Widget _buildRechercheHierarchie<T>({
    required String label,
    required String hint,
    required TextEditingController controller,
    required T? selection,
    required List<T> suggestions,
    required String Function(T) nomDe,
    required ValueChanged<String> onChanged,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
        if (selection == null && suggestions.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 140),
            child: ListView(
              shrinkWrap: true,
              children: suggestions
                  .map(
                    (item) => ListTile(
                      dense: true,
                      title: Text(nomDe(item)),
                      onTap: () => onSelected(item),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  /// Valide la recherche texte : ferme le clavier et force un nouveau cadrage
  /// de la carte, même si les résultats n'ont pas changé.
  void _validerRecherche() {
    FocusScope.of(context).unfocus();
    setState(() => _derniereSignature = null);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _validerDiocese() {
    final diocese = _dioceseSelectionne;
    if (diocese == null) return;
    if (GeoUtils.parsePolygons(diocese.carteQgis) == null) {
      _snack('Les coordonnées du polygone de ce diocèse sont invalides.');
      return;
    }
    _appliquerSelectionHierarchie(
      FiltreHierarchieSelection(dioceseId: diocese.id),
    );
  }

  void _validerRegion() {
    final region = _regionSelectionnee;
    if (region == null) return;
    if (GeoUtils.parsePolygons(region.carteQgis) == null) {
      _snack('Les coordonnées du polygone de cette région sont invalides.');
      return;
    }
    _appliquerSelectionHierarchie(
      FiltreHierarchieSelection(
        dioceseId: region.dioceseId,
        regionId: region.id,
      ),
    );
  }

  void _validerDistrict() {
    final district = _districtSelectionne;
    if (district == null) return;
    if (GeoUtils.parsePolygons(district.carteQgis) == null) {
      _snack('Les coordonnées du polygone de ce district sont invalides.');
      return;
    }
    final region = _parId(widget.regions, district.regionId, (r) => r.id);
    _appliquerSelectionHierarchie(
      FiltreHierarchieSelection(
        dioceseId: region?.dioceseId,
        regionId: region?.id,
        districtId: district.id,
      ),
    );
  }

  /// Applique une sélection hiérarchique (venue des menus déroulants ou des
  /// champs texte) et resynchronise les trois champs texte.
  void _appliquerSelectionHierarchie(FiltreHierarchieSelection selection) {
    final diocese = _parId(widget.dioceses, selection.dioceseId, (d) => d.id);
    final region = _parId(widget.regions, selection.regionId, (r) => r.id);
    final district = _parId(
      widget.districts,
      selection.districtId,
      (d) => d.id,
    );

    setState(() {
      _selection = selection;
      _dioceseSelectionne = diocese;
      _regionSelectionnee = region;
      _districtSelectionne = district;
      _dioceseQuery = diocese?.nom ?? '';
      _regionQuery = region?.nom ?? '';
      _districtQuery = district?.nom ?? '';
      _dioceseController.text = _dioceseQuery;
      _regionController.text = _regionQuery;
      _districtController.text = _districtQuery;
    });
  }

  Future<void> _afficherDetailsEglise(Eglise eglise) async {
    if (eglise.id == null) return;
    final details = await AcaRepository.chargerDetailsEglise(eglise.id!);
    if (!mounted) return;
    if (details == null) {
      _snack('Impossible de charger cette église.');
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EgliseDetailsScreen(details: details),
      ),
    );
  }
}

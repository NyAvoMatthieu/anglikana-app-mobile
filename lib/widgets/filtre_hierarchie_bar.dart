import 'package:flutter/material.dart';

import '../models/diocese.dart';
import '../models/district.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import '../services/filtre_hierarchie_service.dart';
import '../services/recherche_service.dart';

/// Barre de filtres hiérarchiques en cascade : Diocèse > Région > District >
/// Paroisse. Chaque niveau garde un menu déroulant classique, avec un champ
/// de recherche en dessous qui filtre localement les options affichées dans
/// ce menu (la recherche ne modifie pas la sélection elle-même).
class FiltreHierarchieBar extends StatefulWidget {
  final List<Diocese> dioceses;
  final List<Region> regions;
  final List<District> districts;
  final List<Paroisse> paroisses;
  final FiltreHierarchieSelection selection;
  final ValueChanged<FiltreHierarchieSelection> onChanged;

  const FiltreHierarchieBar({
    super.key,
    required this.dioceses,
    required this.regions,
    required this.districts,
    required this.paroisses,
    required this.selection,
    required this.onChanged,
  });

  @override
  State<FiltreHierarchieBar> createState() => _FiltreHierarchieBarState();
}

class _FiltreHierarchieBarState extends State<FiltreHierarchieBar> {
  String _rechercheDiocese = '';
  String _rechercheRegion = '';
  String _rechercheDistrict = '';
  String _rechercheParoisse = '';

  @override
  Widget build(BuildContext context) {
    final selection = widget.selection;

    final dioceses = RechercheService.rechercherDioceses(
      widget.dioceses,
      _rechercheDiocese,
    );

    final regionsCascade = FiltreHierarchieService.regionsPour(
      widget.regions,
      selection.dioceseId,
    );
    final regions = RechercheService.rechercherRegions(
      regionsCascade,
      _rechercheRegion,
    );

    final districtsCascade = FiltreHierarchieService.districtsPour(
      widget.districts,
      selection.regionId,
    );
    final districts = RechercheService.rechercherDistricts(
      districtsCascade,
      _rechercheDistrict,
    );

    final paroissesCascade = FiltreHierarchieService.paroissesPour(
      widget.paroisses,
      selection.districtId,
    );
    final paroisses = RechercheService.rechercherParoisses(
      paroissesCascade,
      _rechercheParoisse,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _colonneNiveau<Diocese>(
            label: 'Diocèse',
            items: dioceses,
            nomDe: (d) => d.nom,
            idDe: (d) => d.id,
            valeurSelectionnee: selection.dioceseId,
            onDropdownChanged: (id) =>
                widget.onChanged(FiltreHierarchieSelection(dioceseId: id)),
            recherche: _rechercheDiocese,
            onRechercheChanged: (v) => setState(() => _rechercheDiocese = v),
          ),
          const SizedBox(width: 8),
          _colonneNiveau<Region>(
            label: 'Région',
            items: regions,
            nomDe: (r) => r.nom,
            idDe: (r) => r.id,
            valeurSelectionnee: selection.regionId,
            onDropdownChanged: (id) => widget.onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: id,
              ),
            ),
            recherche: _rechercheRegion,
            onRechercheChanged: (v) => setState(() => _rechercheRegion = v),
          ),
          const SizedBox(width: 8),
          _colonneNiveau<District>(
            label: 'District',
            items: districts,
            nomDe: (d) => d.nom,
            idDe: (d) => d.id,
            valeurSelectionnee: selection.districtId,
            onDropdownChanged: (id) => widget.onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: selection.regionId,
                districtId: id,
              ),
            ),
            recherche: _rechercheDistrict,
            onRechercheChanged: (v) => setState(() => _rechercheDistrict = v),
          ),
          const SizedBox(width: 8),
          _colonneNiveau<Paroisse>(
            label: 'Paroisse',
            items: paroisses,
            nomDe: (p) => p.nom,
            idDe: (p) => p.id,
            valeurSelectionnee: selection.paroisseId,
            onDropdownChanged: (id) => widget.onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: selection.regionId,
                districtId: selection.districtId,
                paroisseId: id,
              ),
            ),
            recherche: _rechercheParoisse,
            onRechercheChanged: (v) => setState(() => _rechercheParoisse = v),
          ),
          const SizedBox(width: 8),
          if (!selection.estVide)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ActionChip(
                label: const Text('Réinitialiser'),
                onPressed: () =>
                    widget.onChanged(const FiltreHierarchieSelection()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _colonneNiveau<T>({
    required String label,
    required List<T> items,
    required String Function(T) nomDe,
    required int? Function(T) idDe,
    required int? valeurSelectionnee,
    required ValueChanged<int?> onDropdownChanged,
    required String recherche,
    required ValueChanged<String> onRechercheChanged,
  }) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<int?>(
            initialValue: valeurSelectionnee,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Tous')),
              ...items
                  .where((e) => idDe(e) != null)
                  .map(
                    (e) => DropdownMenuItem<int?>(
                      value: idDe(e),
                      child: Text(nomDe(e), overflow: TextOverflow.ellipsis),
                    ),
                  ),
            ],
            onChanged: onDropdownChanged,
          ),
          const SizedBox(height: 4),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher...',
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              border: OutlineInputBorder(),
            ),
            onChanged: onRechercheChanged,
          ),
        ],
      ),
    );
  }
}

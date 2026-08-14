import 'package:flutter/material.dart';

import '../models/diocese.dart';
import '../models/district.dart';
import '../models/paroisse.dart';
import '../models/region.dart';
import '../services/filtre_hierarchie_service.dart';

/// Barre de filtres hiérarchiques en cascade : Diocèse > Région > District >
/// Paroisse. Changer un niveau réinitialise automatiquement les niveaux
/// inférieurs et notifie la sélection complète via [onChanged].
class FiltreHierarchieBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final regionsDispo = FiltreHierarchieService.regionsPour(
      regions,
      selection.dioceseId,
    );
    final districtsDispo = FiltreHierarchieService.districtsPour(
      districts,
      selection.regionId,
    );
    final paroissesDispo = FiltreHierarchieService.paroissesPour(
      paroisses,
      selection.districtId,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _dropdown<Diocese>(
            label: 'Diocèse',
            value: selection.dioceseId,
            items: dioceses,
            nomDe: (d) => d.nom,
            idDe: (d) => d.id,
            onChanged: (id) =>
                onChanged(FiltreHierarchieSelection(dioceseId: id)),
          ),
          const SizedBox(width: 8),
          _dropdown<Region>(
            label: 'Région',
            value: selection.regionId,
            items: regionsDispo,
            nomDe: (r) => r.nom,
            idDe: (r) => r.id,
            onChanged: (id) => onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: id,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _dropdown<District>(
            label: 'District',
            value: selection.districtId,
            items: districtsDispo,
            nomDe: (d) => d.nom,
            idDe: (d) => d.id,
            onChanged: (id) => onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: selection.regionId,
                districtId: id,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _dropdown<Paroisse>(
            label: 'Paroisse',
            value: selection.paroisseId,
            items: paroissesDispo,
            nomDe: (p) => p.nom,
            idDe: (p) => p.id,
            onChanged: (id) => onChanged(
              FiltreHierarchieSelection(
                dioceseId: selection.dioceseId,
                regionId: selection.regionId,
                districtId: selection.districtId,
                paroisseId: id,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (!selection.estVide)
            ActionChip(
              label: const Text('Réinitialiser'),
              onPressed: () => onChanged(const FiltreHierarchieSelection()),
            ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required int? value,
    required List<T> items,
    required String Function(T) nomDe,
    required int? Function(T) idDe,
    required ValueChanged<int?> onChanged,
  }) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int?>(
        // value: value,
        initialValue: value,
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
        onChanged: onChanged,
      ),
    );
  }
}

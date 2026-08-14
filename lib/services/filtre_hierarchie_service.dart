import '../models/district.dart';
import '../models/eglise.dart';
import '../models/paroisse.dart';
import '../models/region.dart';

/// Sélection courante dans le filtre hiérarchique
/// (Diocèse > Région > District > Paroisse).
class FiltreHierarchieSelection {
  final int? dioceseId;
  final int? regionId;
  final int? districtId;
  final int? paroisseId;

  const FiltreHierarchieSelection({
    this.dioceseId,
    this.regionId,
    this.districtId,
    this.paroisseId,
  });

  bool get estVide =>
      dioceseId == null &&
      regionId == null &&
      districtId == null &&
      paroisseId == null;
}

/// Filtre les listes hiérarchiques (Diocèse > Région > District > Paroisse)
/// et propage la sélection jusqu'aux églises, en résolvant la chaîne de FK
/// à partir des listes de référence — nécessaire tant qu'aucune vue
/// dénormalisée n'existe côté données.
class FiltreHierarchieService {
  FiltreHierarchieService._();

  static List<Region> regionsPour(List<Region> toutes, int? dioceseId) {
    if (dioceseId == null) return toutes;
    return toutes.where((r) => r.dioceseId == dioceseId).toList();
  }

  static List<District> districtsPour(List<District> tous, int? regionId) {
    if (regionId == null) return tous;
    return tous.where((d) => d.regionId == regionId).toList();
  }

  static List<Paroisse> paroissesPour(List<Paroisse> toutes, int? districtId) {
    if (districtId == null) return toutes;
    return toutes.where((p) => p.districtId == districtId).toList();
  }

  /// Applique la sélection complète à une liste plate d'églises.
  static List<Eglise> appliquerSurEglises({
    required List<Eglise> eglises,
    required List<Paroisse> paroisses,
    required List<District> districts,
    required List<Region> regions,
    required FiltreHierarchieSelection selection,
  }) {
    if (selection.estVide) return eglises;

    Set<int> paroisseIds;

    if (selection.paroisseId != null) {
      paroisseIds = {selection.paroisseId!};
    } else if (selection.districtId != null) {
      paroisseIds = paroisses
          .where((p) => p.districtId == selection.districtId)
          .map((p) => p.id)
          .whereType<int>()
          .toSet();
    } else if (selection.regionId != null) {
      final districtIds = districts
          .where((d) => d.regionId == selection.regionId)
          .map((d) => d.id)
          .whereType<int>()
          .toSet();
      paroisseIds = paroisses
          .where((p) => districtIds.contains(p.districtId))
          .map((p) => p.id)
          .whereType<int>()
          .toSet();
    } else {
      // selection.dioceseId != null
      final regionIds = regions
          .where((r) => r.dioceseId == selection.dioceseId)
          .map((r) => r.id)
          .whereType<int>()
          .toSet();
      final districtIds = districts
          .where((d) => regionIds.contains(d.regionId))
          .map((d) => d.id)
          .whereType<int>()
          .toSet();
      paroisseIds = paroisses
          .where((p) => districtIds.contains(p.districtId))
          .map((p) => p.id)
          .whereType<int>()
          .toSet();
    }

    return eglises.where((e) => paroisseIds.contains(e.paroisseId)).toList();
  }
}

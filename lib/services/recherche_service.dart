import '../models/eglise.dart';
import '../models/ressource.dart';

/// Fonctions de recherche texte, insensibles à la casse et aux accents,
/// opérant sur des listes déjà chargées en mémoire (le module Base locale /
/// SQLite fournira ensuite la vraie source de données, mais l'API de
/// recherche restera la même : on lui passe une liste, elle la filtre).
class RechercheService {
  RechercheService._();

  static String _normalise(String value) {
    const accents = 'àâäáãåèéêëìíîïòóôöõùúûüçñ';
    const sansAccents = 'aaaaaaeeeeiiiiooooouuuucn';
    var result = value.toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], sansAccents[i]);
    }
    return result;
  }

  /// Recherche par nom ou adresse. Retourne [eglises] telle quelle si
  /// [query] est vide.
  static List<Eglise> rechercherEglises(List<Eglise> eglises, String query) {
    final q = _normalise(query.trim());
    if (q.isEmpty) return eglises;
    return eglises.where((e) {
      final nomOk = _normalise(e.nom).contains(q);
      final adresseOk = e.adresse != null && _normalise(e.adresse!).contains(q);
      return nomOk || adresseOk;
    }).toList();
  }

  /// Recherche par nom ou adresse. Retourne [ressources] telle quelle si
  /// [query] est vide.
  static List<Ressource> rechercherRessources(
    List<Ressource> ressources,
    String query,
  ) {
    final q = _normalise(query.trim());
    if (q.isEmpty) return ressources;
    return ressources.where((r) {
      final nomOk = _normalise(r.nom).contains(q);
      final adresseOk = r.adresse != null && _normalise(r.adresse!).contains(q);
      return nomOk || adresseOk;
    }).toList();
  }
}

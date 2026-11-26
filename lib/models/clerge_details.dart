import 'clerge.dart';
import 'eglise.dart';
import 'photo.dart';

/// Fiche complète d'un membre du clergé : identité, rôle (libellé), photos
/// et églises dont il est le responsable actuel.
class ClergeDetails {
  final Clerge clerge;
  final String? roleNom;
  final List<Photo> photos;
  final List<Eglise> eglises;

  const ClergeDetails({
    required this.clerge,
    this.roleNom,
    this.photos = const [],
    this.eglises = const [],
  });

  String get nomComplet => '${clerge.prenom} ${clerge.nom}'.trim();
}

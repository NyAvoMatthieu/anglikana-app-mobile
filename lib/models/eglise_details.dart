import 'eglise.dart';
import 'horaire_culte.dart';
import 'photo.dart';

class EgliseDetails {
  final Eglise eglise;
  final String? responsableNom;
  final List<HoraireCulte> horaires;
  final List<Photo> photos;

  const EgliseDetails({
    required this.eglise,
    required this.responsableNom,
    required this.horaires,
    this.photos = const [],
  });
}

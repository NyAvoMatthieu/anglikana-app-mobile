import 'eglise.dart';
import 'horaire_culte.dart';

class EgliseDetails {
  final Eglise eglise;
  final String? responsableNom;
  final List<HoraireCulte> horaires;

  const EgliseDetails({
    required this.eglise,
    required this.responsableNom,
    required this.horaires,
  });
}

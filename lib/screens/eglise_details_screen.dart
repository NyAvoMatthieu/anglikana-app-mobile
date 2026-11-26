import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../database/aca_repository.dart';
import '../models/eglise_details.dart';
import '../utils/geo_utils.dart';
import '../utils/lien_utils.dart';
import '../widgets/galerie_photos.dart';
import 'clerge_details_screen.dart';

class EgliseDetailsScreen extends StatelessWidget {
  final EgliseDetails details;

  const EgliseDetailsScreen({super.key, required this.details});

  Future<void> _ouvrirResponsable(BuildContext context) async {
    final id = details.eglise.responsableId;
    if (id == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final fiche = await AcaRepository.chargerDetailsClerge(id);
    if (fiche == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fiche du responsable introuvable.')),
      );
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => ClergeDetailsScreen(details: fiche),
      ),
    );
  }

  /// « 18.7614° S, 47.5563° E » : lisible, à la place du WKT brut.
  static String _formaterPoint(LatLng p) {
    final ns = p.latitude >= 0 ? 'N' : 'S';
    final eo = p.longitude >= 0 ? 'E' : 'O';
    return '${p.latitude.abs().toStringAsFixed(5)}° $ns, '
        '${p.longitude.abs().toStringAsFixed(5)}° $eo';
  }

  @override
  Widget build(BuildContext context) {
    final eglise = details.eglise;
    final theme = Theme.of(context);
    final point = GeoUtils.parsePoint(eglise.localisation);
    final facebook = LienUtils.urlWeb(eglise.lienFacebook);
    final aResponsable =
        details.responsableNom != null && eglise.responsableId != null;

    return Scaffold(
      appBar: AppBar(title: Text(eglise.nom)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(eglise.nom, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 20),
            _Detail(label: 'Adresse', value: eglise.adresse),
            _Detail(
              label: 'Localisation',
              value: point == null
                  ? eglise.localisation
                  : _formaterPoint(point),
              action: point == null
                  ? null
                  : _Action(
                      icone: Icons.map_outlined,
                      libelle: 'Ouvrir dans Cartes',
                      onTap: () => LienUtils.ouvrir(
                        context,
                        LienUtils.carte(point, libelle: eglise.nom),
                      ),
                    ),
            ),
            _Detail(label: 'Historique', value: eglise.historique),
            _Detail(
              label: 'Page Facebook',
              value: facebook == null ? null : eglise.lienFacebook!.trim(),
              action: facebook == null
                  ? null
                  : _Action(
                      icone: Icons.open_in_new,
                      libelle: 'Ouvrir la page',
                      onTap: () => LienUtils.ouvrir(context, facebook),
                    ),
            ),
            _Detail(
              label: 'Responsable',
              value: details.responsableNom,
              action: aResponsable
                  ? _Action(
                      icone: Icons.person_outline,
                      libelle: 'Voir la fiche',
                      onTap: () => _ouvrirResponsable(context),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text('Photos', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (details.photos.isEmpty)
              const Text('Aucune photo disponible.')
            else
              GaleriePhotos(photos: details.photos),
            const SizedBox(height: 16),
            Text('Horaires de culte', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            if (details.horaires.isEmpty)
              const Text('Aucun horaire renseigné.')
            else
              ...details.horaires.map(
                (horaire) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(horaire.jour),
                    subtitle: Text(horaire.libelle ?? 'Culte'),
                    trailing: Text(
                      '${horaire.debut} - ${horaire.fin}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Action {
  final IconData icone;
  final String libelle;
  final VoidCallback onTap;

  const _Action({
    required this.icone,
    required this.libelle,
    required this.onTap,
  });
}

class _Detail extends StatelessWidget {
  final String label;
  final String? value;
  final _Action? action;

  const _Detail({required this.label, required this.value, this.action});

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim().isNotEmpty == true ? value! : '-';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(displayValue),
          if (action != null)
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 36),
                alignment: Alignment.centerLeft,
              ),
              onPressed: action!.onTap,
              icon: Icon(action!.icone, size: 18),
              label: Text(action!.libelle),
            ),
        ],
      ),
    );
  }
}

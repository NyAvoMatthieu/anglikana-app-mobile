import 'package:flutter/material.dart';

import '../database/aca_repository.dart';
import '../models/clerge_details.dart';
import '../models/eglise.dart';
import '../utils/lien_utils.dart';
import '../widgets/photo_view.dart';
import 'eglise_details_screen.dart';

/// Fiche d'un membre du clergé : photo, nom, fonction, téléphone et e-mail
/// (touchables : appel et nouveau message).
class ClergeDetailsScreen extends StatelessWidget {
  final ClergeDetails details;

  const ClergeDetailsScreen({super.key, required this.details});

  Future<void> _ouvrirEglise(BuildContext context, Eglise eglise) async {
    if (eglise.id == null) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final fiche = await AcaRepository.chargerDetailsEglise(eglise.id!);
    if (fiche == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Église introuvable.')),
      );
      return;
    }
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => EgliseDetailsScreen(details: fiche),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clerge = details.clerge;
    final theme = Theme.of(context);
    final telephone = LienUtils.telephone(clerge.telephone);
    final email = LienUtils.email(clerge.email);
    final fonction = [
      details.roleNom,
      clerge.hierarchie,
    ].whereType<String>().where((v) => v.trim().isNotEmpty).toSet().join(' · ');

    return Scaffold(
      appBar: AppBar(title: Text(details.nomComplet)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _Portrait(details: details)),
            if (details.photos.length > 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: details.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 72,
                      child: PhotoView(url: details.photos[index].url),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(details.nomComplet, style: theme.textTheme.headlineMedium),
            if (fonction.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(fonction, style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: 20),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(
                      clerge.telephone?.trim().isNotEmpty == true
                          ? clerge.telephone!
                          : 'Téléphone non renseigné',
                    ),
                    subtitle: telephone == null ? null : const Text('Appeler'),
                    enabled: telephone != null,
                    onTap: telephone == null
                        ? null
                        : () => LienUtils.ouvrir(context, telephone),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: Text(
                      clerge.email?.trim().isNotEmpty == true
                          ? clerge.email!
                          : 'E-mail non renseigné',
                    ),
                    subtitle: email == null ? null : const Text('Écrire'),
                    enabled: email != null,
                    onTap: email == null
                        ? null
                        : () => LienUtils.ouvrir(context, email),
                  ),
                ],
              ),
            ),
            if (details.eglises.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                details.eglises.length == 1
                    ? 'Responsable de l’église'
                    : 'Responsable des églises',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    for (final eglise in details.eglises)
                      ListTile(
                        leading: const Icon(Icons.church),
                        title: Text(eglise.nom),
                        subtitle: eglise.adresse?.trim().isNotEmpty == true
                            ? Text(eglise.adresse!)
                            : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _ouvrirEglise(context, eglise),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Portrait extends StatelessWidget {
  final ClergeDetails details;

  const _Portrait({required this.details});

  @override
  Widget build(BuildContext context) {
    const taille = 140.0;
    final photo = details.photos.isEmpty ? null : details.photos.first;
    return ClipOval(
      child: SizedBox(
        width: taille,
        height: taille,
        child: photo == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  size: 80,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )
            : PhotoView(url: photo.url),
      ),
    );
  }
}

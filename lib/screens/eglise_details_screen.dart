import 'package:flutter/material.dart';

import '../models/eglise_details.dart';

class EgliseDetailsScreen extends StatelessWidget {
  final EgliseDetails details;

  const EgliseDetailsScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    final eglise = details.eglise;
    return Scaffold(
      appBar: AppBar(title: Text(eglise.nom)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eglise.nom,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            _Detail(label: 'Adresse', value: eglise.adresse),
            _Detail(label: 'Localisation', value: eglise.localisation),
            _Detail(label: 'Historique', value: eglise.historique),
            _Detail(label: 'Lien Facebook', value: eglise.lienFacebook),
            _Detail(label: 'Responsable', value: details.responsableNom),
            const SizedBox(height: 16),
            Text(
              'Horaires de culte',
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
                      style: Theme.of(context).textTheme.bodyMedium,
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

class _Detail extends StatelessWidget {
  final String label;
  final String? value;

  const _Detail({required this.label, required this.value});

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
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(displayValue),
        ],
      ),
    );
  }
}

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
              'Photos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (details.photos.isEmpty)
              const Text('Aucune photo disponible.')
            else
              SizedBox(
                height: 220,
                child: PageView.builder(
                  itemCount: details.photos.length,
                  itemBuilder: (context, index) {
                    final photo = details.photos[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _PhotoView(url: photo.url),
                            ),
                          ),
                          if (photo.description?.trim().isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                photo.description!,
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
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

class _PhotoView extends StatelessWidget {
  final String url;

  const _PhotoView({required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PhotoError(),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const _PhotoError(),
      );
    }
    return const _PhotoError();
  }
}

class _PhotoError extends StatelessWidget {
  const _PhotoError();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE0E0E0),
      child: Center(
        child: Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

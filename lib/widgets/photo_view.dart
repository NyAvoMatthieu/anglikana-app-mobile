import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Affiche une photo depuis un asset ou une URL http(s).
/// Les photos réseau sont mises en cache sur disque : une photo déjà vue
/// reste disponible hors ligne.
class PhotoView extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const PhotoView({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: fit,
        errorBuilder: (_, _, _) => const PhotoErreur(),
      );
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        placeholder: (_, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, _, _) => const PhotoErreur(),
      );
    }
    return const PhotoErreur();
  }
}

class PhotoErreur extends StatelessWidget {
  const PhotoErreur({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFE0E0E0),
      child: Center(child: Icon(Icons.broken_image_outlined)),
    );
  }
}

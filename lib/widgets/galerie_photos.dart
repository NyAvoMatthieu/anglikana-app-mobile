import 'package:flutter/material.dart';

import '../models/photo.dart';
import 'photo_view.dart';

/// Galerie de photos : défilement horizontal avec compteur « 2 / 5 »,
/// légende, et plein écran (zoom par pincement) au toucher.
class GaleriePhotos extends StatefulWidget {
  final List<Photo> photos;
  final double hauteur;

  const GaleriePhotos({super.key, required this.photos, this.hauteur = 240});

  @override
  State<GaleriePhotos> createState() => _GaleriePhotosState();
}

class _GaleriePhotosState extends State<GaleriePhotos> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _ouvrirPleinEcran(int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _PhotosPleinEcran(photos: widget.photos, indexInitial: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    final legende = photos[_index].description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.hauteur,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GestureDetector(
                    onTap: () => _ouvrirPleinEcran(i),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PhotoView(url: photos[i].url),
                    ),
                  ),
                ),
              ),
              if (photos.length > 1)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        '${_index + 1} / ${photos.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (legende.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(legende, textAlign: TextAlign.center),
          ),
      ],
    );
  }
}

class _PhotosPleinEcran extends StatefulWidget {
  final List<Photo> photos;
  final int indexInitial;

  const _PhotosPleinEcran({required this.photos, required this.indexInitial});

  @override
  State<_PhotosPleinEcran> createState() => _PhotosPleinEcranState();
}

class _PhotosPleinEcranState extends State<_PhotosPleinEcran> {
  late final PageController _controller = PageController(
    initialPage: widget.indexInitial,
  );
  late int _index = widget.indexInitial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.photos.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.photos.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, i) => InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: PhotoView(url: widget.photos[i].url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

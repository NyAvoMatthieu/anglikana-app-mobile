import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouverture de liens externes (navigateur, téléphone, mail, cartes).
class LienUtils {
  LienUtils._();

  /// Ajoute `https://` si l'URL n'a pas de schéma (« facebook.com/xyz »).
  static Uri? urlWeb(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final avecSchema = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://').hasMatch(value)
        ? value
        : 'https://$value';
    final uri = Uri.tryParse(avecSchema);
    if (uri == null || !uri.hasAuthority) return null;
    return uri;
  }

  /// `tel:` : on ne garde que les chiffres et le « + » initial.
  static Uri? telephone(String? raw) {
    final value = raw?.trim() ?? '';
    final chiffres = value.replaceAll(RegExp(r'[^\d+]'), '');
    if (chiffres.isEmpty) return null;
    return Uri(scheme: 'tel', path: chiffres);
  }

  static Uri? email(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !value.contains('@')) return null;
    return Uri(scheme: 'mailto', path: value);
  }

  /// Lien de carte universel (ouvre Google Maps / l'app de cartes).
  static Uri carte(LatLng point, {String? libelle}) =>
      Uri.https('www.google.com', '/maps/search/', {
        'api': '1',
        'query': '${point.latitude},${point.longitude}',
      });

  /// Ouvre [uri] ; affiche un message si rien ne peut le gérer.
  static Future<void> ouvrir(BuildContext context, Uri? uri) async {
    final messenger = ScaffoldMessenger.of(context);
    var ok = false;
    if (uri != null) {
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir ce lien.')),
      );
    }
  }
}

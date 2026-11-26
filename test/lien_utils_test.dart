import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:anglikana_app_mobile/utils/lien_utils.dart';

void main() {
  test('urlWeb ajoute https:// quand le schéma manque', () {
    expect(
      LienUtils.urlWeb('facebook.com/eglise.test').toString(),
      'https://facebook.com/eglise.test',
    );
    expect(
      LienUtils.urlWeb(' https://facebook.com/x ').toString(),
      'https://facebook.com/x',
    );
  });

  test('urlWeb refuse vide et invalide', () {
    expect(LienUtils.urlWeb(null), isNull);
    expect(LienUtils.urlWeb('   '), isNull);
    expect(LienUtils.urlWeb('https://'), isNull);
  });

  test('telephone garde chiffres et + initial', () {
    expect(
      LienUtils.telephone('+261 34 12 345 67').toString(),
      'tel:+261341234567',
    );
    expect(LienUtils.telephone('abc'), isNull);
    expect(LienUtils.telephone(null), isNull);
  });

  test('email exige un @', () {
    expect(LienUtils.email('pere@aca.mg').toString(), 'mailto:pere@aca.mg');
    expect(LienUtils.email('pas-un-mail'), isNull);
  });

  test('carte : lat,lon dans la requête', () {
    final uri = LienUtils.carte(const LatLng(-18.7614, 47.5563));
    expect(uri.host, 'www.google.com');
    expect(uri.queryParameters['query'], '-18.7614,47.5563');
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anglikana_app_mobile/models/eglise.dart';
import 'package:anglikana_app_mobile/models/eglise_details.dart';
import 'package:anglikana_app_mobile/models/horaire_culte.dart';
import 'package:anglikana_app_mobile/screens/eglise_details_screen.dart';

void main() {
  Future<void> afficher(WidgetTester tester, EgliseDetails details) {
    return tester.pumpWidget(
      MaterialApp(home: EgliseDetailsScreen(details: details)),
    );
  }

  testWidgets('localisation lisible, Facebook et responsable cliquables', (
    tester,
  ) async {
    await afficher(
      tester,
      EgliseDetails(
        eglise: Eglise(
          id: 1,
          nom: 'Sainte-Marie',
          adresse: 'Analakely',
          localisation: 'POINT(47.5563 -18.7614)',
          lienFacebook: 'facebook.com/sainte.marie',
          responsableId: 5,
        ),
        responsableNom: 'Hery Randrianarisoa',
        horaires: [
          HoraireCulte(jour: 'Dimanche', debut: '08:00', fin: '10:00'),
        ],
        photos: const [],
      ),
    );

    expect(find.textContaining('POINT('), findsNothing);
    expect(find.text('18.76140° S, 47.55630° E'), findsOneWidget);
    expect(find.text('Ouvrir dans Cartes'), findsOneWidget);
    expect(find.text('Ouvrir la page'), findsOneWidget);
    expect(find.text('Voir la fiche'), findsOneWidget);
    expect(find.text('Hery Randrianarisoa'), findsOneWidget);
    expect(find.text('Aucune photo disponible.'), findsOneWidget);
  });

  testWidgets('sans Facebook ni responsable : pas de boutons', (tester) async {
    await afficher(
      tester,
      EgliseDetails(
        eglise: Eglise(id: 2, nom: 'Chapelle'),
        responsableNom: null,
        horaires: const [],
        photos: const [],
      ),
    );

    expect(find.text('Ouvrir la page'), findsNothing);
    expect(find.text('Voir la fiche'), findsNothing);
    expect(find.text('Ouvrir dans Cartes'), findsNothing);
    expect(find.text('Aucun horaire renseigné.'), findsOneWidget);
  });
}

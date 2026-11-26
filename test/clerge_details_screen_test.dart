import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anglikana_app_mobile/models/clerge.dart';
import 'package:anglikana_app_mobile/models/clerge_details.dart';
import 'package:anglikana_app_mobile/models/eglise.dart';
import 'package:anglikana_app_mobile/screens/clerge_details_screen.dart';

void main() {
  Future<void> afficher(WidgetTester tester, ClergeDetails details) {
    return tester.pumpWidget(
      MaterialApp(home: ClergeDetailsScreen(details: details)),
    );
  }

  testWidgets('fiche complète : contacts actifs, fonction, églises', (
    tester,
  ) async {
    await afficher(
      tester,
      ClergeDetails(
        clerge: Clerge(
          id: 5,
          nom: 'Randrianarisoa',
          prenom: 'Hery',
          hierarchie: 'Prêtre',
          telephone: '+261 34 12 345 67',
          email: 'hery@aca.mg',
        ),
        roleNom: 'Recteur',
        eglises: [Eglise(id: 1, nom: 'Sainte-Marie', adresse: 'Analakely')],
      ),
    );

    expect(find.text('Hery Randrianarisoa'), findsNWidgets(2)); // titre + corps
    expect(find.text('Recteur · Prêtre'), findsOneWidget);
    expect(find.text('+261 34 12 345 67'), findsOneWidget);
    expect(find.text('Appeler'), findsOneWidget);
    expect(find.text('hery@aca.mg'), findsOneWidget);
    expect(find.text('Écrire'), findsOneWidget);
    expect(find.text('Responsable de l’église'), findsOneWidget);
    expect(find.text('Sainte-Marie'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget); // pas de photo
  });

  testWidgets('sans téléphone ni e-mail : lignes désactivées', (tester) async {
    await afficher(
      tester,
      ClergeDetails(clerge: Clerge(id: 6, nom: 'Rakoto', prenom: 'Miora')),
    );

    expect(find.text('Téléphone non renseigné'), findsOneWidget);
    expect(find.text('E-mail non renseigné'), findsOneWidget);
    expect(find.text('Appeler'), findsNothing);
    expect(find.text('Écrire'), findsNothing);
    expect(find.textContaining('Responsable de'), findsNothing);
  });
}

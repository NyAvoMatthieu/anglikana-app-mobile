// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anglikana_app_mobile/models/diocese.dart';
import 'package:anglikana_app_mobile/models/district.dart';
import 'package:anglikana_app_mobile/models/eglise.dart';
import 'package:anglikana_app_mobile/models/paroisse.dart';
import 'package:anglikana_app_mobile/models/region.dart';
import 'package:anglikana_app_mobile/models/ressource.dart';
import 'package:anglikana_app_mobile/screens/carte_screen.dart';

void main() {
  testWidgets(
    'La carte affiche un bloc unique pour les filtres géographiques.',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CarteScreen(
            eglises: const <Eglise>[],
            ressources: const <Ressource>[],
            dioceses: const <Diocese>[],
            regions: const <Region>[],
            districts: const <District>[],
            paroisses: const <Paroisse>[],
          ),
        ),
      );

      expect(find.text('Filtres géographiques'), findsOneWidget);
      expect(find.text('Rechercher un diocèse'), findsNothing);
      expect(find.text('Rechercher une région'), findsNothing);
      expect(find.text('Rechercher un district'), findsNothing);
    },
  );
}

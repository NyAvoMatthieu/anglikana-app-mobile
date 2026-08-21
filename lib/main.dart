import 'package:flutter/material.dart';

import 'database/aca_repository.dart';
import 'database/database_helper.dart';
import 'database/donnees_test.dart';
import 'models/diocese.dart';
import 'models/district.dart';
import 'models/eglise.dart';
import 'models/paroisse.dart';
import 'models/region.dart';
import 'models/ressource.dart';
import 'screens/carte_screen.dart';
import 'services/offline_map_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineMapService.initialise();

  await DatabaseHelper.instance.database; // ouvre/crée la base SQLite
  await DonneesTest.insererSiVide();

  final dioceses = await AcaRepository.chargerDioceses();
  final regions = await AcaRepository.chargerRegions();
  final districts = await AcaRepository.chargerDistricts();
  final paroisses = await AcaRepository.chargerParoisses();
  final eglises = await AcaRepository.chargerEglises();
  final ressources = await AcaRepository.chargerRessources();

  runApp(
    MyApp(
      dioceses: dioceses,
      regions: regions,
      districts: districts,
      paroisses: paroisses,
      eglises: eglises,
      ressources: ressources,
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<Diocese> dioceses;
  final List<Region> regions;
  final List<District> districts;
  final List<Paroisse> paroisses;
  final List<Eglise> eglises;
  final List<Ressource> ressources;

  const MyApp({
    super.key,
    required this.dioceses,
    required this.regions,
    required this.districts,
    required this.paroisses,
    required this.eglises,
    required this.ressources,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACA',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: CarteScreen(
        dioceses: dioceses,
        regions: regions,
        districts: districts,
        paroisses: paroisses,
        eglises: eglises,
        ressources: ressources,
      ),
    );
  }
}

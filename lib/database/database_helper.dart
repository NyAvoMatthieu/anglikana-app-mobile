import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Ouvre et initialise la base SQLite locale, miroir du schéma PostgreSQL
/// (hiérarchie ecclésiale + ressources + clergé + utilisateurs).
///
/// Ce fichier crée uniquement le schéma. La synchronisation
/// PostgreSQL -> SQLite (module suivant) remplira les tables via les
/// méthodes génériques ci-dessous ou des DAO dédiés à écrire à ce moment-là.
///
/// Dépendances à ajouter dans pubspec.yaml si absentes :
///   sqflite: ^2.3.0
///   path: ^1.9.0
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _dbName = 'aca.db';
  static const int _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // --- Référentiels indépendants -----------------------------------
    batch.execute('''
      CREATE TABLE role (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        niveau INTEGER NOT NULL,
        description TEXT
      )
    ''');

    batch.execute('''
      CREATE TABLE clerge (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        date_naissance TEXT,
        hierarchie TEXT,
        telephone TEXT,
        email TEXT,
        role_id INTEGER REFERENCES role(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE utilisateur (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom_utilisateur TEXT NOT NULL UNIQUE,
        mot_de_passe TEXT NOT NULL,
        actif INTEGER NOT NULL DEFAULT 1,
        clerge_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE type_ressource (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL
      )
    ''');

    // --- Hiérarchie ecclésiale -----------------------------------------
    batch.execute('''
      CREATE TABLE diocese (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        carte_qgis TEXT,
        presentation TEXT,
        coordonnees TEXT,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE region (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        diocese_id INTEGER REFERENCES diocese(id) ON DELETE CASCADE,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE district (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        carte_qgis TEXT,
        region_id INTEGER REFERENCES region(id) ON DELETE CASCADE,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE paroisse (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        carte_qgis TEXT,
        district_id INTEGER REFERENCES district(id) ON DELETE CASCADE,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE eglise (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        adresse TEXT,
        localisation TEXT,
        historique TEXT,
        lien_facebook TEXT,
        paroisse_id INTEGER REFERENCES paroisse(id) ON DELETE CASCADE,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE horaire_culte (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        jour TEXT NOT NULL,
        libelle TEXT,
        debut TEXT NOT NULL,
        fin TEXT NOT NULL,
        eglise_id INTEGER REFERENCES eglise(id) ON DELETE CASCADE
      )
    ''');

    // --- Ressources ------------------------------------------------------
    batch.execute('''
      CREATE TABLE ressource (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nom TEXT NOT NULL,
        adresse TEXT,
        localisation TEXT,
        type_id INTEGER REFERENCES type_ressource(id) ON DELETE SET NULL,
        eglise_id INTEGER REFERENCES eglise(id) ON DELETE CASCADE,
        responsable_id INTEGER REFERENCES clerge(id) ON DELETE SET NULL
      )
    ''');

    // --- Contenus polymorphes (pas de FK typée, par design) --------------
    batch.execute('''
      CREATE TABLE photo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        description TEXT,
        date_ajout TEXT,
        type_entite TEXT NOT NULL,
        entite_id INTEGER NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE contribution (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type_entite TEXT NOT NULL,
        entite_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        date_contribution TEXT,
        statut TEXT,
        commentaire TEXT,
        date_validation TEXT,
        utilisateur_id INTEGER REFERENCES utilisateur(id) ON DELETE SET NULL,
        validateur_id INTEGER REFERENCES utilisateur(id) ON DELETE SET NULL
      )
    ''');

    // --- Index utiles pour la recherche/filtre déjà en place -------------
    batch.execute('CREATE INDEX idx_region_diocese ON region(diocese_id)');
    batch.execute('CREATE INDEX idx_district_region ON district(region_id)');
    batch.execute(
      'CREATE INDEX idx_paroisse_district ON paroisse(district_id)',
    );
    batch.execute('CREATE INDEX idx_eglise_paroisse ON eglise(paroisse_id)');
    batch.execute(
      'CREATE INDEX idx_horaire_eglise ON horaire_culte(eglise_id)',
    );
    batch.execute('CREATE INDEX idx_ressource_eglise ON ressource(eglise_id)');
    batch.execute('CREATE INDEX idx_ressource_type ON ressource(type_id)');
    batch.execute(
      'CREATE INDEX idx_photo_entite ON photo(type_entite, entite_id)',
    );
    batch.execute(
      'CREATE INDEX idx_contribution_entite ON contribution(type_entite, entite_id)',
    );

    await batch.commit(noResult: true);
  }

  // --- Utilitaires génériques ---------------------------------------------

  /// Insère [donnees] (typiquement `modele.toJson()`) dans [table] et
  /// retourne l'id généré. Remplace en cas de conflit sur la clé primaire.
  Future<int> inserer(String table, Map<String, dynamic> donnees) async {
    final db = await database;
    return db.insert(
      table,
      donnees,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupère toutes les lignes de [table], optionnellement filtrées.
  Future<List<Map<String, dynamic>>> tout(
    String table, {
    String? where,
    List<Object?>? whereArgs,
    String? orderBy,
  }) async {
    final db = await database;
    return db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
    );
  }

  /// Supprime toutes les données de toutes les tables (avant une
  /// resynchronisation complète depuis PostgreSQL, par exemple).
  Future<void> viderToutesLesTables() async {
    final db = await database;
    await db.transaction((txn) async {
      const tables = [
        'contribution',
        'photo',
        'ressource',
        'type_ressource',
        'horaire_culte',
        'eglise',
        'paroisse',
        'district',
        'region',
        'diocese',
        'utilisateur',
        'clerge',
        'role',
      ];
      for (final table in tables) {
        await txn.delete(table);
      }
    });
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}

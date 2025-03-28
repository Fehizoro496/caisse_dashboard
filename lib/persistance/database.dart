import 'package:drift/drift.dart';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:uuid/uuid.dart'; // Ajouter cette dépendance dans pubspec.yaml

part 'database.g.dart';

// Ajout de la fonction helper pour générer des UID
String generateUid() => const Uuid().v4();

class Depenses extends Table {
  TextColumn get idDepense => text()(); // Changed from IntColumn
  TextColumn get libelle => text()();
  IntColumn get montant => integer()();
  DateTimeColumn get dateDepense => dateTime()();
}

class Operations extends Table {
  TextColumn get idOperation => text()(); // Changed from IntColumn
  TextColumn get nomOperation => text()();
  IntColumn get prixOperation => integer()();
  IntColumn get quantiteOperation => integer()();
  TextColumn get facture =>
      text().references(Factures, #idFacture).nullable()(); // Changed reference
  DateTimeColumn get dateOperation => dateTime()();
}

class Factures extends Table {
  TextColumn get idFacture => text()(); // Changed from IntColumn
  TextColumn get client => text()();
  DateTimeColumn get dateFacture => dateTime()();
}

class ReglementsFacture extends Table {
  TextColumn get idReglement => text()(); // Changed from IntColumn
  IntColumn get montant => integer()();
  DateTimeColumn get dateReglement => dateTime()();
  TextColumn get facture =>
      text().references(Factures, #idFacture)(); // Changed reference
}

class Prelevements extends Table {
  TextColumn get idPrelevement => text()(); // Changed from IntColumn
  IntColumn get montant => integer()();
  DateTimeColumn get datePrelevement => dateTime()();
}

class Releves extends Table {
  TextColumn get idReleve => text()(); // Changed from IntColumn
  RealColumn get compteur => real()();
  RealColumn get sousCompteur => real()();
  DateTimeColumn get dateReleve => dateTime()();
}

@DriftDatabase(tables: [Operations, Factures, Depenses, Prelevements, Releves])
class AppDatabase extends _$AppDatabase {
  // Private constructor
  AppDatabase._() : super(_openConnection());

  // Named constructor for testing/import purposes
  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  // Static instance
  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 8; // Increment schema version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        await m.createAll();
      },
      beforeOpen: (details) async {
        if (kDebugMode) {}
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationCacheDirectory();
    final file = File(p.join(dbFolder.path, 'caisse_dashboard.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;
    return NativeDatabase.createInBackground(file);
  });
}

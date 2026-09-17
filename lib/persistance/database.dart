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

/// Charges fixes du mois — loyer, fournitures, factures.
///
/// Ce n'est pas une dépense : une dépense tombe un jour donné, une charge vaut
/// pour un mois entier et n'est imputée qu'au cadrage Mois du tableau de bord.
/// Les montants varient d'un mois à l'autre (une facture JIRAMA n'est pas un
/// loyer), d'où une ligne par couple (libellé, mois) plutôt qu'un modèle
/// d'abonnement à montant unique.
class Charges extends Table {
  TextColumn get idCharge => text()();
  TextColumn get libelle => text()();

  /// Prix d'une unité. Le total de la ligne vaut `prixUnitaire * quantite` :
  /// une charge n'est pas toujours un montant nu — trois ramettes ou deux
  /// bidons se saisissent au prix unitaire, comme une opération.
  IntColumn get prixUnitaire => integer()();

  /// Nombre d'unités. Vaut 1 pour un loyer ou une facture, qui ne se comptent
  /// pas. Le défaut est une constante, donc identique que la colonne sorte
  /// d'un CREATE ou d'un ALTER — contrairement au piège de `dateEnregistrement`.
  IntColumn get quantite => integer().withDefault(const Constant(1))();

  /// Premier jour du mois d'imputation, à 00:00 — voir `normalizeMois`.
  /// C'est lui, et lui seul, qui décide du cadrage où la charge est comptée.
  DateTimeColumn get mois => dateTime()();

  /// Jour de la saisie, à 00:00 — voir `normalizeJour`. Distinct de [mois] à
  /// dessein : le loyer d'août réglé le 3 septembre s'impute à août tout en
  /// s'enregistrant en septembre. Sans effet sur les totaux — c'est une trace,
  /// pas une clé. Pas d'heure : une charge se règle dans une journée, pas à
  /// une minute près.
  ///
  /// Sans `withDefault` volontairement : un défaut SQL ne serait pas le même
  /// selon que la table sort d'un `CREATE` ou d'un `ALTER` (voir la migration
  /// v10 → v11), et drift s'en remettrait à lui sur les insertions muettes.
  /// Valeur toujours fournie côté Dart, donc jamais de divergence.
  DateTimeColumn get dateEnregistrement => dateTime()();

  /// Catégorie choisie à la saisie. Nullable : les charges antérieures à cette
  /// colonne n'en portent pas, et retombent alors sur la déduction par mots-clés
  /// — voir `CategoryRules.resolveCharge`. C'est la seule table dont la catégorie est
  /// stockée ; celle d'une dépense reste dérivée de son libellé.
  TextColumn get categorie => text().nullable()();
}

/// Ramène une date au premier jour de son mois. Toute écriture dans `Charges`
/// passe par là : deux charges du même mois doivent porter la même clé.
DateTime normalizeMois(DateTime d) => DateTime(d.year, d.month);

/// Ramène une date à son jour, à 00:00. Les charges ne portent pas d'heure :
/// la retirer à l'écriture évite qu'un `DateTime.now()` en laisse traîner une
/// que plus rien n'affiche.
DateTime normalizeJour(DateTime d) => DateTime(d.year, d.month, d.day);

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

class FacturesJiro extends Table {
  TextColumn get idFactureJiro => text()();
  TextColumn get mois => text()(); // "Janvier 2026"
  DateTimeColumn get dateAncienIndex => dateTime()(); // Date de l'ancien relevé
  DateTimeColumn get dateNouvelIndex => dateTime()(); // Date du nouveau relevé
  RealColumn get ancienIndexCompteur => real()();
  RealColumn get nouvelIndexCompteur => real()();
  RealColumn get ancienIndexSousCompteur => real()();
  RealColumn get nouvelIndexSousCompteur => real()();
  RealColumn get prixUnitaireKwh => real()();
  RealColumn get redevanceJirama => real()();
  RealColumn get primeFixeJirama => real()();
  RealColumn get taxesRedevances => real()();
  RealColumn get tva => real()();
  DateTimeColumn get dateFacture => dateTime()(); // Date de création
}

@DriftDatabase(
  tables: [
    Operations,
    Factures,
    Depenses,
    Prelevements,
    Releves,
    FacturesJiro,
    Charges,
  ],
)
class AppDatabase extends _$AppDatabase {
  // Private constructor
  AppDatabase._() : super(_openConnection());

  // Named constructor for testing/import purposes
  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  // Static instance
  static final AppDatabase instance = AppDatabase._();

  @override
  int get schemaVersion => 13; // Increment schema version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // `createAll` émet des CREATE TABLE IF NOT EXISTS : ajouter une table
        // (v9 → v10, `Charges`) ne demande donc aucune migration écrite. Une
        // colonne ajoutée à une table existante, en revanche, en exige une —
        // `createAll` laisse intacte une table déjà là.
        await m.createAll();

        // Les pas suivants ne concernent QUE les bases où `Charges`
        // existait déjà : venant d'avant la v10, la table sort de `createAll`
        // avec toutes ses colonnes, et les rajouter lèverait « duplicate
        // column name ». D'où des conditions sur des versions précises, et non
        // sur `from < n`.

        // v10 → v11 : `dateEnregistrement`.
        if (from == 10) {
          // SQLite refuse un DEFAULT non constant sur ALTER TABLE : pas de
          // CURRENT_TIMESTAMP ici. On ajoute donc la colonne à zéro, puis on
          // date les lignes existantes du premier jour du mois qu'elles
          // couvrent — la seule date que ces lignes connaissent, et celle qui
          // évite de les faire passer pour des saisies hors délai.
          await m.database.customStatement(
            'ALTER TABLE charges ADD COLUMN date_enregistrement '
            'INTEGER NOT NULL DEFAULT 0',
          );
          await m.database.customStatement(
            'UPDATE charges SET date_enregistrement = mois',
          );
        }

        // v11 → v12 : `categorie`. Nullable, donc pas de DEFAULT à fournir et
        // rien à rétro-remplir : les lignes sans catégorie choisie retombent
        // sur la déduction par mots-clés, exactement comme avant la colonne.
        if (from == 10 || from == 11) {
          await m.database.customStatement(
            'ALTER TABLE charges ADD COLUMN categorie TEXT NULL',
          );
        }

        // v12 -> v13 : la quantite, et `montant` qui devient `prix_unitaire`.
        // Le DEFAULT 1 est constant, donc accepte par ALTER TABLE, et laisse
        // les lignes existantes a leur total d'origine.
        if (from >= 10 && from < 13) {
          await m.database.customStatement(
            'ALTER TABLE charges ADD COLUMN quantite INTEGER NOT NULL DEFAULT 1',
          );
          await m.database.customStatement(
            'ALTER TABLE charges RENAME COLUMN montant TO prix_unitaire',
          );
        }
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

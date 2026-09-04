import 'dart:io';

import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// `Charges` a gagné deux colonnes après coup : `dateEnregistrement` (v11)
/// puis `categorie` (v12). Trois chemins mènent donc à la v12, et ils ne font
/// pas la même chose — venant d'avant la v10 la table sort de `createAll`
/// complète, alors qu'au-delà il faut la compléter par des ALTER. Se tromper
/// de condition rend la base illisible au lancement, sans que rien d'autre ne
/// le signale.
void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('charges_migration'));
  tearDown(() => dir.deleteSync(recursive: true));

  /// Écrit un fichier SQLite au schéma demandé, sans passer par drift.
  /// [colonnesCharges] décrit la table `charges` telle qu'elle existait à la
  /// version visée — vide pour les schémas antérieurs à la table.
  File seed(int userVersion, {String? colonnesCharges, String? valeurs}) {
    final file = File(p.join(dir.path, 'v$userVersion.sqlite'));
    final db = sqlite3.open(file.path);
    // Une table du socle commun, pour vérifier qu'aucune migration ne la perd.
    db.execute('''
      CREATE TABLE depenses (
        id_depense TEXT NOT NULL,
        libelle TEXT NOT NULL,
        montant INTEGER NOT NULL,
        date_depense INTEGER NOT NULL
      );
    ''');
    db.execute(
      "INSERT INTO depenses VALUES ('d1', 'Ramette A4', 18500, 1755000000);",
    );
    if (colonnesCharges != null) {
      db.execute('CREATE TABLE charges ($colonnesCharges);');
      db.execute('INSERT INTO charges VALUES ($valeurs);');
    }
    db.execute('PRAGMA user_version = $userVersion;');
    db.dispose();
    return file;
  }

  /// La table `charges` de la v10 : ni date d'enregistrement, ni catégorie.
  const v10 = '''
    id_charge TEXT NOT NULL,
    libelle TEXT NOT NULL,
    montant INTEGER NOT NULL,
    mois INTEGER NOT NULL
  ''';

  /// Celle de la v11 : la date est là, la catégorie pas encore.
  const v11 = '''
    id_charge TEXT NOT NULL,
    libelle TEXT NOT NULL,
    montant INTEGER NOT NULL,
    mois INTEGER NOT NULL,
    date_enregistrement INTEGER NOT NULL
  ''';

  test('v10 → v12 : les deux colonnes arrivent, la charge survit', () async {
    final db = AppDatabase.fromFile(
      seed(10, colonnesCharges: v10, valeurs: "'c1', 'Loyer', 350000, 1754000000"),
    );
    addTearDown(db.close);

    final charge = await db.select(db.charges).getSingle();
    expect(charge.libelle, 'Loyer');
    expect(charge.montant, 350000);
    // Faute de mieux, la ligne d'avant la colonne est datée du mois qu'elle
    // couvre — donc jamais signalée comme saisie hors délai.
    expect(charge.dateEnregistrement, charge.mois);
    // Aucune catégorie n'a été choisie pour elle : la déduction reprend la main.
    expect(charge.categorie, isNull);
    expect(CategoryRules.resolveCharge(charge.categorie, charge.libelle), 'Loyer');

    // La dépense du socle n'a pas été emportée par la migration.
    expect(await db.select(db.depenses).get(), hasLength(1));
  });

  test('v11 → v12 : seule la catégorie manque, la date est préservée', () async {
    final db = AppDatabase.fromFile(
      seed(
        11,
        colonnesCharges: v11,
        // Enregistrée le 12, pour un mois d'août : la date ne doit pas être
        // écrasée par le pas v10 → v11, qui ne la concerne plus.
        valeurs: "'c1', 'Facture JIRAMA', 95000, 1754000000, 1754956800",
      ),
    );
    addTearDown(db.close);

    final charge = await db.select(db.charges).getSingle();
    expect(charge.categorie, isNull);
    expect(charge.dateEnregistrement.millisecondsSinceEpoch, 1754956800 * 1000);
    expect(charge.dateEnregistrement, isNot(charge.mois));
  });

  test('v9 → v12 : la table naît complète, sans double ajout de colonne', () async {
    final db = AppDatabase.fromFile(seed(9));
    addTearDown(db.close);

    // Le piège : un ALTER inconditionnel lèverait ici « duplicate column
    // name », la table sortant déjà complète de `createAll`.
    expect(await db.select(db.charges).get(), isEmpty);
    expect(await db.select(db.depenses).get(), hasLength(1));

    // Et la table est bien utilisable dans la foulée, catégorie comprise.
    await db
        .into(db.charges)
        .insert(
          ChargesCompanion.insert(
            idCharge: 'x',
            libelle: 'Cotisation association',
            montant: 120000,
            mois: DateTime(2026, 8),
            dateEnregistrement: DateTime(2026, 8, 12),
            categorie: const Value('Facture'),
          ),
        );
    final inserted = await db.select(db.charges).getSingle();
    expect(inserted.montant, 120000);
    expect(inserted.mois, DateTime(2026, 8));
    // Le choix explicite prime sur la déduction, qui dirait « Divers » ici.
    expect(CategoryRules.ofCharge('Cotisation association'), 'Divers');
    expect(
      CategoryRules.resolveCharge(inserted.categorie, inserted.libelle),
      'Facture',
    );
  });
}

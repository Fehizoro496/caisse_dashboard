import 'dart:io';
import 'dart:typed_data';

import 'package:caisse_dashboard/persistance/database.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Bilan d'un import : ce qui est entré, ce qui était déjà là.
/// La fusion se fait par identifiant — rien n'est jamais écrasé.
class ImportResult {
  const ImportResult({required this.added, required this.skipped});

  final int added;
  final int skipped;
}

class SyncService extends GetxService {
  final database = AppDatabase.instance;

  // Add constant key (in production, use secure storage instead)
  static final _encryptionKey = encrypt.Key.fromUtf8(
    '12345678901234567890123456789012',
  );

  /// Nom du fichier SQLite, aligné sur `_openConnection()` de la base.
  static const _dbFileName = 'caisse_dashboard.sqlite';

  Future<SyncService> init() async {
    return this;
  }

  Future<File> _databaseFile() async {
    final dbFolder = await getApplicationCacheDirectory();
    return File(p.join(dbFolder.path, _dbFileName));
  }

  /// Écrit une archive chiffrée `[IV | clé | données]` — le même format que
  /// celui attendu par [decryptBackup], donc relisible par l'import.
  /// Retourne le chemin du fichier produit.
  Future<String> exportDatabase({String? targetDirectory}) async {
    final dbFile = await _databaseFile();
    if (!await dbFile.exists()) {
      throw StateError('Base introuvable : ${dbFile.path}');
    }

    final databaseContent = await dbFile.readAsBytes();

    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));
    final encrypted = encrypter.encryptBytes(databaseContent, iv: iv);

    final dir =
        targetDirectory ??
        Platform.environment['USERPROFILE'] ??
        (await getApplicationDocumentsDirectory()).path;
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.-]'), '_')
        .split('_')
        .take(6)
        .join('_');
    final backupFile = File(p.join(dir, 'backup_caisse_$timestamp.enc'));

    await backupFile.writeAsBytes([
      ...iv.bytes,
      ..._encryptionKey.bytes,
      ...encrypted.bytes,
    ]);
    return backupFile.path;
  }

  // Fonction pour décrypter (à utiliser lors de la restauration)
  Future<Uint8List> decryptBackup(String backupPath) async {
    final backupFile = File(backupPath);
    final List<int> fileBytes = await backupFile.readAsBytes();

    // Extraire IV (16 bytes), clé (32 bytes) et données cryptées
    final iv = encrypt.IV(Uint8List.fromList(fileBytes.sublist(0, 16)));
    final key = encrypt.Key(Uint8List.fromList(fileBytes.sublist(16, 48)));
    final encryptedBytes = Uint8List.fromList(fileBytes.sublist(48));

    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypt.Encrypted(encryptedBytes);

    final decryptedBytes = encrypter.decryptBytes(encrypted, iv: iv);
    return Uint8List.fromList(decryptedBytes);
  }

  /// Fusionne une sauvegarde dans la base courante. Lève si le fichier n'est
  /// pas déchiffrable ; dans ce cas la base locale reste intacte.
  Future<ImportResult> importAndMergeDatabase(String backupPath) async {
    // Décrypter le fichier de backup
    final decryptedData = await decryptBackup(backupPath);

    // Créer un fichier temporaire pour la base de données importée
    final tempDir = await getTemporaryDirectory();
    final tempDbFile = File(p.join(tempDir.path, 'temp_import.sqlite'));
    await tempDbFile.writeAsBytes(decryptedData);

    // Ouvrir la base de données temporaire
    final importedDb = AppDatabase.fromFile(tempDbFile);
    var added = 0;
    var skipped = 0;

    try {
      // Récupérer toutes les données de la base importée
      final importedOperations = await importedDb
          .select(importedDb.operations)
          .get();
      final importedDepenses = await importedDb
          .select(importedDb.depenses)
          .get();
      final importedPrelevements = await importedDb
          .select(importedDb.prelevements)
          .get();
      final importedReleves = await importedDb.select(importedDb.releves).get();
      final importedFactures = await importedDb
          .select(importedDb.factures)
          .get();
      // Une sauvegarde antérieure aux charges (schéma ≤ 9) n'a pas la table :
      // drift la crée à l'ouverture, mais une archive écrite hors drift
      // pourrait ne pas déclencher la migration. L'absence de charges ne doit
      // pas faire échouer l'import du reste.
      List<Charge> importedCharges;
      try {
        importedCharges = await importedDb.select(importedDb.charges).get();
      } catch (_) {
        importedCharges = const [];
      }

      // Commencer la fusion des données dans une transaction
      await database.transaction(() async {
        // Les factures d'abord : les opérations les référencent.
        for (final fac in importedFactures) {
          final exists = await (database.select(
            database.factures,
          )..where((t) => t.idFacture.equals(fac.idFacture))).getSingleOrNull();
          if (exists == null) {
            await database.into(database.factures).insert(fac);
            added++;
          } else {
            skipped++;
          }
        }

        // Fusionner les opérations
        for (final op in importedOperations) {
          final exists =
              await (database.select(database.operations)
                    ..where((t) => t.idOperation.equals(op.idOperation)))
                  .getSingleOrNull();
          if (exists == null) {
            await database.into(database.operations).insert(op);
            added++;
          } else {
            skipped++;
          }
        }

        // Fusionner les dépenses
        for (final dep in importedDepenses) {
          final exists = await (database.select(
            database.depenses,
          )..where((t) => t.idDepense.equals(dep.idDepense))).getSingleOrNull();
          if (exists == null) {
            await database.into(database.depenses).insert(dep);
            added++;
          } else {
            skipped++;
          }
        }

        // Fusionner les prélèvements
        for (final prel in importedPrelevements) {
          final exists =
              await (database.select(database.prelevements)
                    ..where((t) => t.idPrelevement.equals(prel.idPrelevement)))
                  .getSingleOrNull();
          if (exists == null) {
            await database.into(database.prelevements).insert(prel);
            added++;
          } else {
            skipped++;
          }
        }

        // Fusionner les relevés
        for (final rel in importedReleves) {
          final exists = await (database.select(
            database.releves,
          )..where((t) => t.idReleve.equals(rel.idReleve))).getSingleOrNull();
          if (exists == null) {
            await database.into(database.releves).insert(rel);
            added++;
          } else {
            skipped++;
          }
        }

        // Fusionner les charges. L'export chiffre le fichier SQLite entier :
        // sans cette boucle, une charge saisie sur un poste partirait dans
        // le .enc sans jamais revenir sur l'autre.
        for (final ch in importedCharges) {
          final exists = await (database.select(
            database.charges,
          )..where((t) => t.idCharge.equals(ch.idCharge))).getSingleOrNull();
          if (exists == null) {
            await database.into(database.charges).insert(ch);
            added++;
          } else {
            skipped++;
          }
        }
      });
    } finally {
      // Fermer et supprimer la base de données temporaire
      await importedDb.close();
      if (await tempDbFile.exists()) await tempDbFile.delete();
    }

    return ImportResult(added: added, skipped: skipped);
  }
}

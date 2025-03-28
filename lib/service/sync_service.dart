import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:drift/drift.dart';

class SyncService extends GetxService {
  final database = AppDatabase.instance;

  // Add constant key (in production, use secure storage instead)
  static final _encryptionKey =
      encrypt.Key.fromUtf8('12345678901234567890123456789012');

  Future<SyncService> init() async {
    return this;
  }

  Future<bool> backupDatabaseToDesktop() async {
    try {
      final dbFolder = await getApplicationCacheDirectory();
      final dbFile = File(p.join(dbFolder.path, 'caisse_database.sqlite'));

      // Lire le contenu du fichier
      final List<int> databaseContent = await dbFile.readAsBytes();

      // Crypter le contenu
      final iv = encrypt.IV.fromLength(16); // Vecteur d'initialisation
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

      final encrypted = encrypter.encryptBytes(databaseContent, iv: iv);

      // Créer le fichier de backup
      final desktopPath =
          "C:\\Users\\${Platform.environment['USERNAME']}\\Desktop";
      final timestamp = DateTime.now()
          .toString()
          .replaceAll(RegExp(r'[:-]'), '_')
          .split('.')
          .first;
      final backupFile = File('$desktopPath\\backup_caisse_$timestamp.enc');

      // Sauvegarder le contenu crypté
      await backupFile.writeAsBytes(
          [...iv.bytes, ...encrypted.bytes] // Combine IV et données cryptées
          ).then((_) {
        Get.snackbar(
          'Exportation effectuée',
          'Exportation effectuée avec succès!',
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
          backgroundColor: const Color.fromARGB(175, 0, 225, 0),
          colorText: Colors.white,
        );
      }).catchError((error) {
        Get.snackbar(
          "Erreur",
          "Une erreur est survenue lors de l'exportation!",
          snackPosition: SnackPosition.TOP,
          margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
          backgroundColor: const Color.fromARGB(175, 255, 0, 0),
          colorText: Colors.white,
        );
      });

      return true;
    } catch (e) {
      Get.snackbar(
        "Error backing up database",
        '$e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 255, 0, 0),
        colorText: Colors.white,
      );
      return false;
    }
  }

  // Fonction pour décrypter (à utiliser lors de la restauration)
  Future<List<int>> decryptBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      final List<int> encryptedData = await backupFile.readAsBytes();

      // Extraire IV et données cryptées
      final ivBytes = encryptedData.sublist(0, 16);
      final encryptedBytes = encryptedData.sublist(16);

      final iv = encrypt.IV(Uint8List.fromList(ivBytes));
      final encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey));

      final decrypted = encrypter.decryptBytes(
          encrypt.Encrypted(Uint8List.fromList(encryptedBytes)),
          iv: iv);

      return decrypted;
    } catch (e) {
      Get.snackbar(
        "Error decrypting backup",
        '$e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 255, 0, 0),
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<bool> importAndMergeDatabase(String backupPath) async {
    try {
      // Décrypter le fichier de backup
      final decryptedData = await decryptBackup(backupPath);

      // Créer un fichier temporaire pour la base de données importée
      final tempDir = await getTemporaryDirectory();
      final tempDbFile = File(p.join(tempDir.path, 'temp_import.sqlite'));
      await tempDbFile.writeAsBytes(decryptedData);

      // Ouvrir la base de données temporaire
      final importedDb = AppDatabase.fromFile(tempDbFile);

      // Récupérer toutes les données de la base importée
      final importedOperations =
          await importedDb.select(importedDb.operations).get();
      final importedDepenses =
          await importedDb.select(importedDb.depenses).get();
      final importedPrelevements =
          await importedDb.select(importedDb.prelevements).get();
      final importedReleves = await importedDb.select(importedDb.releves).get();
      final importedFactures =
          await importedDb.select(importedDb.factures).get();

      // Commencer la fusion des données dans une transaction
      await database.transaction(() async {
        // Fusionner les opérations
        for (final op in importedOperations) {
          final exists = await (database.select(database.operations)
                ..where((t) => t.idOperation.equals(op.idOperation)))
              .getSingleOrNull();
          if (exists == null) {
            await database.into(database.operations).insert(op);
          }
        }

        // Fusionner les dépenses
        for (final dep in importedDepenses) {
          final exists = await (database.select(database.depenses)
                ..where((t) => t.idDepense.equals(dep.idDepense)))
              .getSingleOrNull();
          if (exists == null) {
            await database.into(database.depenses).insert(dep);
          }
        }

        // Fusionner les prélèvements
        for (final prel in importedPrelevements) {
          final exists = await (database.select(database.prelevements)
                ..where((t) => t.idPrelevement.equals(prel.idPrelevement)))
              .getSingleOrNull();
          if (exists == null) {
            await database.into(database.prelevements).insert(prel);
          }
        }

        // Fusionner les relevés
        for (final rel in importedReleves) {
          final exists = await (database.select(database.releves)
                ..where((t) => t.idReleve.equals(rel.idReleve)))
              .getSingleOrNull();
          if (exists == null) {
            await database.into(database.releves).insert(rel);
          }
        }

        // Fusionner les factures
        for (final fac in importedFactures) {
          final exists = await (database.select(database.factures)
                ..where((t) => t.idFacture.equals(fac.idFacture)))
              .getSingleOrNull();
          if (exists == null) {
            await database.into(database.factures).insert(fac);
          }
        }
      });

      // Fermer et supprimer la base de données temporaire
      await importedDb.close();
      await tempDbFile.delete();

      Get.snackbar(
        'Importation réussie',
        'Les données ont été fusionnées avec succès!',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 0, 225, 0),
        colorText: Colors.white,
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur lors de l\'importation des données',
        '$e',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 255, 0, 0),
        colorText: Colors.white,
      );
      return false;
    }
  }
}

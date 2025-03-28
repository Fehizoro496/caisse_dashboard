import 'package:caisse_dashboard/model/depense_model.dart';
import 'package:caisse_dashboard/model/operation_model.dart';
import 'package:caisse_dashboard/model/prelevement_model.dart';
import 'package:caisse_dashboard/model/releve_model.dart';
import 'package:caisse_dashboard/utils/generate_invoice_id.dart';
import 'package:drift/drift.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/persistance/database.dart';
// ignore: implementation_imports
import 'package:drift/src/runtime/data_class.dart' as drift_data_class;

class DBService extends GetxService {
  final database = AppDatabase.instance;

  Future<DBService> init() async {
    return this;
  }

  Future<int> saveDepense(DepenseModel depense) async {
    return await database.into(database.depenses).insert(
        DepensesCompanion.insert(
            idDepense: generateUid(),
            libelle: depense.libelle,
            montant: depense.montant,
            dateDepense: depense.dateDepense ?? DateTime.timestamp()));
  }

  Future<String> saveOperation(OperationModel operation) async {
    final String id = generateUid();
    await database.into(database.operations).insert(OperationsCompanion.insert(
        idOperation: id,
        nomOperation: operation.nomOperation,
        prixOperation: operation.prixOperation,
        quantiteOperation: operation.quantiteOperation,
        dateOperation: operation.dateOperation ?? DateTime.timestamp()));
    return id;
  }

  Future<String> saveFacture({required String client, DateTime? date}) async {
    final String id =
        generateInvoiceId(client: client, date: date ?? DateTime.now());
    await database.into(database.factures).insert(FacturesCompanion.insert(
        idFacture: id,
        client: client,
        dateFacture: date ?? DateTime.timestamp()));
    return id;
  }

  Future<Operation?> getOperationById(String id) {
    return (database.select(database.operations)
          ..where((tbl) => tbl.idOperation.equals(id)))
        .getSingleOrNull();
  }

  Future<void> assignFactureInOperation(
      String operationID, String factureID) async {
    final operation = await getOperationById(operationID);
    if (operation != null) {
      await (database.update(database.operations)
            ..where((tbl) => tbl.idOperation.equals(operationID)))
          .write(
        OperationsCompanion(
          facture: drift_data_class.Value(factureID),
        ),
      );
    }
  }

  Future<List<Operation>> getAllOperations() async {
    List<Operation> out = await database.select(database.operations).get();
    return out;
  }

  Future<List<Depense>> getAllDepenses() async {
    List<Depense> out = await database.select(database.depenses).get();
    return out;
  }

  Future<List<Prelevement>> getAllPrelevements() async {
    List<Prelevement> out = await database.select(database.prelevements).get();
    return out;
  }

  Future<DateTime> getLastInsertDate() async {
    final lastOperation = await (database.select(database.operations)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateOperation)])
          ..limit(1))
        .getSingleOrNull();

    final lastDepense = await (database.select(database.depenses)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateDepense)])
          ..limit(1))
        .getSingleOrNull();

    final lastPrelevements = await (database.select(database.prelevements)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.datePrelevement)])
          ..limit(1))
        .getSingleOrNull();

    final dates = [
      lastOperation!.dateOperation,
      lastDepense!.dateDepense,
      lastPrelevements!.datePrelevement,
    ].whereType<DateTime>().toList();

    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  Future<List<Prelevement>> getPrelevementByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (database.select(database.prelevements)
          ..where((dep) =>
              dep.datePrelevement.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  Future<int> savePrelevement(PrelevementModel prelevement) async {
    return await database.into(database.prelevements).insert(
        PrelevementsCompanion.insert(
            idPrelevement: generateUid(),
            montant: prelevement.montant,
            datePrelevement:
                prelevement.datePrelevement ?? DateTime.timestamp()));
  }

  Future<List<Releve>> getAllReleves() async {
    List<Releve> out = await database.select(database.releves).get();
    return out;
  }

  Future<int> saveReleve(ReleveModel releve) async {
    return await database.into(database.releves).insert(RelevesCompanion.insert(
        idReleve: generateUid(),
        compteur: releve.compteur,
        sousCompteur: releve.sousCompteur,
        dateReleve: releve.dateReleve ?? DateTime.timestamp()));
  }

  Future<List<Operation>> getOperationsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (database.select(database.operations)
          ..where(
              (op) => op.dateOperation.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  Future<List<Depense>> getDepensesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (database.select(database.depenses)
          ..where(
              (dep) => dep.dateDepense.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }
}
// dart run drift_dev schema dump lib/persistance/database.dart db_schemas
// dart run build_runner build --delete-conflicting-outputs
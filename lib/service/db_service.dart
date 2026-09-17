import 'package:caisse_dashboard/model/depense_model.dart';
import 'package:caisse_dashboard/model/facture_jiro_model.dart';
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
    return await database
        .into(database.depenses)
        .insert(
          DepensesCompanion.insert(
            idDepense: generateUid(),
            libelle: depense.libelle,
            montant: depense.montant,
            dateDepense: depense.dateDepense ?? DateTime.timestamp(),
          ),
        );
  }

  Future<String> saveOperation(OperationModel operation) async {
    final String id = generateUid();
    await database
        .into(database.operations)
        .insert(
          OperationsCompanion.insert(
            idOperation: id,
            nomOperation: operation.nomOperation,
            prixOperation: operation.prixOperation,
            quantiteOperation: operation.quantiteOperation,
            dateOperation: operation.dateOperation ?? DateTime.timestamp(),
          ),
        );
    return id;
  }

  Future<String> saveFacture({required String client, DateTime? date}) async {
    final String id = generateInvoiceId(
      client: client,
      date: date ?? DateTime.now(),
    );
    await database
        .into(database.factures)
        .insert(
          FacturesCompanion.insert(
            idFacture: id,
            client: client,
            dateFacture: date ?? DateTime.timestamp(),
          ),
        );
    return id;
  }

  Future<Operation?> getOperationById(String id) {
    return (database.select(
      database.operations,
    )..where((tbl) => tbl.idOperation.equals(id))).getSingleOrNull();
  }

  Future<void> assignFactureInOperation(
    String operationID,
    String factureID,
  ) async {
    final operation = await getOperationById(operationID);
    if (operation != null) {
      await (database.update(
        database.operations,
      )..where((tbl) => tbl.idOperation.equals(operationID))).write(
        OperationsCompanion(facture: drift_data_class.Value(factureID)),
      );
    }
  }

  /// Corrige une opération existante. L'identifiant ne change pas : c'est lui
  /// qui porte la déduplication à l'import d'une sauvegarde.
  /// Retourne le nombre de lignes touchées — 0 si l'identifiant n'existe plus.
  Future<int> updateOperation({
    required String id,
    required String nomOperation,
    required int prixOperation,
    required int quantiteOperation,
    required DateTime dateOperation,
  }) async {
    return await (database.update(
      database.operations,
    )..where((tbl) => tbl.idOperation.equals(id))).write(
      OperationsCompanion(
        nomOperation: drift_data_class.Value(nomOperation),
        prixOperation: drift_data_class.Value(prixOperation),
        quantiteOperation: drift_data_class.Value(quantiteOperation),
        dateOperation: drift_data_class.Value(dateOperation),
      ),
    );
  }

  /// Corrige une dépense existante. Voir [updateOperation] pour l'identifiant.
  Future<int> updateDepense({
    required String id,
    required String libelle,
    required int montant,
    required DateTime dateDepense,
  }) async {
    return await (database.update(
      database.depenses,
    )..where((tbl) => tbl.idDepense.equals(id))).write(
      DepensesCompanion(
        libelle: drift_data_class.Value(libelle),
        montant: drift_data_class.Value(montant),
        dateDepense: drift_data_class.Value(dateDepense),
      ),
    );
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
    final lastOperation =
        await (database.select(database.operations)
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateOperation)])
              ..limit(1))
            .getSingleOrNull();

    final lastDepense =
        await (database.select(database.depenses)
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.dateDepense)])
              ..limit(1))
            .getSingleOrNull();

    final lastPrelevements =
        await (database.select(database.prelevements)
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

    return await (database.select(database.prelevements)..where(
          (dep) => dep.datePrelevement.isBetweenValues(startOfDay, endOfDay),
        ))
        .get();
  }

  Future<int> savePrelevement(PrelevementModel prelevement) async {
    return await database
        .into(database.prelevements)
        .insert(
          PrelevementsCompanion.insert(
            idPrelevement: generateUid(),
            montant: prelevement.montant,
            datePrelevement:
                prelevement.datePrelevement ?? DateTime.timestamp(),
          ),
        );
  }

  /// Corrige un prélèvement existant. Voir [updateOperation] pour l'identifiant.
  Future<int> updatePrelevement({
    required String id,
    required int montant,
    required DateTime datePrelevement,
  }) async {
    return await (database.update(
      database.prelevements,
    )..where((tbl) => tbl.idPrelevement.equals(id))).write(
      PrelevementsCompanion(
        montant: drift_data_class.Value(montant),
        datePrelevement: drift_data_class.Value(datePrelevement),
      ),
    );
  }

  /// Corrige un relevé existant. Voir [updateOperation] pour l'identifiant.
  Future<int> updateReleve({
    required String id,
    required double compteur,
    required double sousCompteur,
    required DateTime dateReleve,
  }) async {
    return await (database.update(
      database.releves,
    )..where((tbl) => tbl.idReleve.equals(id))).write(
      RelevesCompanion(
        compteur: drift_data_class.Value(compteur),
        sousCompteur: drift_data_class.Value(sousCompteur),
        dateReleve: drift_data_class.Value(dateReleve),
      ),
    );
  }

  Future<List<Releve>> getAllReleves() async {
    List<Releve> out = await database.select(database.releves).get();
    return out;
  }

  /// Trouve le relevé correspondant à la valeur du compteur principal.
  /// Si la valeur exacte n'existe pas, interpole le sous-compteur à partir
  /// des deux relevés les plus proches (un inférieur et un supérieur).
  /// Retourne un Map avec:
  /// - 'releve': le relevé exact si trouvé, ou null
  /// - 'sousCompteur': la valeur du sous-compteur (exacte ou interpolée)
  /// - 'date': la date du relevé (exacte ou interpolée)
  /// - 'isInterpolated': true si la valeur a été calculée par interpolation
  Future<Map<String, dynamic>?> getSousCompteurForCompteurValue(
    double compteurValue,
  ) async {
    final releves = await getAllReleves();
    if (releves.isEmpty) return null;

    // Trier par valeur du compteur
    releves.sort((a, b) => a.compteur.compareTo(b.compteur));

    // Chercher une correspondance exacte (avec tolérance de 0.01)
    for (final releve in releves) {
      if ((releve.compteur - compteurValue).abs() < 0.01) {
        return {
          'releve': releve,
          'sousCompteur': releve.sousCompteur,
          'date': releve.dateReleve,
          'isInterpolated': false,
        };
      }
    }

    // Pas de correspondance exacte, chercher les deux relevés encadrants
    Releve? releveBas; // Le relevé avec compteur juste en dessous
    Releve? releveHaut; // Le relevé avec compteur juste au dessus

    for (final releve in releves) {
      if (releve.compteur < compteurValue) {
        if (releveBas == null || releve.compteur > releveBas.compteur) {
          releveBas = releve;
        }
      } else if (releve.compteur > compteurValue) {
        if (releveHaut == null || releve.compteur < releveHaut.compteur) {
          releveHaut = releve;
        }
      }
    }

    // Si on n'a qu'un seul côté, utiliser le relevé le plus proche
    if (releveBas == null && releveHaut == null) {
      return null;
    }

    if (releveBas == null) {
      // Extrapolation vers le bas (pas idéal mais mieux que rien)
      return {
        'releve': null,
        'sousCompteur': releveHaut!.sousCompteur,
        'date': releveHaut.dateReleve,
        'isInterpolated': true,
        'note': 'Extrapolé (valeur inférieure aux relevés)',
      };
    }

    if (releveHaut == null) {
      // Extrapolation vers le haut (pas idéal mais mieux que rien)
      return {
        'releve': null,
        'sousCompteur': releveBas.sousCompteur,
        'date': releveBas.dateReleve,
        'isInterpolated': true,
        'note': 'Extrapolé (valeur supérieure aux relevés)',
      };
    }

    // Interpolation linéaire entre les deux relevés
    // Formule: sousCompteur = sousCompteurBas + (compteurValue - compteurBas) *
    //          (sousCompteurHaut - sousCompteurBas) / (compteurHaut - compteurBas)
    final compteurBas = releveBas.compteur;
    final compteurHaut = releveHaut.compteur;
    final sousCompteurBas = releveBas.sousCompteur;
    final sousCompteurHaut = releveHaut.sousCompteur;

    final ratio = (compteurValue - compteurBas) / (compteurHaut - compteurBas);
    final sousCompteurInterpole =
        sousCompteurBas + ratio * (sousCompteurHaut - sousCompteurBas);

    // Interpoler aussi la date
    final dateBas = releveBas.dateReleve;
    final dateHaut = releveHaut.dateReleve;
    final diffMillis = dateHaut.difference(dateBas).inMilliseconds;
    final dateInterpole = dateBas.add(
      Duration(milliseconds: (diffMillis * ratio).round()),
    );

    return {
      'releve': null,
      'sousCompteur': sousCompteurInterpole,
      'date': dateInterpole,
      'isInterpolated': true,
      'releveBas': releveBas,
      'releveHaut': releveHaut,
    };
  }

  Future<int> saveReleve(ReleveModel releve) async {
    return await database
        .into(database.releves)
        .insert(
          RelevesCompanion.insert(
            idReleve: generateUid(),
            compteur: releve.compteur,
            sousCompteur: releve.sousCompteur,
            dateReleve: releve.dateReleve ?? DateTime.timestamp(),
          ),
        );
  }

  Future<List<Operation>> getOperationsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (database.select(database.operations)..where(
          (op) => op.dateOperation.isBetweenValues(startOfDay, endOfDay),
        ))
        .get();
  }

  Future<List<Depense>> getDepensesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return await (database.select(database.depenses)..where(
          (dep) => dep.dateDepense.isBetweenValues(startOfDay, endOfDay),
        ))
        .get();
  }

  // ─────────────────────────────── Charges ───────────────────────────────
  // Deuxième et dernière source d'écriture de l'app avec la facture JIRO :
  // les charges ne viennent pas de l'import, elles se saisissent ici.

  Future<List<Charge>> getAllCharges() async {
    return await database.select(database.charges).get();
  }

  Future<String> saveCharge({
    required String libelle,
    required int prixUnitaire,
    required DateTime mois,
    int quantite = 1,
    DateTime? dateEnregistrement,
    String? categorie,
  }) async {
    final id = generateUid();
    await database
        .into(database.charges)
        .insert(
          ChargesCompanion.insert(
            idCharge: id,
            libelle: libelle,
            prixUnitaire: prixUnitaire,
            quantite: drift_data_class.Value(quantite),
            mois: normalizeMois(mois),
            dateEnregistrement: normalizeJour(
              dateEnregistrement ?? DateTime.now(),
            ),
            categorie: drift_data_class.Value(categorie),
          ),
        );
    return id;
  }

  /// Corrige une charge existante. Voir [updateOperation] pour l'identifiant.
  Future<int> updateCharge({
    required String id,
    required String libelle,
    required int prixUnitaire,
    required DateTime mois,
    required DateTime dateEnregistrement,
    int quantite = 1,
    String? categorie,
  }) async {
    return await (database.update(
      database.charges,
    )..where((tbl) => tbl.idCharge.equals(id))).write(
      ChargesCompanion(
        libelle: drift_data_class.Value(libelle),
        prixUnitaire: drift_data_class.Value(prixUnitaire),
        quantite: drift_data_class.Value(quantite),
        mois: drift_data_class.Value(normalizeMois(mois)),
        dateEnregistrement: drift_data_class.Value(
          normalizeJour(dateEnregistrement),
        ),
        categorie: drift_data_class.Value(categorie),
      ),
    );
  }

  Future<int> deleteCharge(String id) async {
    return await (database.delete(
      database.charges,
    )..where((t) => t.idCharge.equals(id))).go();
  }

  // CRUD FacturesJiro
  Future<List<FacturesJiroData>> getAllFacturesJiro() async {
    return await (database.select(
      database.facturesJiro,
    )..orderBy([(t) => OrderingTerm.desc(t.dateFacture)])).get();
  }

  Future<FacturesJiroData?> getFactureJiroById(String id) {
    return (database.select(
      database.facturesJiro,
    )..where((t) => t.idFactureJiro.equals(id))).getSingleOrNull();
  }

  Future<int> saveFactureJiro(FactureJiroModel facture) async {
    return await database
        .into(database.facturesJiro)
        .insert(
          FacturesJiroCompanion.insert(
            idFactureJiro: generateUid(),
            mois: facture.mois,
            dateAncienIndex: facture.dateAncienIndex,
            dateNouvelIndex: facture.dateNouvelIndex,
            ancienIndexCompteur: facture.ancienIndexCompteur,
            nouvelIndexCompteur: facture.nouvelIndexCompteur,
            ancienIndexSousCompteur: facture.ancienIndexSousCompteur,
            nouvelIndexSousCompteur: facture.nouvelIndexSousCompteur,
            prixUnitaireKwh: facture.prixUnitaireKwh,
            redevanceJirama: facture.redevanceJirama,
            primeFixeJirama: facture.primeFixeJirama,
            taxesRedevances: facture.taxesRedevances,
            tva: facture.tva,
            dateFacture: facture.dateFacture ?? DateTime.now(),
          ),
        );
  }

  Future<int> deleteFactureJiro(String id) async {
    return await (database.delete(
      database.facturesJiro,
    )..where((t) => t.idFactureJiro.equals(id))).go();
  }
}

// dart run drift_dev schema dump lib/persistance/database.dart db_schemas
// dart run build_runner build --delete-conflicting-outputs

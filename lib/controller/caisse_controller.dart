import 'dart:convert';

import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/model/facture_jiro_model.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/jiro_invoice_service.dart';
import 'package:caisse_dashboard/service/sync_service.dart';
import 'package:caisse_dashboard/view/screens/backup_screen.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart';
import 'package:caisse_dashboard/view/screens/jiro_screen.dart';
import 'package:caisse_dashboard/view/screens/ledger_screen.dart';
import 'package:caisse_dashboard/view/widgets/app_shell.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le seul point de contact entre les écrans et SQLite.
///
/// La base tient en mémoire : quelques milliers de lignes locales, chargées une
/// fois puis rechargées après chaque import. Les écrans ne font aucune requête
/// et ne calculent aucun total — tout est préparé ici.
class CaisseController extends GetxController {
  CaisseController({DBService? db, SyncService? sync, JiroInvoiceService? jiro})
    : _db = db ?? Get.find<DBService>(),
      _sync = sync ?? Get.find<SyncService>(),
      _jiro = jiro ?? Get.find<JiroInvoiceService>();

  final DBService _db;
  final SyncService _sync;
  final JiroInvoiceService _jiro;

  static const _importsKey = 'importLogs';

  // ── État de chargement
  bool loading = true;
  Object? error;

  /// Import ou export en cours.
  bool busy = false;

  // ── Données brutes
  List<Operation> _operations = const [];
  List<Depense> _depenses = const [];
  List<Prelevement> _prelevements = const [];
  List<FacturesJiroData> _facturesJiro = const [];
  List<ReleveElectricite> releves = const [];
  List<ImportLog> imports = const [];

  // ── État de navigation
  AppSection section = AppSection.dashboard;
  Period period = Period.day;

  /// Date courante — initialisée sur le dernier enregistrement en base,
  /// jamais sur aujourd'hui.
  DateTime date = DateTime.now();
  DateTime lastRecordDate = DateTime.now();

  /// Mois sélectionné dans l'écran Prélèvements.
  DateTime mois = DateTime(DateTime.now().year, DateTime.now().month);

  String qOperations = '';
  String qDepenses = '';
  LedgerSort sortOperations = LedgerSort.date;
  LedgerSort sortDepenses = LedgerSort.date;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  // ─────────────────────────────── Chargement ───────────────────────────────

  Future<void> load({bool keepDate = false}) async {
    loading = true;
    error = null;
    update();
    try {
      final results = await Future.wait([
        _db.getAllOperations(),
        _db.getAllDepenses(),
        _db.getAllPrelevements(),
        _db.getAllReleves(),
        _db.getAllFacturesJiro(),
      ]);
      _operations = results[0] as List<Operation>;
      _depenses = results[1] as List<Depense>;
      _prelevements = results[2] as List<Prelevement>;
      releves = [
        for (final r in results[3] as List<Releve>)
          ReleveElectricite(
            id: r.idReleve,
            date: r.dateReleve,
            compteur: r.compteur,
            sousCompteur: r.sousCompteur,
          ),
      ];
      _facturesJiro = results[4] as List<FacturesJiroData>;
      imports = await _loadImportLogs();

      lastRecordDate = _computeLastRecordDate();
      if (!keepDate) {
        date = lastRecordDate;
        mois = DateTime(date.year, date.month);
      }
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      update();
    }
  }

  DateTime _computeLastRecordDate() {
    final dates = <DateTime>[
      ..._operations.map((o) => o.dateOperation),
      ..._depenses.map((d) => d.dateDepense),
      ..._prelevements.map((p) => p.datePrelevement),
    ];
    if (dates.isEmpty) return DateTime.now();
    return dates.reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // ─────────────────────────────── Navigation ───────────────────────────────

  void openSection(AppSection s) {
    section = s;
    if (s == AppSection.drawings) mois = DateTime(date.year, date.month);
    update();
  }

  void setPeriod(Period p) {
    period = p;
    update();
  }

  void setDate(DateTime d) {
    date = d;
    update();
  }

  void setMois(DateTime m) {
    mois = m;
    update();
  }

  void setQuery(AppSection s, String q) {
    if (s == AppSection.operations) {
      qOperations = q;
    } else {
      qDepenses = q;
    }
    update();
  }

  void setSort(AppSection s, LedgerSort sort) {
    if (s == AppSection.operations) {
      sortOperations = sort;
    } else {
      sortDepenses = sort;
    }
    update();
  }

  /// Sélection directe d'une date, bornée au dernier enregistrement.
  Future<void> pickDate(BuildContext context) async {
    final first = _operations.isEmpty && _depenses.isEmpty
        ? DateTime(lastRecordDate.year - 1)
        : DateTime(2020);
    final picked = await showDatePicker(
      context: context,
      initialDate: date.isAfter(lastRecordDate) ? lastRecordDate : date,
      firstDate: first,
      lastDate: lastRecordDate,
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) setDate(picked);
  }

  // ──────────────────────────────── Compteurs ────────────────────────────────

  int get recordCount =>
      _operations.length +
      _depenses.length +
      _prelevements.length +
      releves.length;

  Map<AppSection, int> get counts => {
    AppSection.operations: _operations.length,
    AppSection.expenses: _depenses.length,
    AppSection.drawings: _prelevements.length,
    AppSection.meterReadings: releves.length,
    AppSection.jiroSharing: _facturesJiro.length,
  };

  /// Mois où des prélèvements existent, du plus ancien au plus récent.
  List<DateTime> get availableMonths {
    final set = <DateTime>{
      for (final p in _prelevements)
        DateTime(p.datePrelevement.year, p.datePrelevement.month),
    };
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  /// Libellé du mois suivant le dernier mois disponible — affiché désactivé.
  String get nextMonthLabel {
    final months = availableMonths;
    final last = months.isEmpty
        ? DateTime(lastRecordDate.year, lastRecordDate.month)
        : months.last;
    final next = DateTime(last.year, last.month + 1);
    final multiYear = months.map((d) => d.year).toSet().length > 1;
    final label = Fmt.cap(Fmt.monthShort(next));
    return multiYear ? '$label ${next.year % 100}' : label;
  }

  // ────────────────────────────────── Bornes ──────────────────────────────────

  (DateTime, DateTime) _bounds(DateTime d, Period p) => switch (p) {
    // Bornes semi-ouvertes [début, fin[ — voir [_within].
    Period.day => (
      DateTime(d.year, d.month, d.day),
      DateTime(d.year, d.month, d.day + 1),
    ),
    Period.week => () {
      final start = DateTime(
        d.year,
        d.month,
        d.day,
      ).subtract(Duration(days: (d.weekday + 6) % 7));
      return (start, start.add(const Duration(days: 7)));
    }(),
    Period.month => (DateTime(d.year, d.month), DateTime(d.year, d.month + 1)),
  };

  (DateTime, DateTime) _previousBounds(DateTime d, Period p) => switch (p) {
    Period.day => _bounds(d.subtract(const Duration(days: 1)), p),
    Period.week => _bounds(d.subtract(const Duration(days: 7)), p),
    Period.month => _bounds(DateTime(d.year, d.month - 1, 1), p),
  };

  static bool _within(DateTime d, DateTime start, DateTime end) =>
      !d.isBefore(start) && d.isBefore(end);

  PeriodTotals _totals(DateTime start, DateTime end) {
    var entrant = 0, sortant = 0, prelevement = 0;
    var nbOps = 0, nbDep = 0, nbPrel = 0;
    for (final o in _operations) {
      if (_within(o.dateOperation, start, end)) {
        entrant += o.prixOperation * o.quantiteOperation;
        nbOps++;
      }
    }
    for (final d in _depenses) {
      if (_within(d.dateDepense, start, end)) {
        sortant += d.montant;
        nbDep++;
      }
    }
    for (final p in _prelevements) {
      if (_within(p.datePrelevement, start, end)) {
        prelevement += p.montant;
        nbPrel++;
      }
    }
    return PeriodTotals(
      entrant: entrant,
      sortant: sortant,
      prelevement: prelevement,
      nbOperations: nbOps,
      nbDepenses: nbDep,
      nbPrelevements: nbPrel,
    );
  }

  // ───────────────────────────────── Dashboard ─────────────────────────────────

  DashboardData get dashboard {
    final (start, end) = _bounds(date, period);
    final (pStart, pEnd) = _previousBounds(date, period);

    final ops =
        _operations.where((o) => _within(o.dateOperation, start, end)).toList()
          ..sort((a, b) => a.dateOperation.compareTo(b.dateOperation));

    final deps =
        _depenses.where((d) => _within(d.dateDepense, start, end)).toList()
          ..sort((a, b) => a.dateDepense.compareTo(b.dateDepense));

    return DashboardData(
      totals: _totals(start, end),
      previousTotals: _totals(pStart, pEnd),
      operations: period == Period.day
          ? [
              for (final o in ops)
                OperationRow(
                  nom: o.nomOperation,
                  prixUnitaire: o.prixOperation,
                  quantite: o.quantiteOperation,
                  total: o.prixOperation * o.quantiteOperation,
                  meta: Fmt.hour(o.dateOperation),
                ),
            ]
          : _aggregate(ops),
      depenses: [
        for (final d in deps)
          DepenseRow(
            libelle: d.libelle,
            categorie: CategoryRules.of(d.libelle),
            montant: d.montant,
          ),
      ],
      trend: _trend(),
      repartition: _repartition(deps),
    );
  }

  /// Vue Semaine / Mois : une ligne par prestation, quantités cumulées.
  List<OperationRow> _aggregate(List<Operation> ops) {
    final byName = <String, ({int pu, int qte, int total, int lignes})>{};
    for (final o in ops) {
      final cur = byName[o.nomOperation];
      byName[o.nomOperation] = (
        pu: o.prixOperation,
        qte: (cur?.qte ?? 0) + o.quantiteOperation,
        total: (cur?.total ?? 0) + o.prixOperation * o.quantiteOperation,
        lignes: (cur?.lignes ?? 0) + 1,
      );
    }
    final rows = [
      for (final e in byName.entries)
        OperationRow(
          nom: e.key,
          prixUnitaire: e.value.pu,
          quantite: e.value.qte,
          total: e.value.total,
          meta: '${e.value.lignes}',
        ),
    ]..sort((a, b) => b.total.compareTo(a.total));
    return rows;
  }

  /// 7 jours / 8 semaines / 6 mois se terminant sur la période courante.
  List<BarGroup> _trend() {
    final count = switch (period) {
      Period.day => 7,
      Period.week => 8,
      Period.month => 6,
    };
    final groups = <BarGroup>[];
    for (var i = count - 1; i >= 0; i--) {
      final anchor = switch (period) {
        Period.day => date.subtract(Duration(days: i)),
        Period.week => date.subtract(Duration(days: 7 * i)),
        Period.month => DateTime(date.year, date.month - i, 1),
      };
      final (s, e) = _bounds(anchor, period);
      final t = _totals(s, e);
      groups.add(
        BarGroup(
          label: switch (period) {
            Period.day => Fmt.shortDate(anchor),
            Period.week => Fmt.shortDate(s),
            Period.month => _shortMonth(anchor),
          },
          primary: t.entrant,
          secondary: t.prelevement,
          highlighted: i == 0,
        ),
      );
    }
    return groups;
  }

  /// « Janv », « Mai » — assez court pour tenir sous une barre.
  static String _shortMonth(DateTime d) {
    final m = Fmt.cap(Fmt.monthShort(d));
    return m.length <= 4 ? m : m.substring(0, 4);
  }

  List<(String, int)> _repartition(List<Depense> deps) {
    final byCat = <String, int>{};
    for (final d in deps) {
      final c = CategoryRules.of(d.libelle);
      byCat[c] = (byCat[c] ?? 0) + d.montant;
    }
    final entries = byCat.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return entries;
  }

  // ─────────────────────────────── Écrans-listes ───────────────────────────────

  List<LedgerItem> operationItems() {
    final q = qOperations.trim().toLowerCase();
    final list = _operations
        .where((o) => q.isEmpty || o.nomOperation.toLowerCase().contains(q))
        .toList();
    list.sort(
      (a, b) => switch (sortOperations) {
        LedgerSort.date => b.dateOperation.compareTo(a.dateOperation),
        LedgerSort.name => a.nomOperation.compareTo(b.nomOperation),
        LedgerSort.amount => (b.prixOperation * b.quantiteOperation).compareTo(
          a.prixOperation * a.quantiteOperation,
        ),
      },
    );
    return [
      for (final o in list)
        LedgerItem(
          date: o.dateOperation,
          amount: o.prixOperation * o.quantiteOperation,
          cells: [
            LedgerCell(o.nomOperation),
            LedgerCell(Fmt.num(o.prixOperation), mono: true),
            LedgerCell('×${o.quantiteOperation}', mono: true),
            LedgerCell(
              Fmt.num(o.prixOperation * o.quantiteOperation),
              mono: true,
            ),
            LedgerCell(Fmt.hour(o.dateOperation), mono: true),
          ],
        ),
    ];
  }

  List<LedgerItem> depenseItems(BuildContext context) {
    final q = qDepenses.trim().toLowerCase();
    final list = _depenses
        .where((d) => q.isEmpty || d.libelle.toLowerCase().contains(q))
        .toList();
    list.sort(
      (a, b) => switch (sortDepenses) {
        LedgerSort.date => b.dateDepense.compareTo(a.dateDepense),
        LedgerSort.name => a.libelle.compareTo(b.libelle),
        LedgerSort.amount => b.montant.compareTo(a.montant),
      },
    );
    return [
      for (final d in list)
        depenseItem(
          context,
          date: d.dateDepense,
          libelle: d.libelle,
          categorie: CategoryRules.of(d.libelle),
          montant: d.montant,
        ),
    ];
  }

  List<LedgerItem> prelevementItems() {
    final list =
        _prelevements
            .where(
              (p) =>
                  p.datePrelevement.year == mois.year &&
                  p.datePrelevement.month == mois.month,
            )
            .toList()
          ..sort((a, b) => b.datePrelevement.compareTo(a.datePrelevement));
    return [
      for (final p in list)
        LedgerItem(
          date: p.datePrelevement,
          amount: p.montant,
          cells: [
            LedgerCell(Fmt.cap(Fmt.longDate(p.datePrelevement))),
            LedgerCell(Fmt.num(p.montant), mono: true),
            LedgerCell(Fmt.hour(p.datePrelevement), mono: true),
          ],
        ),
    ];
  }

  // ────────────────────────────────── JIRO ──────────────────────────────────

  List<JiroSharing> get jiroHistory => [
    for (final f in _facturesJiro)
      () {
        final m = _toModel(f);
        return JiroSharing(
          id: f.idFactureJiro,
          periode: f.mois,
          indexPrecedent: f.ancienIndexCompteur,
          indexActuel: f.nouvelIndexCompteur,
          conso1: m.consommation1,
          conso2: m.consommation2,
          part1: m.total1,
          part2: m.total2,
          total: m.totalGeneral,
          genereLe: f.dateFacture,
        );
      }(),
  ];

  /// Prix du kWh et frais fixes de la dernière facture : ils changent rarement.
  JiroDefaults? get jiroDefaults {
    if (_facturesJiro.isEmpty) return null;
    final f = _facturesJiro.first;
    return JiroDefaults(
      prixKwh: f.prixUnitaireKwh,
      redevance: f.redevanceJirama,
      primeFixe: f.primeFixeJirama,
      taxes: f.taxesRedevances,
      tva: f.tva,
    );
  }

  FactureJiroModel _toModel(FacturesJiroData d) => FactureJiroModel(
    idFactureJiro: d.idFactureJiro,
    mois: d.mois,
    dateAncienIndex: d.dateAncienIndex,
    dateNouvelIndex: d.dateNouvelIndex,
    ancienIndexCompteur: d.ancienIndexCompteur,
    nouvelIndexCompteur: d.nouvelIndexCompteur,
    ancienIndexSousCompteur: d.ancienIndexSousCompteur,
    nouvelIndexSousCompteur: d.nouvelIndexSousCompteur,
    prixUnitaireKwh: d.prixUnitaireKwh,
    redevanceJirama: d.redevanceJirama,
    primeFixeJirama: d.primeFixeJirama,
    taxesRedevances: d.taxesRedevances,
    tva: d.tva,
    dateFacture: d.dateFacture,
  );

  /// La seule écriture de l'application : enregistre la facture puis imprime
  /// le PDF de partage.
  Future<void> saveJiroSharing(JiroDraft draft) async {
    final facture = FactureJiroModel(
      mois: draft.mois,
      dateAncienIndex: draft.dateIndexPrecedent,
      dateNouvelIndex: draft.dateIndexActuel,
      ancienIndexCompteur: draft.bill.indexPrecedent,
      nouvelIndexCompteur: draft.bill.indexActuel,
      ancienIndexSousCompteur: draft.sousCompteurPrecedent,
      nouvelIndexSousCompteur: draft.sousCompteurActuel,
      prixUnitaireKwh: draft.bill.prixKwh,
      redevanceJirama: draft.bill.redevance,
      primeFixeJirama: draft.bill.primeFixe,
      taxesRedevances: draft.bill.taxes,
      tva: draft.bill.tva,
      dateFacture: DateTime.now(),
    );
    try {
      await _db.saveFactureJiro(facture);
      await _jiro.generateJiroPdf(facture);
      _facturesJiro = await _db.getAllFacturesJiro();
      update();
    } catch (e) {
      _toast('Partage non généré', '$e', ok: false);
    }
  }

  Future<void> regenerateJiroPdf(JiroSharing s) async {
    final data = _facturesJiro.firstWhereOrNull((f) => f.idFactureJiro == s.id);
    if (data == null) return;
    await _jiro.generateJiroPdfFromData(data);
  }

  Future<void> deleteJiroSharing(JiroSharing s) async {
    await _db.deleteFactureJiro(s.id);
    _facturesJiro = await _db.getAllFacturesJiro();
    update();
  }

  // ──────────────────────────────── Sauvegarde ────────────────────────────────

  Future<void> importBackup() async {
    if (busy) return;
    final picked = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choisir une sauvegarde .enc',
      type: FileType.any,
    );
    final path = picked?.files.single.path;
    if (path == null) return;

    busy = true;
    update();
    try {
      final result = await _sync.importAndMergeDatabase(path);
      await _appendImportLog(
        ImportLog(
          fileName: path.split(RegExp(r'[\\/]')).last,
          date: DateTime.now(),
          added: result.added,
          skipped: result.skipped,
        ),
      );
      await load();
      _toast(
        'Importation réussie',
        '${result.added} nouveaux enregistrements · ${result.skipped} déjà présents',
      );
    } catch (e) {
      // La base locale n'a pas été touchée : la transaction n'a pas eu lieu.
      _toast('Importation impossible', '$e', ok: false);
    } finally {
      busy = false;
      update();
    }
  }

  Future<void> exportBackup() async {
    if (busy) return;
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Où enregistrer la sauvegarde ?',
    );
    if (dir == null) return;

    busy = true;
    update();
    try {
      final path = await _sync.exportDatabase(targetDirectory: dir);
      _toast('Exportation effectuée', path);
    } catch (e) {
      _toast('Exportation impossible', '$e', ok: false);
    } finally {
      busy = false;
      update();
    }
  }

  Future<List<ImportLog>> _loadImportLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_importsKey) ?? const [];
      return [
        for (final s in raw)
          ImportLog.fromJson(jsonDecode(s) as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _appendImportLog(ImportLog log) async {
    // Les dix derniers suffisent : c'est un journal de contrôle, pas un audit.
    final next = [log, ...imports].take(10).toList();
    imports = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_importsKey, [
        for (final l in next) jsonEncode(l.toJson()),
      ]);
    } catch (_) {
      // Le journal est un confort : son échec ne doit pas casser l'import.
    }
  }

  void _toast(String title, String message, {bool ok = true}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 70),
      backgroundColor: ok
          ? const Color.fromARGB(175, 0, 225, 0)
          : const Color.fromARGB(175, 255, 0, 0),
      colorText: Colors.white,
      duration: const Duration(seconds: 4),
    );
  }
}

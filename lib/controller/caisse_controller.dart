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
import 'package:caisse_dashboard/view/widgets/app_toast.dart';
import 'package:caisse_dashboard/view/widgets/record_editor.dart';
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
  static const _chargesKey = 'chargesIncluses';

  // ── État de chargement
  bool loading = true;
  Object? error;

  /// Import ou export en cours.
  bool busy = false;

  // ── Données brutes
  List<Operation> _operations = const [];
  List<Depense> _depenses = const [];
  List<Prelevement> _prelevements = const [];
  List<Charge> _charges = const [];
  List<FacturesJiroData> _facturesJiro = const [];
  List<ReleveElectricite> releves = const [];
  List<ImportLog> imports = const [];

  // ── État de navigation
  AppSection section = AppSection.dashboard;
  Period period = Period.day;

  /// Les charges pèsent-elles sur le solde du mois ? Bascule offerte au
  /// cadrage Mois, et persistée : c'est une façon de lire, pas un état d'écran.
  bool chargesIncluses = true;

  /// Date courante — initialisée sur le dernier enregistrement en base,
  /// jamais sur aujourd'hui.
  DateTime date = DateTime.now();
  DateTime lastRecordDate = DateTime.now();

  /// Mois sélectionné dans l'écran Prélèvements.
  DateTime mois = DateTime(DateTime.now().year, DateTime.now().month);

  /// Mois sélectionné dans l'écran Charges. Distinct de [mois] : on consulte
  /// souvent les charges d'un mois en corrigeant les prélèvements d'un autre.
  DateTime moisCharges = DateTime(DateTime.now().year, DateTime.now().month);

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
        _db.getAllCharges(),
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
      _charges = results[5] as List<Charge>;
      imports = await _loadImportLogs();
      chargesIncluses = await _loadChargesPreference();

      lastRecordDate = _computeLastRecordDate();
      if (!keepDate) {
        date = lastRecordDate;
        mois = DateTime(date.year, date.month);
        moisCharges = DateTime(date.year, date.month);
      }
      error = null;
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      update();
    }
  }

  /// Les charges sont volontairement absentes : saisir celle du mois prochain
  /// projetterait le tableau de bord en avant, sur une période sans caisse.
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
    if (s == AppSection.charges) {
      moisCharges = DateTime(date.year, date.month);
    }
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

  void setMoisCharges(DateTime m) {
    moisCharges = m;
    update();
  }

  /// Bascule l'imputation des charges au solde du mois. La préférence survit
  /// à la fermeture : c'est une façon de lire les chiffres, pas un état d'écran.
  Future<void> setChargesIncluses(bool v) async {
    chargesIncluses = v;
    update();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_chargesKey, v);
    } catch (_) {
      // Le confort d'une préférence retenue ne vaut pas un écran en erreur.
    }
  }

  Future<bool> _loadChargesPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_chargesKey) ?? true;
    } catch (_) {
      return true;
    }
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
      _charges.length +
      releves.length;

  Map<AppSection, int> get counts => {
    AppSection.operations: _operations.length,
    AppSection.expenses: _depenses.length,
    AppSection.charges: _charges.length,
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

  /// Charges imputables à la fenêtre, triées du plus lourd au plus léger.
  ///
  /// La garde sur le cadrage n'est pas une commodité : datée du 1er du mois,
  /// une charge tomberait sinon dans la fenêtre du *jour* « 1er » et dans la
  /// *semaine* qui le contient. Un loyer n'appartient à aucun jour — seul le
  /// cadrage Mois peut le porter.
  ///
  /// Le résultat ignore [chargesIncluses] : la bascule décide de l'imputation
  /// au solde, pas de l'existence des charges, que la carte affiche même
  /// quand elles sont exclues.
  /// Ce que coûte une ligne : le prix unitaire ne suffit plus depuis qu'une
  /// charge peut porter une quantité.
  static int _totalCharge(Charge c) => c.prixUnitaire * c.quantite;

  List<Charge> _chargesIn(DateTime start, DateTime end, Period p) {
    if (p != Period.month) return const [];
    return _charges.where((c) => _within(c.mois, start, end)).toList()
      ..sort((a, b) => _totalCharge(b).compareTo(_totalCharge(a)));
  }

  PeriodTotals _totals(DateTime start, DateTime end, Period p) {
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
    final chs = _chargesIn(start, end, p);
    return PeriodTotals(
      entrant: entrant,
      sortant: sortant,
      prelevement: prelevement,
      nbOperations: nbOps,
      nbDepenses: nbDep,
      nbPrelevements: nbPrel,
      // Exclues, les charges sortent du solde mais restent lisibles sur la
      // carte, que `DashboardData.chargesDuMois` alimente séparément.
      charges: chargesIncluses
          ? chs.fold<int>(0, (s, c) => s + _totalCharge(c))
          : 0,
      nbCharges: chargesIncluses ? chs.length : 0,
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

    final charges = _chargesIn(start, end, period);

    return DashboardData(
      totals: _totals(start, end, period),
      previousTotals: _totals(pStart, pEnd, period),
      chargesDuMois: [
        for (final c in charges)
          DepenseRow(
            // « Ramette A4 ×3 » : sans la quantité, un total de 55 500 face à
            // un prix unitaire de 18 500 passerait pour une faute de frappe.
            libelle: c.quantite > 1 ? '${c.libelle} ×${c.quantite}' : c.libelle,
            categorie: CategoryRules.resolveCharge(c.categorie, c.libelle),
            montant: _totalCharge(c),
          ),
      ],
      chargesIncluses: chargesIncluses,
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
      repartition: _repartition(deps, charges),
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
      final t = _totals(s, e, period);
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

  /// Les charges rejoignent la répartition quand elles pèsent sur le solde :
  /// un camembert qui ignore le loyer dit le contraire de la carte voisine.
  List<(String, int)> _repartition(List<Depense> deps, List<Charge> charges) {
    final byCat = <String, int>{};
    for (final d in deps) {
      final c = CategoryRules.of(d.libelle);
      byCat[c] = (byCat[c] ?? 0) + d.montant;
    }
    if (chargesIncluses) {
      for (final ch in charges) {
        final c = CategoryRules.resolveCharge(ch.categorie, ch.libelle);
        byCat[c] = (byCat[c] ?? 0) + _totalCharge(ch);
      }
    }
    final entries = byCat.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return entries;
  }

  // ─────────────────────────────── Écrans-listes ───────────────────────────────

  List<LedgerItem> operationItems(BuildContext context) {
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
          onEdit: () => editOperation(context, o),
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
          onEdit: () => editDepense(context, d),
        ),
    ];
  }

  List<LedgerItem> prelevementItems(BuildContext context) {
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
          onEdit: () => editPrelevement(context, p),
          cells: [
            LedgerCell(Fmt.cap(Fmt.longDate(p.datePrelevement))),
            LedgerCell(Fmt.num(p.montant), mono: true),
            LedgerCell(Fmt.hour(p.datePrelevement), mono: true),
          ],
        ),
    ];
  }

  // ──────────────────────────────── Charges ────────────────────────────────
  // Saisies dans l'app, pas importées : avec la facture JIRO, la seule autre
  // écriture du produit. Une charge vaut pour un mois entier — elle n'a donc
  // ni jour ni heure, contrairement à tout le reste de la base.

  /// Libellés déjà employés, avec ce qu'ils valaient la dernière fois.
  ///
  /// Les charges d'abord, classées par fréquence : on reconduit chaque mois
  /// les mêmes lignes, et ce sont donc les propositions les plus sûres. Les
  /// libellés de dépenses suivent, sans doublon — sans eux, la toute première
  /// charge se saisirait devant une liste vide.
  List<ChargeSuggestion> get suggestionsCharges {
    // La plus récente de chaque libellé porte les valeurs à reprendre : c'est
    // le dernier loyer connu qu'on veut proposer, pas celui d'il y a deux ans.
    final derniere = <String, Charge>{};
    final freq = <String, int>{};
    for (final c in _charges) {
      if (c.libelle.trim().isEmpty) continue;
      final k = c.libelle.trim().toLowerCase();
      freq[k] = (freq[k] ?? 0) + 1;
      final d = derniere[k];
      if (d == null || _plusRecente(c, d)) derniere[k] = c;
    }

    // Une dépense n'a ni quantité ni catégorie choisie, mais son montant fait
    // un prix unitaire honnête faute de mieux.
    final vues = <String, Depense>{};
    final freqDep = <String, int>{};
    for (final d in _depenses) {
      if (d.libelle.trim().isEmpty) continue;
      final k = d.libelle.trim().toLowerCase();
      if (derniere.containsKey(k)) continue;
      freqDep[k] = (freqDep[k] ?? 0) + 1;
      final p = vues[k];
      if (p == null || d.dateDepense.isAfter(p.dateDepense)) vues[k] = d;
    }

    List<String> parFrequence(Iterable<String> cles, Map<String, int> f) =>
        cles.toList()..sort((a, b) {
          final n = f[b]!.compareTo(f[a]!);
          return n != 0 ? n : a.compareTo(b);
        });

    return [
      for (final k in parFrequence(derniere.keys, freq))
        ChargeSuggestion(
          libelle: derniere[k]!.libelle,
          prixUnitaire: derniere[k]!.prixUnitaire,
          quantite: derniere[k]!.quantite,
          categorie: derniere[k]!.categorie,
        ),
      for (final k in parFrequence(vues.keys, freqDep))
        ChargeSuggestion(
          libelle: vues[k]!.libelle,
          prixUnitaire: vues[k]!.montant,
        ),
    ];
  }

  /// Le mois d'imputation prime sur la date de saisie : c'est lui qui dit à
  /// quelle période la ligne appartient.
  static bool _plusRecente(Charge a, Charge b) {
    final m = a.mois.compareTo(b.mois);
    return m != 0
        ? m > 0
        : a.dateEnregistrement.isAfter(b.dateEnregistrement);
  }

  /// Charges du mois sélectionné, de la plus lourde à la plus légère.
  List<ChargeMensuelle> get chargesDuMois {
    final list =
        _charges
            .where(
              (c) =>
                  c.mois.year == moisCharges.year &&
                  c.mois.month == moisCharges.month,
            )
            .toList()
          ..sort((a, b) => _totalCharge(b).compareTo(_totalCharge(a)));
    return [
      for (final c in list)
        ChargeMensuelle(
          id: c.idCharge,
          libelle: c.libelle,
          prixUnitaire: c.prixUnitaire,
          mois: c.mois,
          dateEnregistrement: c.dateEnregistrement,
          quantite: c.quantite,
          categorie: c.categorie,
        ),
    ];
  }

  int get totalChargesDuMois =>
      chargesDuMois.fold<int>(0, (s, c) => s + c.montant);

  /// Ce que reprendrait « Reporter le mois précédent » — vide si le mois
  /// courant est déjà servi, car le report n'écrase jamais une saisie.
  List<ChargeMensuelle> get chargesReportables {
    if (chargesDuMois.isNotEmpty) return const [];
    final prev = DateTime(moisCharges.year, moisCharges.month - 1);
    final list =
        _charges
            .where((c) => c.mois.year == prev.year && c.mois.month == prev.month)
            .toList()
          ..sort((a, b) => _totalCharge(b).compareTo(_totalCharge(a)));
    return [
      for (final c in list)
        ChargeMensuelle(
          id: c.idCharge,
          libelle: c.libelle,
          prixUnitaire: c.prixUnitaire,
          mois: c.mois,
          dateEnregistrement: c.dateEnregistrement,
          quantite: c.quantite,
          categorie: c.categorie,
        ),
    ];
  }

  Future<void> addCharge(BuildContext context) async {
    final edit = await showChargeEditor(
      context,
      mois: moisCharges,
      suggestions: suggestionsCharges,
    );
    if (edit == null) return;
    try {
      await _db.saveCharge(
        libelle: edit.libelle,
        prixUnitaire: edit.prixUnitaire,
        quantite: edit.quantite,
        mois: edit.mois,
        dateEnregistrement: edit.dateEnregistrement,
        categorie: edit.categorie,
      );
      await load(keepDate: true);
      moisCharges = DateTime(edit.mois.year, edit.mois.month);
      update();
      _toast('Charge ajoutée', '${edit.libelle} · ${Fmt.ar(edit.montant)}');
    } catch (e) {
      _toast('Charge non enregistrée', '$e', ok: false);
    }
  }

  Future<void> editCharge(BuildContext context, ChargeMensuelle c) async {
    final edit = await showChargeEditor(
      context,
      libelle: c.libelle,
      prixUnitaire: c.prixUnitaire,
      quantite: c.quantite,
      mois: c.mois,
      dateEnregistrement: c.dateEnregistrement,
      categorie: c.categorie,
      suggestions: suggestionsCharges,
    );
    if (edit == null) return;
    try {
      final touched = await _db.updateCharge(
        id: c.id,
        libelle: edit.libelle,
        prixUnitaire: edit.prixUnitaire,
        quantite: edit.quantite,
        mois: edit.mois,
        dateEnregistrement: edit.dateEnregistrement,
        categorie: edit.categorie,
      );
      if (touched == 0) {
        _toast(
          'Charge introuvable',
          'La ligne a disparu de la base entre-temps — rien n\'a été écrit.',
          ok: false,
        );
        return;
      }
      await load(keepDate: true);
      // Changer de mois sortirait la ligne du filtre : on suit la charge.
      moisCharges = DateTime(edit.mois.year, edit.mois.month);
      update();
      _toast('Charge modifiée', '${edit.libelle} · ${Fmt.ar(edit.montant)}');
    } catch (e) {
      _toast('Modification impossible', '$e', ok: false);
    }
  }

  Future<void> deleteCharge(ChargeMensuelle c) async {
    try {
      await _db.deleteCharge(c.id);
      await load(keepDate: true);
      _toast('Charge supprimée', '${c.libelle} · ${Fmt.ar(c.montant)}');
    } catch (e) {
      _toast('Suppression impossible', '$e', ok: false);
    }
  }

  /// Recopie les charges du mois précédent sur le mois courant. Les montants
  /// sont repris tels quels : une facture varie, l'utilisateur corrigera la
  /// ligne — c'est toujours moins de frappe que de tout ressaisir.
  Future<void> reconduireCharges() async {
    final source = chargesReportables;
    if (source.isEmpty) return;
    try {
      for (final c in source) {
        // Sans date explicite, le report s'enregistre à maintenant : c'est
        // bien aujourd'hui qu'on l'a saisi, même s'il reprend un vieux montant.
        // La catégorie, elle, se reprend telle quelle — le report doit rendre
        // la ligne du mois précédent, choix de catégorie compris.
        await _db.saveCharge(
          libelle: c.libelle,
          prixUnitaire: c.prixUnitaire,
          quantite: c.quantite,
          mois: moisCharges,
          categorie: c.categorie,
        );
      }
      await load(keepDate: true);
      moisCharges = DateTime(moisCharges.year, moisCharges.month);
      update();
      _toast(
        'Charges reportées',
        '${source.length} ligne${source.length > 1 ? 's' : ''} reprise'
            '${source.length > 1 ? 's' : ''} du mois précédent',
      );
    } catch (e) {
      _toast('Report impossible', '$e', ok: false);
    }
  }

  // ─────────────────────────────── Corrections ───────────────────────────────
  // Les données arrivent par import ; la saisie d'origine se fait ailleurs.
  // Ces deux méthodes ne servent qu'à rattraper une faute de frappe : elles
  // réécrivent une ligne existante sans jamais toucher à son identifiant.

  Future<void> editOperation(BuildContext context, Operation o) async {
    final edit = await showOperationEditor(
      context,
      nom: o.nomOperation,
      prixUnitaire: o.prixOperation,
      quantite: o.quantiteOperation,
      date: o.dateOperation,
    );
    if (edit == null) return;
    try {
      final touched = await _db.updateOperation(
        id: o.idOperation,
        nomOperation: edit.nom,
        prixOperation: edit.prixUnitaire,
        quantiteOperation: edit.quantite,
        dateOperation: edit.date,
      );
      if (touched == 0) {
        _toast(
          'Opération introuvable',
          'La ligne a disparu de la base entre-temps — rien n\'a été écrit.',
          ok: false,
        );
        return;
      }
      // La date courante ne doit pas sauter au dernier enregistrement à cause
      // d'une simple correction.
      await load(keepDate: true);
      _toast(
        'Opération modifiée',
        '${edit.nom} · ${Fmt.ar(edit.prixUnitaire * edit.quantite)}',
      );
    } catch (e) {
      _toast('Modification impossible', '$e', ok: false);
    }
  }

  Future<void> editDepense(BuildContext context, Depense d) async {
    final edit = await showDepenseEditor(
      context,
      libelle: d.libelle,
      montant: d.montant,
      date: d.dateDepense,
    );
    if (edit == null) return;
    try {
      final touched = await _db.updateDepense(
        id: d.idDepense,
        libelle: edit.libelle,
        montant: edit.montant,
        dateDepense: edit.date,
      );
      if (touched == 0) {
        _toast(
          'Dépense introuvable',
          'La ligne a disparu de la base entre-temps — rien n\'a été écrit.',
          ok: false,
        );
        return;
      }
      await load(keepDate: true);
      _toast(
        'Dépense modifiée',
        '${edit.libelle} · ${Fmt.ar(edit.montant)}',
      );
    } catch (e) {
      _toast('Modification impossible', '$e', ok: false);
    }
  }

  Future<void> editPrelevement(BuildContext context, Prelevement p) async {
    final edit = await showPrelevementEditor(
      context,
      montant: p.montant,
      date: p.datePrelevement,
    );
    if (edit == null) return;
    try {
      final touched = await _db.updatePrelevement(
        id: p.idPrelevement,
        montant: edit.montant,
        datePrelevement: edit.date,
      );
      if (touched == 0) {
        _toast(
          'Prélèvement introuvable',
          'La ligne a disparu de la base entre-temps — rien n\'a été écrit.',
          ok: false,
        );
        return;
      }
      await load(keepDate: true);
      // Déplacer un prélèvement d'un mois à l'autre le sortirait du filtre :
      // on suit la ligne plutôt que de laisser l'utilisateur la chercher.
      mois = DateTime(edit.date.year, edit.date.month);
      update();
      _toast('Prélèvement modifié', Fmt.ar(edit.montant));
    } catch (e) {
      _toast('Modification impossible', '$e', ok: false);
    }
  }

  Future<void> editReleve(BuildContext context, ReleveElectricite r) async {
    final edit = await showReleveEditor(
      context,
      compteur: r.compteur,
      sousCompteur: r.sousCompteur,
      date: r.date,
    );
    if (edit == null) return;
    try {
      final touched = await _db.updateReleve(
        id: r.id,
        compteur: edit.compteur,
        sousCompteur: edit.sousCompteur,
        dateReleve: edit.date,
      );
      if (touched == 0) {
        _toast(
          'Relevé introuvable',
          'La ligne a disparu de la base entre-temps — rien n\'a été écrit.',
          ok: false,
        );
        return;
      }
      await load(keepDate: true);
      // La consommation n'est pas stockée : corriger un index rejoue les deux
      // périodes qui l'encadrent, et le partage JIRO qui s'y appuie.
      _toast(
        'Relevé modifié',
        'Général ${Fmt.dec(edit.compteur)} · '
            'sous-compteur ${Fmt.dec(edit.sousCompteur)}',
      );
    } catch (e) {
      _toast('Modification impossible', '$e', ok: false);
    }
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

  /// Avec les charges mensuelles, l'une des deux écritures de l'application :
  /// enregistre la facture puis imprime le PDF de partage.
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
    if (ok) {
      AppToast.success(title, message: message);
    } else {
      AppToast.error(title, message: message);
    }
  }
}

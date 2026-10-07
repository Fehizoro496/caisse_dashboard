import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/app_shell.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
import 'package:caisse_dashboard/view/widgets/prestations_pie_chart.dart';
import 'package:flutter/material.dart';

/// Données prêtes à afficher pour une période. Le contrôleur les calcule ;
/// l'écran ne fait aucune requête.
class DashboardData {
  const DashboardData({
    required this.totals,
    required this.previousTotals,
    required this.operations,
    required this.depenses,
    required this.trend,
    required this.repartition,
    this.chargesDuMois = const [],
    this.chargesIncluses = true,
  });

  final PeriodTotals totals;
  final PeriodTotals previousTotals;

  /// En Jour : les lignes telles quelles. En Semaine/Mois : agrégées par nom.
  final List<OperationRow> operations;
  final List<DepenseRow> depenses;

  /// Charges du mois — vide hors cadrage Mois. Peuplée même quand
  /// [chargesIncluses] est faux : la carte les montre alors sans les imputer.
  final List<DepenseRow> chargesDuMois;

  /// Les charges pèsent-elles sur [PeriodTotals.soldeNet] ?
  final bool chargesIncluses;

  /// Les 12 mois de l'année de la date courante, quel que soit le cadrage.
  final List<BarGroup> trend;
  final List<(String, int)> repartition;

  int get totalCharges => chargesDuMois.fold<int>(0, (s, c) => s + c.montant);

  static const empty = DashboardData(
    totals: PeriodTotals.empty,
    previousTotals: PeriodTotals.empty,
    operations: [],
    depenses: [],
    trend: [],
    repartition: [],
  );
}

class OperationRow {
  const OperationRow({
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.total,
    required this.meta,
  });

  final String nom;
  final int prixUnitaire;
  final int quantite;
  final int total;

  /// Heure en vue Jour, nombre de lignes en vue agrégée.
  final String meta;
}

class DepenseRow {
  const DepenseRow({
    required this.libelle,
    required this.categorie,
    required this.montant,
  });

  final String libelle;
  final String categorie;
  final int montant;
}

/// Tableau de bord : piloté par une date courante unique, initialisée sur le
/// dernier enregistrement en base — jamais sur aujourd'hui.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.data,
    required this.date,
    required this.period,
    required this.lastRecordDate,
    required this.onPeriodChanged,
    required this.onDateChanged,
    required this.onOpenSection,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onPickDate,
    this.onToggleCharges,
  });

  final DashboardData data;
  final DateTime date;
  final Period period;

  /// Borne haute de la navigation : on ne dépasse pas la base.
  final DateTime lastRecordDate;

  final ValueChanged<Period> onPeriodChanged;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<AppSection> onOpenSection;

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final VoidCallback? onPickDate;

  /// Bascule l'imputation des charges au solde. N'apparaît qu'en cadrage Mois.
  final ValueChanged<bool>? onToggleCharges;

  /// Les charges ne concernent que le mois : partout ailleurs, ni carte,
  /// ni bascule, ni bloc dans le panneau des dépenses.
  bool get _showCharges => period == Period.month;

  int get _stepDays => switch (period) {
    Period.day => 1,
    Period.week => 7,
    Period.month => 30,
  };

  String get _dateLabel => switch (period) {
    Period.day => Fmt.cap(Fmt.longDate(date)),
    Period.week => 'Semaine du ${Fmt.shortDate(_startOfWeek(date))}',
    Period.month => Fmt.cap(Fmt.month(date)),
  };

  String get _periodWord => switch (period) {
    Period.day => 'jour',
    Period.week => 'semaine',
    Period.month => 'mois',
  };

  static DateTime _startOfWeek(DateTime d) =>
      d.subtract(Duration(days: (d.weekday + 6) % 7));

  int? get _delta {
    final prev = data.previousTotals.soldeNetPour(period);
    if (prev == 0) return null;
    return ((data.totals.soldeNetPour(period) - prev) / prev.abs() * 100)
        .round();
  }

  DateTime? get _nextDate {
    final n = date.add(Duration(days: _stepDays));
    return n.isAfter(lastRecordDate) ? null : n;
  }

  /// Barre d'outils à passer à [AppShell.toolbar] : navigation de date
  /// + cadrage Jour/Semaine/Mois. L'écran ne dessine pas la barre lui-même.
  Widget buildToolbar() => Builder(
    builder: (context) => DateToolbar(
      label: _dateLabel,
      period: period,
      onPeriodChanged: onPeriodChanged,
      onPrev: () => onDateChanged(date.subtract(Duration(days: _stepDays))),
      onNext: _nextDate == null ? null : () => onDateChanged(_nextDate!),
      onPickDate: onPickDate,
      trailing: _showCharges && onToggleCharges != null
          ? TogglePill(
              label: 'Charges',
              value: data.chargesIncluses,
              color: context.tokens.charge,
              onChanged: onToggleCharges!,
              tooltip: data.chargesIncluses
                  ? 'Les charges du mois pèsent sur le solde net'
                  : 'Les charges du mois sont affichées mais hors du solde',
            )
          : null,
    ),
  );

  /// Hauteurs des bandes, les mêmes aux trois cadrages : tableaux, anneau et
  /// répartition, puis courbes. Leur somme dépasse la fenêtre, donc la page
  /// défile — c'est ce qui laisse aux tableaux sept ou huit lignes. La bande
  /// de tête, elle, n'a pas de hauteur imposée : elle se mesure (voir
  /// [_TotalsRow]), sinon un texte agrandi par le système la ferait déborder
  /// de quelques pixels.
  static const _tablesHeight = 380.0;
  static const _chartsHeight = 258.0;
  static const _trendHeight = 236.0;

  @override
  Widget build(BuildContext context) {
    return AsyncPane(
      loading: loading,
      error: error,
      onRetry: onRetry,
      child: PrestationsScope(
        child: LayoutBuilder(
          builder: (context, box) {
            final head = _TotalsRow(
              totals: data.totals,
              period: period,
              periodWord: _periodWord,
              delta: _delta,
              width: box.maxWidth,
              onOpenSection: onOpenSection,
              charges: _showCharges ? data.totalCharges : null,
              nbCharges: data.chargesDuMois.length,
              chargesIncluses: data.chargesIncluses,
            );

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  head,
                  const SizedBox(height: 12),
                  SizedBox(height: _tablesHeight, child: _tables()),
                  const SizedBox(height: 12),
                  SizedBox(height: _chartsHeight, child: _charts(context)),
                  const SizedBox(height: 12),
                  SizedBox(height: _trendHeight, child: _trendPanel(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _tables() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 155,
        // Le tableau sert de légende à l'anneau. Au jour, il liste les
        // opérations une à une, avec leur heure.
        child: PrestationsPanel(
          operations: data.operations,
          totalEntrant: data.totals.entrant,
          byLine: period == Period.day,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(flex: 100, child: _DepensesPanel(data: data)),
    ],
  );

  Widget _charts(BuildContext context) {
    final x = context.texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 155,
          child: PrestationsPieChart(operations: data.operations),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 100,
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Répartition des dépenses', style: x.cardTitle),
                const SizedBox(height: 14),
                Expanded(
                  child: SingleChildScrollView(
                    child: CategoryBreakdown(
                      entries: data.repartition,
                      colorOf: (c) => categoryColor(context, c),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _trendPanel(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, box) => Row(
              children: [
                Expanded(
                  child: Text(
                    'Année ${date.year} · entrants vs prélèvements',
                    style: x.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Carte étroite : le titre prime sur la légende, que les
                // couleurs des barres rendent de toute façon lisible.
                if (box.maxWidth > 420) ...[
                  _Legend(color: t.income, label: 'Entrants'),
                  const SizedBox(width: 14),
                  _Legend(color: t.drawing, label: 'Prélèvements'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TrendLineChart(
              groups: data.trend,
              primaryColor: t.income,
              secondaryColor: t.drawing,
              primaryLabel: 'Entrants',
              secondaryLabel: 'Prélèvements',
            ),
          ),
        ],
      ),
    );
  }
}

/// Rapprochement du prélèvement : ce qui a été saisi face à ce que la caisse
/// laisse attendre (entrant − sortant). Même gabarit que [SoldeNetCard], à sa
/// droite : l'écart en grand, le calcul rappelé dessous. L'état se lit dans
/// l'étiquette — icône et mot — autant que dans la couleur.
class _Reconciliation extends StatelessWidget {
  const _Reconciliation({required this.totals});

  final PeriodTotals totals;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final ecart = totals.ecartPrelevement;
    final ok = ecart >= 0;
    final color = ok ? t.success : t.warning;

    return Tooltip(
      message: 'Calculé = entrant − sortant · écart = saisi − calculé',
      waitDuration: const Duration(milliseconds: 400),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'ÉCART DE PRÉLÈVEMENT',
                    style: x.overline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  ok ? Icons.check_circle_outline : Icons.error_outline,
                  size: 13,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  switch (ecart) {
                    0 => 'Conforme',
                    > 0 => 'Excédent',
                    _ => 'À vérifier',
                  },
                  style: x.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${ecart > 0
                          ? '+'
                          : ecart < 0
                          ? '−'
                          : ''}${Fmt.num(ecart.abs())}',
                      key: const ValueKey('ecart-prelevement'),
                      style: x.heroAmount.copyWith(color: color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Ar', style: x.monoMuted.copyWith(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 12),
            // Une seule ligne, toujours — comme la formule du solde. À l'étroit,
            // le calcul se réduit : un chiffre ne se tronque pas.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('saisi ', style: x.monoFaint),
                  Text(Fmt.num(totals.prelevement), style: x.monoMuted),
                  Text('  −  calculé ', style: x.monoFaint),
                  Text(
                    Fmt.num(totals.prelevementCalcule),
                    key: const ValueKey('prelevement-calcule'),
                    style: x.monoMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.totals,
    required this.period,
    required this.periodWord,
    required this.delta,
    required this.width,
    required this.onOpenSection,
    required this.charges,
    required this.nbCharges,
    required this.chargesIncluses,
  });

  final PeriodTotals totals;
  final Period period;
  final String periodWord;
  final int? delta;

  /// Largeur offerte à la tête : sert à caler la carte d'écart sur la grille
  /// des cartes du dessous.
  final double width;
  final ValueChanged<AppSection> onOpenSection;

  /// Total des charges du mois, ou `null` hors cadrage Mois — auquel cas la
  /// quatrième carte n'existe pas.
  final int? charges;
  final int nbCharges;
  final bool chargesIncluses;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final solde = SoldeNetCard(
      solde: totals.soldeNetPour(period),
      periodWord: periodWord,
      deltaPercent: delta,
      formula: period == Period.month
          ? (chargesIncluses
                ? 'prélèvement saisi − charges'
                : 'prélèvement saisi')
          : 'entrant − sortant − prélèv.',
    );
    final cards = [
      TotalCard(
        label: 'Entrant',
        amount: totals.entrant,
        sub: '${totals.nbOperations} opérations',
        color: t.income,
        onTap: () => onOpenSection(AppSection.operations),
      ),
      TotalCard(
        label: 'Sortant',
        amount: totals.sortant,
        sub: '${totals.nbDepenses} dépenses',
        color: t.expense,
        onTap: () => onOpenSection(AppSection.expenses),
      ),
      TotalCard(
        label: 'Prélèvement saisi',
        amount: totals.prelevement,
        sub: '${totals.nbPrelevements} retraits',
        color: t.drawing,
        onTap: () => onOpenSection(AppSection.drawings),
      ),
      if (charges != null)
        TotalCard(
          label: 'Charges',
          amount: charges!,
          // Exclues, elles restent affichées : cacher le loyer parce qu'il
          // ne compte pas ferait croire qu'il n'a pas été saisi.
          sub: chargesIncluses
              ? '$nbCharges ${nbCharges > 1 ? 'charges' : 'charge'} · mois entier'
              : 'hors solde net',
          color: t.charge,
          muted: !chargesIncluses,
          onTap: () => onOpenSection(AppSection.charges),
        ),
    ];

    // Deux rangées, quel que soit le cadrage. En haut, l'écart s'aligne sur
    // la grille du dessous : la dernière carte, ou les deux dernières quand
    // les charges du mois en ajoutent une quatrième.
    const gap = 12.0;
    final n = cards.length;
    final cardWidth = (width - gap * (n - 1)) / n;
    final ecartWidth = n > 3 ? cardWidth * 2 + gap : cardWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _band(
          minHeight: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: solde),
              const SizedBox(width: gap),
              SizedBox(
                width: ecartWidth,
                child: _Reconciliation(totals: totals),
              ),
            ],
          ),
        ),
        const SizedBox(height: gap),
        _band(
          minHeight: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Une rangée de cartes : jamais plus courte que son contenu, jamais plus
  /// basse que le plancher esthétique. `minHeight` remplace l'ancienne hauteur
  /// imposée, qui débordait dès que le système agrandissait le texte.
  static Widget _band({required double minHeight, required Widget child}) =>
      ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight),
        child: IntrinsicHeight(child: child),
      );
}

/// Une entrée du panneau : soit un intertitre de section, soit une ligne.
/// Les charges y voisinent les dépenses sans se confondre avec elles — même
/// colonne de montants, section et pastille distinctes.
class _PanelEntry {
  const _PanelEntry.section(this.title) : row = null, charge = false;
  const _PanelEntry.line(DepenseRow this.row, {this.charge = false})
    : title = null;

  final String? title;
  final DepenseRow? row;
  final bool charge;

  bool get isSection => title != null;
}

class _DepensesPanel extends StatelessWidget {
  const _DepensesPanel({required this.data});
  final DashboardData data;

  List<_PanelEntry> get _entries {
    final charges = data.chargesDuMois;
    return [
      if (charges.isNotEmpty) ...[
        _PanelEntry.section(
          data.chargesIncluses
              ? 'Charges du mois'
              : 'Charges du mois · exclues',
        ),
        for (final c in charges) _PanelEntry.line(c, charge: true),
        if (data.depenses.isNotEmpty) const _PanelEntry.section('Dépenses'),
      ],
      for (final d in data.depenses) _PanelEntry.line(d),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final entries = _entries;
    final nbCharges = data.chargesDuMois.length;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: nbCharges > 0 ? 'Dépenses et charges' : 'Dépenses',
            meta: nbCharges > 0
                ? '${data.depenses.length} + $nbCharges lignes'
                : '${data.depenses.length} lignes',
          ),
          Expanded(
            child: entries.isEmpty
                ? const EmptyState(title: 'Aucune dépense sur cette période.')
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, i) {
                      final e = entries[i];
                      return e.isSection
                          ? TotalBar(height: 26, label: e.title!, value: '')
                          : _Line(
                              entry: e,
                              pale: e.charge && !data.chargesIncluses,
                            );
                    },
                  ),
          ),
          TotalBar(
            label: data.totals.charges > 0
                ? 'Sortant + charges'
                : 'Total sortant',
            meta: data.totals.charges > 0
                ? 'dont ${Fmt.num(data.totals.charges)}'
                : null,
            value: Fmt.ar(data.totals.sortant + data.totals.charges),
            valueColor: t.expense,
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.entry, required this.pale});
  final _PanelEntry entry;

  /// Charge exclue du solde : affichée en retrait, car elle est bien saisie —
  /// simplement pas comptée.
  final bool pale;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final d = entry.row!;

    return Container(
      height: t.rowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          KindDot(
            entry.charge ? t.charge : categoryColor(context, d.categorie),
            size: 6,
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              d.libelle,
              style: pale ? x.bodyMuted : x.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // « ÉLECTRICITÉ » à texte agrandi pousserait le montant hors de la
          // ligne : la catégorie s'abrège, jamais le chiffre.
          Flexible(
            flex: 2,
            child: Text(
              d.categorie.toUpperCase(),
              style: x.columnHeader,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Text(Fmt.num(d.montant), style: pale ? x.monoFaint : x.monoBody),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      KindDot(color, size: 8),
      const SizedBox(width: 6),
      Text(label, style: context.texts.caption),
    ],
  );
}

/// Couleur d'une catégorie de dépense. Toujours dérivée des jetons :
/// aucune couleur littérale dans les écrans.
Color categoryColor(BuildContext context, String categorie) {
  final t = context.tokens;
  return switch (categorie) {
    'Papier' => t.accent,
    'Consommables' => t.expense,
    'Maintenance' => t.drawing,
    'Électricité' => t.electric,
    'Internet' => t.income,
    'Salaires' => t.muted,
    'Loyer' => t.charge,
    'Fournitures' => t.text,
    // Propre aux charges : « Facture » y couvre ce qu'Électricité et Internet
    // séparent côté dépenses, d'où la couleur de l'électricité, qui domine.
    'Facture' => t.electric,
    _ => t.faint,
  };
}

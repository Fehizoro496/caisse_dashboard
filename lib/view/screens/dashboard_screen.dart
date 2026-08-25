import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/app_shell.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
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
  });

  final PeriodTotals totals;
  final PeriodTotals previousTotals;

  /// En Jour : les lignes telles quelles. En Semaine/Mois : agrégées par nom.
  final List<OperationRow> operations;
  final List<DepenseRow> depenses;

  /// 7 jours / 8 semaines / 6 mois selon le cadrage.
  final List<BarGroup> trend;
  final List<(String, int)> repartition;

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
    final prev = data.previousTotals.soldeNet;
    if (prev == 0) return null;
    return ((data.totals.soldeNet - prev) / prev.abs() * 100).round();
  }

  DateTime? get _nextDate {
    final n = date.add(Duration(days: _stepDays));
    return n.isAfter(lastRecordDate) ? null : n;
  }

  /// Barre d'outils à passer à [AppShell.toolbar] : navigation de date
  /// + cadrage Jour/Semaine/Mois. L'écran ne dessine pas la barre lui-même.
  Widget buildToolbar() => DateToolbar(
    label: _dateLabel,
    period: period,
    onPeriodChanged: onPeriodChanged,
    onPrev: () => onDateChanged(date.subtract(Duration(days: _stepDays))),
    onNext: _nextDate == null ? null : () => onDateChanged(_nextDate!),
    onPickDate: onPickDate,
  );

  /// Hauteurs plancher des trois bandes. En dessous de leur somme, la page
  /// défile au lieu d'écraser les tableaux. La bande de tête, elle, n'a pas de
  /// hauteur imposée : elle se mesure (voir [_TotalsRow]), sinon un texte
  /// agrandi par le système la ferait déborder de quelques pixels.
  static const _tablesMinHeight = 260.0;
  static const _chartsHeight = 258.0;

  @override
  Widget build(BuildContext context) {
    return AsyncPane(
      loading: loading,
      error: error,
      onRetry: onRetry,
      child: LayoutBuilder(
        builder: (context, box) {
          // Sous ~1180 px les quatre cartes de tête passent sur deux rangs.
          final tight = box.maxWidth < 1180;

          // Estimation, seulement pour décider du passage en défilement :
          // la bande réelle s'ajuste toute seule à son contenu.
          final scale = MediaQuery.textScalerOf(context).scale(1);
          final totalsHeight = (tight ? 220.0 : 118.0) * scale;
          final needed =
              totalsHeight + 12 + _tablesMinHeight + 12 + _chartsHeight;
          final short = box.maxHeight < needed;

          final head = _TotalsRow(
            totals: data.totals,
            periodWord: _periodWord,
            delta: _delta,
            wrap: tight,
            onOpenSection: onOpenSection,
          );

          if (short) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  head,
                  const SizedBox(height: 12),
                  SizedBox(height: _tablesMinHeight, child: _tables()),
                  const SizedBox(height: 12),
                  SizedBox(height: _chartsHeight, child: _charts(context)),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              head,
              const SizedBox(height: 12),
              Expanded(child: _tables()),
              const SizedBox(height: 12),
              SizedBox(height: _chartsHeight, child: _charts(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _tables() => Row(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        flex: 155,
        child: _OperationsPanel(data: data, period: period),
      ),
      const SizedBox(width: 12),
      Expanded(flex: 100, child: _DepensesPanel(data: data)),
    ],
  );

  Widget _charts(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 155,
          child: Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, box) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          switch (period) {
                            Period.day =>
                              '7 derniers jours · entrants vs prélèvements',
                            Period.week =>
                              '8 dernières semaines · entrants vs prélèvements',
                            Period.month =>
                              '6 derniers mois · entrants vs prélèvements',
                          },
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
                  child: GroupedBarChart(
                    groups: data.trend,
                    primaryColor: t.income,
                    secondaryColor: t.drawing,
                    height: double.infinity,
                  ),
                ),
              ],
            ),
          ),
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
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({
    required this.totals,
    required this.periodWord,
    required this.delta,
    required this.wrap,
    required this.onOpenSection,
  });

  final PeriodTotals totals;
  final String periodWord;
  final int? delta;
  final bool wrap;
  final ValueChanged<AppSection> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final solde = SoldeNetCard(
      solde: totals.soldeNet,
      periodWord: periodWord,
      deltaPercent: delta,
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
        label: 'Prélèvement',
        amount: totals.prelevement,
        sub: '${totals.nbPrelevements} retraits',
        color: t.drawing,
        onTap: () => onOpenSection(AppSection.drawings),
      ),
    ];

    if (!wrap) {
      return _band(
        minHeight: 118,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 15, child: solde),
            for (final c in cards) ...[
              const SizedBox(width: 12),
              Expanded(flex: 10, child: c),
            ],
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _band(minHeight: 104, child: solde),
        const SizedBox(height: 12),
        _band(
          minHeight: 104,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
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

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel({required this.data, required this.period});
  final DashboardData data;
  final Period period;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final day = period == Period.day;
    final cols = [
      const Col('Prestation', flex: 3),
      const Col('P.U.', flex: 1, numeric: true),
      const Col('Qté', flex: 1, numeric: true),
      const Col('Total', flex: 2, numeric: true),
      Col(day ? 'Heure' : 'Lignes', flex: 1, numeric: true),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: day ? 'Opérations du jour' : 'Prestations agrégées',
            meta: '${data.operations.length} ${day ? 'lignes' : 'prestations'}',
          ),
          TableHeaderRow(cols: cols),
          Expanded(
            child: data.operations.isEmpty
                ? const EmptyState(title: 'Aucune opération sur cette période.')
                : ListView.builder(
                    itemCount: data.operations.length,
                    itemBuilder: (context, i) {
                      final o = data.operations[i];
                      return DataRow2(
                        cols: cols,
                        cells: [
                          Text(
                            o.nom,
                            style: x.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(Fmt.num(o.prixUnitaire), style: x.monoMuted),
                          Text('×${o.quantite}', style: x.monoMuted),
                          Text(Fmt.num(o.total), style: x.monoBody),
                          Text(o.meta, style: x.monoFaint),
                        ],
                      );
                    },
                  ),
          ),
          TotalBar(
            label: 'Total entrant',
            value: Fmt.ar(data.totals.entrant),
            valueColor: t.income,
          ),
        ],
      ),
    );
  }
}

class _DepensesPanel extends StatelessWidget {
  const _DepensesPanel({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: 'Dépenses',
            meta: '${data.depenses.length} lignes',
          ),
          Expanded(
            child: data.depenses.isEmpty
                ? const EmptyState(title: 'Aucune dépense sur cette période.')
                : ListView.builder(
                    itemCount: data.depenses.length,
                    itemBuilder: (context, i) {
                      final d = data.depenses[i];
                      return Container(
                        height: t.rowHeight,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: t.line)),
                        ),
                        child: Row(
                          children: [
                            KindDot(
                              categoryColor(context, d.categorie),
                              size: 6,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d.libelle,
                                style: x.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              d.categorie.toUpperCase(),
                              style: x.columnHeader,
                            ),
                            const SizedBox(width: 10),
                            Text(Fmt.num(d.montant), style: x.monoBody),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          TotalBar(
            label: 'Total sortant',
            value: Fmt.ar(data.totals.sortant),
            valueColor: t.expense,
          ),
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
    'Loyer' => t.text,
    _ => t.faint,
  };
}

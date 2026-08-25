import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart'
    show categoryColor;
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';

/// Une ligne d'un écran-liste, déjà formatée par le contrôleur.
class LedgerItem {
  const LedgerItem({
    required this.date,
    required this.amount,
    required this.cells,
    this.onEdit,
  });

  final DateTime date;
  final int amount;

  /// Contenu des colonnes, dans l'ordre de [LedgerConfig.columns].
  final List<LedgerCell> cells;

  /// Ouvre la correction de l'enregistrement. Absent = ligne non modifiable
  /// (prélèvements) ; la colonne d'action vient de [LedgerConfig.editable].
  final VoidCallback? onEdit;
}

class LedgerCell {
  const LedgerCell(this.text, {this.mono = false, this.color});
  final String text;
  final bool mono;

  /// Couleur explicite (catégorie de dépense) — sinon la couleur de la colonne.
  final Color? color;
}

enum LedgerSort {
  date('Date'),
  name('Nom'),
  amount('Montant');

  const LedgerSort(this.label);
  final String label;
}

/// Le filtre en tête de liste : recherche libre (Opérations, Dépenses)
/// ou sélection de mois (Prélèvements, borné au mois courant).
sealed class LedgerFilter {
  const LedgerFilter();
}

class SearchFilter extends LedgerFilter {
  const SearchFilter({
    required this.query,
    required this.onChanged,
    required this.hint,
  });
  final String query;
  final ValueChanged<String> onChanged;
  final String hint;
}

class MonthFilter extends LedgerFilter {
  const MonthFilter({
    required this.months,
    required this.selected,
    required this.onChanged,
    required this.blockedLabel,
    this.note,
  });

  /// Mois disponibles, du plus ancien au plus récent.
  final List<DateTime> months;
  final DateTime selected;
  final ValueChanged<DateTime> onChanged;

  /// Mois suivant, affiché désactivé : la navigation s'arrête au mois courant.
  final String blockedLabel;
  final String? note;
}

class LedgerConfig {
  const LedgerConfig({
    required this.columns,
    required this.sorts,
    required this.accent,
    required this.sumLabel,
    required this.emptyTitle,
    required this.emptyHint,
    this.nameSortLabel,
    this.editable = false,
  });

  final List<Col> columns;
  final List<LedgerSort> sorts;
  final Color accent;
  final String sumLabel;
  final String emptyTitle;
  final String emptyHint;

  /// « Prestation » pour les opérations, « Libellé » pour les dépenses.
  final String? nameSortLabel;

  /// Ajoute la colonne d'action en fin de tableau. Portée par la config et
  /// non par les lignes : la colonne doit rester en place même filtre vide.
  final bool editable;
}

/// Ossature commune aux écrans Opérations, Dépenses et Prélèvements :
/// filtre + tri, liste groupée par jour avec sous-totaux, colonne d'agrégats.
/// Les trois écrans ne diffèrent que par leur [LedgerConfig] et leur filtre.
class LedgerScreen extends StatelessWidget {
  const LedgerScreen({
    super.key,
    required this.config,
    required this.filter,
    required this.sort,
    required this.onSortChanged,
    required this.items,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final LedgerConfig config;
  final LedgerFilter filter;
  final LedgerSort sort;
  final ValueChanged<LedgerSort> onSortChanged;
  final List<LedgerItem> items;

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  /// Colonnes réellement rendues : la colonne d'action s'ajoute en bout de
  /// ligne sans que chaque configuration ait à la déclarer.
  List<Col> get _columns => [
    ...config.columns,
    if (config.editable) const Col('', width: 44),
  ];

  /// Groupement par jour, du plus récent au plus ancien.
  Map<DateTime, List<LedgerItem>> get _groups {
    final m = <DateTime, List<LedgerItem>>{};
    for (final it in items) {
      final k = DateTime(it.date.year, it.date.month, it.date.day);
      m.putIfAbsent(k, () => []).add(it);
    }
    final keys = m.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in keys) k: m[k]!};
  }

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    final groups = _groups;
    final total = items.fold<int>(0, (s, i) => s + i.amount);

    return AsyncPane(
      loading: loading,
      error: error,
      onRetry: onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _FilterBar(filter: filter)),
              const SizedBox(width: 12),
              Text('TRI', style: x.columnHeader),
              const SizedBox(width: 8),
              SegmentedRow<LedgerSort>(
                values: config.sorts,
                labelOf: (s) => s == LedgerSort.name
                    ? (config.nameSortLabel ?? s.label)
                    : s.label,
                selected: sort,
                onChanged: onSortChanged,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TableHeaderRow(cols: _columns, tinted: true),
                        Expanded(
                          child: groups.isEmpty
                              ? EmptyState(
                                  title: config.emptyTitle,
                                  hint: config.emptyHint,
                                )
                              : ListView(
                                  children: [
                                    for (final g in groups.entries)
                                      ..._group(context, g.key, g.value),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 236,
                  child: _SummaryColumn(
                    config: config,
                    total: total,
                    lineCount: items.length,
                    dayCount: groups.length,
                    maxLine: items.isEmpty
                        ? 0
                        : items
                              .map((i) => i.amount)
                              .reduce((a, b) => a > b ? a : b),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    DateTime day,
    List<LedgerItem> rows,
  ) {
    final x = context.texts;
    return [
      TotalBar(
        height: 30,
        label: Fmt.cap(Fmt.longDate(day)),
        meta: '${rows.length} ${rows.length > 1 ? 'lignes' : 'ligne'}',
        value: Fmt.ar(rows.fold<int>(0, (s, r) => s + r.amount)),
        valueColor: config.accent,
      ),
      for (final r in rows)
        DataRow2(
          cols: _columns,
          // Toute la ligne est cliquable : corriger une faute de frappe ne
          // doit pas demander de viser une icône de 14 pixels.
          onTap: r.onEdit,
          cells: [
            for (var i = 0; i < config.columns.length; i++)
              Text(
                r.cells[i].text,
                style: r.cells[i].mono
                    ? x.monoBody.copyWith(color: r.cells[i].color)
                    : x.body.copyWith(color: r.cells[i].color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (config.editable) RowEditButton(onTap: r.onEdit),
          ],
        ),
    ];
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter});
  final LedgerFilter filter;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return switch (filter) {
      SearchFilter f => _SearchField(filter: f),
      MonthFilter f => Row(
        children: [
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                decoration: BoxDecoration(
                  border: t.border,
                  borderRadius: t.brSmall,
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final m in f.months)
                      _MonthButton(
                        label: _monthLabel(m, f.months),
                        selected:
                            m.year == f.selected.year &&
                            m.month == f.selected.month,
                        onTap: () => f.onChanged(m),
                      ),
                    // Au-delà du mois courant : visible mais inerte.
                    _MonthButton(label: f.blockedLabel, selected: false),
                  ],
                ),
              ),
            ),
          ),
          if (f.note != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                f.note!,
                style: x.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    };
  }

  /// L'année n'apparaît que si la base couvre plusieurs années.
  static String _monthLabel(DateTime m, List<DateTime> all) {
    final multiYear = all.map((d) => d.year).toSet().length > 1;
    final label = Fmt.cap(Fmt.monthShort(m));
    return multiYear ? '$label ${m.year % 100}' : label;
  }
}

/// Champ de recherche à état local : recréer le contrôleur à chaque build
/// ferait sauter le curseur à chaque frappe.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.filter});
  final SearchFilter filter;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final _controller = TextEditingController(text: widget.filter.query);

  @override
  void didUpdateWidget(covariant _SearchField old) {
    super.didUpdateWidget(old);
    // Réinitialisation venue de l'extérieur (changement d'écran, effacement).
    if (widget.filter.query != _controller.text) {
      _controller.text = widget.filter.query;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    // Largeur souhaitée, pas imposée : sur une fenêtre étroite le champ cède
    // du terrain aux boutons de tri plutôt que de les pousser dehors.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: TextField(
        controller: _controller,
        onChanged: widget.filter.onChanged,
        style: context.texts.body,
        decoration: InputDecoration(
          hintText: widget.filter.hint,
          prefixIcon: Icon(Icons.search, size: 16, color: t.faint),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 34,
            minHeight: 20,
          ),
        ),
      ),
    );
  }
}

class _MonthButton extends StatelessWidget {
  const _MonthButton({required this.label, required this.selected, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? t.accentSoft : Colors.transparent,
          border: Border(right: BorderSide(color: t.line)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: onTap == null
                ? t.lineStrong
                : selected
                ? t.accent
                : t.muted,
          ),
        ),
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  const _SummaryColumn({
    required this.config,
    required this.total,
    required this.lineCount,
    required this.dayCount,
    required this.maxLine,
  });

  final LedgerConfig config;
  final int total;
  final int lineCount;
  final int dayCount;
  final int maxLine;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    // Deux cartes de hauteur naturelle : en fenêtre courte ou texte agrandi,
    // elles défilent plutôt que de déborder.
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(config.sumLabel.toUpperCase(), style: x.overline),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.ar(total),
                    style: x.statAmount.copyWith(color: config.accent),
                  ),
                ),
                const SizedBox(height: 6),
                Text('$lineCount lignes · $dayCount jours', style: x.monoFaint),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('AGRÉGATS', style: x.overline),
                const SizedBox(height: 10),
                _agg(
                  context,
                  'Moyenne / ligne',
                  lineCount == 0 ? 0 : total / lineCount,
                ),
                _agg(
                  context,
                  'Moyenne / jour',
                  dayCount == 0 ? 0 : total / dayCount,
                ),
                _agg(context, 'Ligne maximale', maxLine),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _agg(BuildContext context, String k, num v) {
    final x = context.texts;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(child: Text(k, style: x.bodyMuted)),
          Text(Fmt.ar(v), style: x.monoBody),
        ],
      ),
    );
  }
}

/// Configurations prêtes à l'emploi des trois écrans-listes.
class LedgerConfigs {
  static LedgerConfig operations(BuildContext c) => LedgerConfig(
    columns: const [
      Col('Prestation', flex: 3),
      Col('P.U.', numeric: true),
      Col('Qté', numeric: true),
      Col('Total', flex: 2, numeric: true),
      Col('Heure', numeric: true),
    ],
    sorts: LedgerSort.values,
    nameSortLabel: 'Prestation',
    accent: c.tokens.income,
    sumLabel: 'Total entrant filtré',
    emptyTitle: 'Aucun résultat pour cette recherche.',
    emptyHint: 'Essayez un autre terme, ou changez le tri.',
    editable: true,
  );

  static LedgerConfig depenses(BuildContext c) => LedgerConfig(
    columns: const [
      Col('Libellé', flex: 3),
      Col('Catégorie', flex: 2),
      Col('Montant', flex: 2, numeric: true),
      Col('Heure', numeric: true),
    ],
    sorts: LedgerSort.values,
    nameSortLabel: 'Libellé',
    accent: c.tokens.expense,
    sumLabel: 'Total sortant filtré',
    emptyTitle: 'Aucun résultat pour cette recherche.',
    emptyHint: 'Essayez un autre terme, ou changez le tri.',
    editable: true,
  );

  static LedgerConfig prelevements(BuildContext c) => LedgerConfig(
    columns: const [
      Col('Prélèvement', flex: 3),
      Col('Montant', flex: 2, numeric: true),
      Col('Heure', numeric: true),
    ],
    sorts: const [LedgerSort.date, LedgerSort.amount],
    accent: c.tokens.drawing,
    sumLabel: 'Total prélevé',
    emptyTitle: 'Aucun prélèvement ce mois-ci.',
    emptyHint: 'Les données arrivent par import de sauvegarde.',
    editable: true,
  );
}

/// Construit les cellules d'une dépense, catégorie colorée comprise.
LedgerItem depenseItem(
  BuildContext context, {
  required DateTime date,
  required String libelle,
  required String categorie,
  required int montant,
  VoidCallback? onEdit,
}) => LedgerItem(
  date: date,
  amount: montant,
  onEdit: onEdit,
  cells: [
    LedgerCell(libelle),
    LedgerCell(categorie, color: categoryColor(context, categorie)),
    LedgerCell(Fmt.num(montant), mono: true),
    LedgerCell(Fmt.hour(date), mono: true, color: context.tokens.faint),
  ],
);

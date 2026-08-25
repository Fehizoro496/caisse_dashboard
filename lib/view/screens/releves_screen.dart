import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
import 'package:flutter/material.dart';

/// Échelle du graphique de consommation.
enum ReleveSpan {
  last10('10 derniers'),
  all('Tous les relevés'),
  byMonth('Par mois');

  const ReleveSpan(this.label);
  final String label;
}

/// Relevés électricité : consommation calculée par différence entre relevés
/// consécutifs, jamais stockée. Liste dépliable avec le détail du partage.
class RelevesScreen extends StatefulWidget {
  const RelevesScreen({
    super.key,
    required this.releves,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onEdit,
  });

  /// Ordre indifférent : l'écran trie lui-même.
  final List<ReleveElectricite> releves;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  /// Correction d'un relevé. Absent = tableau en lecture seule.
  final void Function(ReleveElectricite)? onEdit;

  @override
  State<RelevesScreen> createState() => _RelevesScreenState();
}

class _RelevesScreenState extends State<RelevesScreen> {
  ReleveSpan _span = ReleveSpan.byMonth;
  String? _open;

  List<ReleveElectricite> get _asc =>
      [...widget.releves]..sort((a, b) => a.date.compareTo(b.date));

  /// Δ entre relevés consécutifs — la consommation réelle de la période.
  List<({DateTime date, double general, double sous})> get _deltas {
    final r = _asc;
    return [
      for (var i = 1; i < r.length; i++)
        (
          date: r[i].date,
          general: r[i].compteur - r[i - 1].compteur,
          sous: r[i].sousCompteur - r[i - 1].sousCompteur,
        ),
    ];
  }

  List<BarGroup> get _bars {
    final d = _deltas;
    if (d.isEmpty) return const [];

    if (_span == ReleveSpan.byMonth) {
      final m = <String, ({DateTime date, double g, double s})>{};
      for (final x in d) {
        final k = '${x.date.year}-${x.date.month}';
        final cur = m[k];
        m[k] = (
          date: DateTime(x.date.year, x.date.month),
          g: (cur?.g ?? 0) + x.general,
          s: (cur?.s ?? 0) + x.sous,
        );
      }
      return [
        for (final e in m.values)
          BarGroup(
            label: Fmt.cap(Fmt.monthShort(e.date)),
            primary: e.g,
            secondary: e.s,
            topLabel: Fmt.dec(e.g),
            tooltipOf: Fmt.kwh,
          ),
      ];
    }

    final take = _span == ReleveSpan.last10 ? 10 : d.length;
    final slice = d.sublist(d.length - take.clamp(1, d.length));
    // Une étiquette sur n pour ne pas empiler les dates.
    final every = slice.length > 24
        ? 4
        : slice.length > 14
        ? 3
        : 1;
    return [
      for (var i = 0; i < slice.length; i++)
        BarGroup(
          label: (slice.length - 1 - i) % every == 0
              ? Fmt.shortDate(slice[i].date)
              : '',
          primary: slice[i].general,
          secondary: slice[i].sous,
          topLabel: '',
          tooltipOf: Fmt.kwh,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final desc = [...widget.releves]..sort((a, b) => b.date.compareTo(a.date));
    final asc = _asc;

    final cols = [
      const Col('Date du relevé', flex: 3),
      const Col('Général (kWh)', flex: 2, numeric: true),
      const Col('Sous-compteur', flex: 2, numeric: true),
      const Col('Conso période', flex: 2, numeric: true),
      const Col('', width: 30),
      if (widget.onEdit != null) const Col('', width: 44),
    ];

    return AsyncPane(
      loading: widget.loading,
      error: widget.error,
      onRetry: widget.onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ChartHeader(
                  title: 'Consommation par période',
                  subtitle: _span == ReleveSpan.byMonth
                      ? 'Cumul par mois · différence entre relevés · kWh'
                      : 'Différence entre deux relevés consécutifs · kWh',
                  controls: SegmentedRow<ReleveSpan>(
                    values: ReleveSpan.values,
                    labelOf: (s) => s.label,
                    selected: _span,
                    onChanged: (s) => setState(() => _span = s),
                  ),
                  legends: [
                    _legend(context, t.electric, 'Compteur général'),
                    _legend(context, t.drawing, 'Sous-compteur'),
                  ],
                ),
                const SizedBox(height: 16),
                GroupedBarChart(
                  groups: _bars,
                  primaryColor: t.electric,
                  secondaryColor: t.drawing,
                  showTopLabels: _span == ReleveSpan.byMonth,
                  height: 176,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TableHeaderRow(cols: cols, tinted: true),
                  Expanded(
                    child: desc.isEmpty
                        ? const EmptyState(
                            title: 'Aucun relevé en base.',
                            hint:
                                'Les relevés arrivent par import de sauvegarde.',
                          )
                        : ListView.builder(
                            itemCount: desc.length,
                            itemBuilder: (context, i) {
                              final r = desc[i];
                              final pos = asc.indexWhere((e) => e.id == r.id);
                              final prev = pos > 0 ? asc[pos - 1] : null;
                              final dG = prev == null
                                  ? null
                                  : r.compteur - prev.compteur;
                              final dS = prev == null
                                  ? null
                                  : r.sousCompteur - prev.sousCompteur;
                              final days = prev == null
                                  ? null
                                  : r.date.difference(prev.date).inDays;
                              final open = _open == r.id;

                              return Column(
                                children: [
                                  DataRow2(
                                    cols: cols,
                                    background: open ? t.surfaceAlt : null,
                                    onTap: () => setState(
                                      () => _open = open ? null : r.id,
                                    ),
                                    cells: [
                                      Text(
                                        Fmt.cap(Fmt.longDate(r.date)),
                                        style: x.body,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        Fmt.dec(r.compteur),
                                        style: x.monoBody,
                                      ),
                                      Text(
                                        Fmt.dec(r.sousCompteur),
                                        style: x.monoBody.copyWith(
                                          color: t.drawing,
                                        ),
                                      ),
                                      Text(
                                        dG == null ? '—' : Fmt.kwh(dG),
                                        style: x.monoMuted,
                                      ),
                                      Icon(
                                        open ? Icons.remove : Icons.add,
                                        size: 13,
                                        color: t.faint,
                                      ),
                                      // Le clic sur la ligne déplie déjà le
                                      // détail : la correction passe par le
                                      // crayon, pas par la ligne entière.
                                      if (widget.onEdit != null)
                                        RowEditButton(
                                          onTap: () => widget.onEdit!(r),
                                        ),
                                    ],
                                  ),
                                  if (open)
                                    _Detail(
                                      items: prev == null
                                          ? const [
                                              (
                                                'Premier relevé',
                                                'aucune référence',
                                                null,
                                              ),
                                            ]
                                          : [
                                              (
                                                'Δ compteur général',
                                                Fmt.kwh(dG!),
                                                t.electric,
                                              ),
                                              (
                                                'Δ sous-compteur',
                                                Fmt.kwh(dS!),
                                                t.drawing,
                                              ),
                                              (
                                                'Reste (occupant 2)',
                                                Fmt.kwh(dG - dS),
                                                null,
                                              ),
                                              (
                                                'Moyenne',
                                                '${(dG / (days == null || days == 0 ? 1 : days)).toStringAsFixed(1)} kWh/j · $days j',
                                                null,
                                              ),
                                            ],
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context, Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      KindDot(c, size: 8),
      const SizedBox(width: 6),
      Text(label, style: context.texts.caption),
    ],
  );
}

/// En-tête de carte-graphique : titre à gauche, contrôles et légendes à droite.
///
/// Sur une fenêtre étroite, tout tenir sur une ligne réduisait la largeur du
/// titre à zéro — le texte s'enroulait alors caractère par caractère et faisait
/// exploser la hauteur de la carte. Sous le seuil, on empile.
class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.title,
    required this.subtitle,
    required this.controls,
    required this.legends,
  });

  final String title;
  final String subtitle;
  final Widget controls;
  final List<Widget> legends;

  static const _minTitleWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: x.cardTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: x.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    // Le sélecteur d'échelle ne se compresse pas : passé une certaine taille
    // de texte il est plus large que la carte. On le laisse alors défiler
    // plutôt que déborder — cas dégradé, jamais atteint en réglages normaux.
    final aside = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          controls,
          for (final l in legends) ...[const SizedBox(width: 14), l],
        ],
      ),
    );

    final scale = MediaQuery.textScalerOf(context).scale(1);

    return LayoutBuilder(
      builder: (context, box) {
        // Sous le seuil, titre au-dessus et contrôles en dessous : le titre
        // garde une largeur lisible au lieu d'être réduit à néant.
        if (box.maxWidth < _minTitleWidth * 2.4 * scale) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleBlock, const SizedBox(height: 10), aside],
          );
        }
        return Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: 16),
            Flexible(child: aside),
          ],
        );
      },
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.items});
  final List<(String, String, Color?)> items;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final i in items)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(i.$1.toUpperCase(), style: x.columnHeader),
                  const SizedBox(height: 5),
                  Text(
                    i.$2,
                    style: x.monoBody.copyWith(
                      fontSize: 15,
                      color: i.$3 ?? t.text,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

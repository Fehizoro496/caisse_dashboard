import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';

/// Le solde net — l'information la plus utile, absente de l'ancienne app.
/// Grand chiffre mono, formule rappelée, comparaison à la période précédente.
class SoldeNetCard extends StatelessWidget {
  const SoldeNetCard({
    super.key,
    required this.solde,
    required this.periodWord,
    this.deltaPercent,
  });

  final int solde;
  final String periodWord;
  final int? deltaPercent;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final negative = solde < 0;
    final d = deltaPercent;

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Pas de Spacer : la carte doit avoir une hauteur intrinsèque juste,
        // c'est elle qui dimensionne la bande (voir DashboardScreen).
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SOLDE NET · ${periodWord.toUpperCase()}',
            style: x.overline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                    '${negative ? '−' : ''}${Fmt.num(solde.abs())}',
                    style: x.heroAmount.copyWith(
                      color: negative ? t.expense : t.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('Ar', style: x.monoMuted.copyWith(fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          // Une seule ligne, toujours : un retour à la ligne rallongerait
          // la carte, donc toute la bande.
          Row(
            children: [
              Flexible(
                child: Text(
                  'entrant − sortant − prélèv.',
                  style: x.monoFaint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (d != null) ...[
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    '${d >= 0 ? '+' : ''}$d % vs préc.',
                    style: x.monoFaint.copyWith(
                      color: d >= 0 ? t.income : t.expense,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Total cliquable du jour : Entrant / Sortant / Prélèvement.
/// Le clic ouvre l'écran de détail correspondant, comme dans l'app actuelle.
class TotalCard extends StatefulWidget {
  const TotalCard({
    super.key,
    required this.label,
    required this.amount,
    required this.sub,
    required this.color,
    this.onTap,
  });

  final String label;
  final int amount;
  final String sub;
  final Color color;
  final VoidCallback? onTap;

  @override
  State<TotalCard> createState() => _TotalCardState();
}

class _TotalCardState extends State<TotalCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border.all(color: _hover ? widget.color : t.line),
            borderRadius: t.br,
            boxShadow: t.shadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  KindDot(widget.color),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      widget.label.toUpperCase(),
                      style: x.overline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(Fmt.num(widget.amount), style: x.statAmount),
              ),
              const SizedBox(height: 12),
              Text(
                widget.sub,
                style: x.monoFaint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une barre du graphique groupé.
class BarGroup {
  const BarGroup({
    required this.label,
    required this.primary,
    required this.secondary,
    this.highlighted = false,
    this.topLabel,
    this.tooltipOf,
  });

  final String label;
  final num primary;
  final num secondary;
  final bool highlighted;
  final String? topLabel;

  /// Formatage de l'infobulle. Ar par défaut ; les relevés passent en kWh.
  final String Function(num)? tooltipOf;
}

/// Graphique à barres groupées : Entrants vs Prélèvements (dashboard),
/// Δ compteur vs Δ sous-compteur (relevés). Une seule échelle, K/M en axe.
class GroupedBarChart extends StatelessWidget {
  const GroupedBarChart({
    super.key,
    required this.groups,
    required this.primaryColor,
    required this.secondaryColor,
    this.height = 168,
    this.showTopLabels = true,
  });

  final List<BarGroup> groups;
  final Color primaryColor;
  final Color secondaryColor;
  final double height;
  final bool showTopLabels;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    if (groups.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(child: Text('Aucune donnée', style: x.caption)),
      );
    }
    final max = groups
        .map((g) => g.primary > g.secondary ? g.primary : g.secondary)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final safeMax = max <= 0 ? 1.0 : max;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final g in groups)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (showTopLabels)
                      Text(
                        g.topLabel ?? Fmt.compact(g.primary),
                        style: x.monoFaint,
                        maxLines: 1,
                      ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _Bar(
                            ratio: g.primary / safeMax,
                            color: primaryColor,
                            tooltip: (g.tooltipOf ?? Fmt.ar)(g.primary),
                          ),
                          const SizedBox(width: 3),
                          _Bar(
                            ratio: g.secondary / safeMax,
                            color: secondaryColor,
                            tooltip: (g.tooltipOf ?? Fmt.ar)(g.secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      g.label,
                      style: x.caption.copyWith(
                        fontWeight: g.highlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: g.highlighted
                            ? context.tokens.text
                            : context.tokens.faint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.ratio, required this.color, required this.tooltip});
  final double ratio;
  final Color color;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: FractionallySizedBox(
        heightFactor: ratio.isFinite ? ratio.clamp(0.01, 1.0) : 0.01,
        child: Container(
          width: 16,
          constraints: const BoxConstraints(minHeight: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ),
      ),
    );
  }
}

/// Répartition des dépenses par catégorie : barre proportionnelle + légende.
class CategoryBreakdown extends StatelessWidget {
  const CategoryBreakdown({
    super.key,
    required this.entries,
    required this.colorOf,
  });

  /// Catégorie → montant, déjà trié décroissant.
  final List<(String, int)> entries;
  final Color Function(String) colorOf;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    if (entries.isEmpty) {
      return const EmptyState(title: 'Rien à répartir.');
    }
    final total = entries.fold<int>(0, (s, e) => s + e.$2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 9,
            child: Row(
              children: [
                for (final e in entries)
                  Expanded(
                    flex: e.$2 <= 0 ? 1 : e.$2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 2),
                      child: ColoredBox(color: colorOf(e.$1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: Row(
              children: [
                KindDot(colorOf(e.$1)),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    e.$1,
                    style: x.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  total == 0 ? '—' : '${(e.$2 / total * 100).round()} %',
                  style: x.monoFaint,
                ),
                const SizedBox(width: 10),
                Text(Fmt.num(e.$2), style: x.monoBody),
              ],
            ),
          ),
      ],
    );
  }
}

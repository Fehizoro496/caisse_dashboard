import 'dart:math' as math;

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
    this.formula = 'entrant − sortant − prélèv.',
  });

  final int solde;
  final String periodWord;
  final int? deltaPercent;

  /// Rappel du calcul. Gagne un terme quand les charges du mois y entrent :
  /// un solde qui change sans que la formule bouge passe pour une erreur.
  final String formula;

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
                  formula,
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
    this.muted = false,
  });

  final String label;
  final int amount;
  final String sub;
  final Color color;
  final VoidCallback? onTap;

  /// Montant affiché mais hors du solde — les charges quand l'utilisateur les
  /// exclut. Le chiffre pâlit sans disparaître.
  final bool muted;

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
                  KindDot(widget.muted ? t.lineStrong : widget.color),
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
                child: Text(
                  Fmt.num(widget.amount),
                  style: widget.muted
                      ? x.statAmount.copyWith(color: t.faint)
                      : x.statAmount,
                ),
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
    this.pending = false,
  });

  final String label;
  final num primary;
  final num secondary;
  final bool highlighted;
  final String? topLabel;

  /// Formatage de l'infobulle. Ar par défaut ; les relevés passent en kWh.
  final String Function(num)? tooltipOf;

  /// Période à venir, sans données : [TrendLineChart] garde son étiquette sur
  /// l'axe mais n'y fait passer aucune courbe.
  final bool pending;
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

/// Courbes d'évolution sur les mêmes [BarGroup] que [GroupedBarChart] :
/// Entrants vs Prélèvements des cadrages Semaine et Mois. Une seule échelle,
/// K/M en axe ; le survol donne les deux valeurs de la période pointée.
class TrendLineChart extends StatefulWidget {
  const TrendLineChart({
    super.key,
    required this.groups,
    required this.primaryColor,
    required this.secondaryColor,
    required this.primaryLabel,
    required this.secondaryLabel,
  });

  final List<BarGroup> groups;
  final Color primaryColor;
  final Color secondaryColor;
  final String primaryLabel;
  final String secondaryLabel;

  @override
  State<TrendLineChart> createState() => _TrendLineChartState();
}

class _TrendLineChartState extends State<TrendLineChart> {
  int? _hover;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final groups = widget.groups;
    if (groups.isEmpty) {
      return Center(child: Text('Aucune donnée', style: x.caption));
    }
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final hover =
        _hover != null && _hover! < groups.length && !groups[_hover!].pending
        ? _hover
        : null;

    return LayoutBuilder(
      builder: (context, box) {
        final plot = _TrendPainter.plotOf(box.biggest, scale);
        return MouseRegion(
          onHover: (e) {
            final i = _TrendPainter.indexAt(
              e.localPosition.dx,
              plot,
              groups.length,
            );
            if (i != _hover) setState(() => _hover = i);
          },
          onExit: (_) => setState(() => _hover = null),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrendPainter(
                    groups: groups,
                    primaryColor: widget.primaryColor,
                    secondaryColor: widget.secondaryColor,
                    hover: hover,
                    tokens: t,
                    texts: x,
                    scale: scale,
                    textScaler: MediaQuery.textScalerOf(context),
                    baseStyle: DefaultTextStyle.of(context).style,
                  ),
                ),
              ),
              if (hover != null)
                _tooltip(context, box.biggest, plot, groups[hover], hover),
            ],
          ),
        );
      },
    );
  }

  Widget _tooltip(
    BuildContext context,
    Size size,
    Rect plot,
    BarGroup g,
    int i,
  ) {
    final t = context.tokens;
    final px = _TrendPainter.xOf(i, plot, widget.groups.length);
    final format = g.tooltipOf ?? Fmt.ar;
    final ink = TextStyle(
      fontFamily: AppFonts.sans,
      fontSize: 11.5,
      color: t.surface,
    );
    Widget line(Color color, String label, num value) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          KindDot(color),
          const SizedBox(width: 6),
          Text('$label  ', style: ink),
          Text(
            format(value),
            style: ink.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    // Du côté où il reste de la place : jamais sur le point qu'il décrit.
    final onRight = px < size.width / 2;
    return Positioned(
      top: 0,
      left: onRight ? px + 12 : null,
      right: onRight ? null : size.width - px + 12,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: t.text,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(g.label, style: ink.copyWith(fontWeight: FontWeight.w600)),
              line(widget.primaryColor, widget.primaryLabel, g.primary),
              line(widget.secondaryColor, widget.secondaryLabel, g.secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.groups,
    required this.primaryColor,
    required this.secondaryColor,
    required this.hover,
    required this.tokens,
    required this.texts,
    required this.scale,
    required this.textScaler,
    required this.baseStyle,
  });

  final List<BarGroup> groups;
  final Color primaryColor;
  final Color secondaryColor;
  final int? hover;
  final AppTokens tokens;
  final AppTextStyles texts;
  final double scale;
  final TextScaler textScaler;

  /// Style hérité, celui que reçoit tout `Text` : sans lui, l'axe serait
  /// dessiné dans une autre police que le reste de la carte.
  final TextStyle baseStyle;

  /// Zone de tracé : la gouttière de gauche porte l'échelle, le bas les
  /// périodes. Partagée avec le survol, qui doit viser les mêmes abscisses.
  static Rect plotOf(Size size, double scale) =>
      Rect.fromLTRB(44 * scale, 8, size.width - 28, size.height - 22 * scale);

  static double xOf(int i, Rect plot, int n) =>
      n == 1 ? plot.center.dx : plot.left + plot.width * i / (n - 1);

  static int indexAt(double dx, Rect plot, int n) => n == 1
      ? 0
      : ((dx - plot.left) / plot.width * (n - 1)).round().clamp(0, n - 1);

  /// Plafond « rond » de l'échelle : 1, 2, 2,5 ou 5 × une puissance de dix.
  static double _niceMax(double max) {
    if (max <= 0) return 1;
    final pow10 = math.pow(10, (math.log(max) / math.ln10).floor()).toDouble();
    for (final m in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * pow10 >= max) return m * pow10;
    }
    return 10 * pow10;
  }

  /// Courbe lisse passant par tous les points. Interpolation cubique
  /// *monotone* : entre deux périodes, la courbe ne dépasse jamais leurs
  /// valeurs — une spline ordinaire creuserait sous zéro après une chute, ou
  /// inventerait un sommet qui n'existe pas.
  static Path _smooth(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p.first.dx, p.first.dy);
    if (n < 3) {
      for (final q in p.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      return path;
    }
    // Pentes des segments, puis tangente en chaque point.
    final slope = [
      for (var i = 0; i < n - 1; i++)
        (p[i + 1].dy - p[i].dy) / (p[i + 1].dx - p[i].dx),
    ];
    final tangent = List<double>.filled(n, 0);
    tangent[0] = slope.first;
    tangent[n - 1] = slope.last;
    for (var i = 1; i < n - 1; i++) {
      // Un sommet ou un creux reste plat : c'est ce qui interdit le
      // dépassement.
      tangent[i] = slope[i - 1] * slope[i] <= 0
          ? 0
          : (slope[i - 1] + slope[i]) / 2;
    }
    for (var i = 0; i < n - 1; i++) {
      if (slope[i] == 0) {
        tangent[i] = 0;
        tangent[i + 1] = 0;
        continue;
      }
      final a = tangent[i] / slope[i];
      final b = tangent[i + 1] / slope[i];
      final h = a * a + b * b;
      if (h > 9) {
        final k = 3 / math.sqrt(h);
        tangent[i] = k * a * slope[i];
        tangent[i + 1] = k * b * slope[i];
      }
    }
    for (var i = 0; i < n - 1; i++) {
      final dx = (p[i + 1].dx - p[i].dx) / 3;
      path.cubicTo(
        p[i].dx + dx,
        p[i].dy + tangent[i] * dx,
        p[i + 1].dx - dx,
        p[i + 1].dy - tangent[i + 1] * dx,
        p[i + 1].dx,
        p[i + 1].dy,
      );
    }
    return path;
  }

  TextPainter _text(String s, TextStyle style) => TextPainter(
    text: TextSpan(text: s, style: baseStyle.merge(style)),
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final plot = plotOf(size, scale);
    if (plot.width <= 0 || plot.height <= 0) return;
    final n = groups.length;
    final top = _niceMax(
      groups
          .map((g) => math.max(g.primary, g.secondary))
          .reduce(math.max)
          .toDouble(),
    );
    double yOf(num v) =>
        plot.bottom - plot.height * (v / top).clamp(0.0, 1.0).toDouble();

    // Grille discrète : trois repères suffisent à lire un ordre de grandeur.
    final grid = Paint()
      ..color = tokens.line
      ..strokeWidth = 1;
    for (final f in const [0.0, .5, 1.0]) {
      final y = yOf(top * f);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final label = _text(Fmt.compact(top * f), texts.monoFaint);
      label.paint(
        canvas,
        Offset(plot.left - 10 - label.width, y - label.height / 2),
      );
      label.dispose();
    }

    // Périodes : une sur deux, ou trois, quand elles se toucheraient.
    final labels = [
      for (final g in groups)
        _text(
          g.label,
          texts.caption.copyWith(
            fontWeight: g.highlighted ? FontWeight.w600 : FontWeight.w400,
            color: g.highlighted ? tokens.text : tokens.faint,
          ),
        ),
    ];
    final widest = labels.map((l) => l.width).reduce(math.max);
    final every = n == 1
        ? 1
        : math.max(1, ((widest + 10) / (plot.width / (n - 1))).ceil());
    for (var i = 0; i < n; i++) {
      // On compte depuis la fin : la période en cours garde son étiquette.
      if ((n - 1 - i) % every == 0) {
        labels[i].paint(
          canvas,
          Offset(xOf(i, plot, n) - labels[i].width / 2, plot.bottom + 7),
        );
      }
      labels[i].dispose();
    }

    if (hover != null) {
      final x = xOf(hover!, plot, n);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = tokens.lineStrong
          ..strokeWidth = 1,
      );
    }

    List<(int, Offset)> pointsOf(num Function(BarGroup) valueOf) => [
      for (var i = 0; i < n; i++)
        if (!groups[i].pending)
          (i, Offset(xOf(i, plot, n), yOf(valueOf(groups[i])))),
    ];

    // Dégradé sous la courbe : la couleur de la série, qui s'éteint vers
    // l'axe. Assez léger pour que la grille et l'autre série restent lisibles
    // au travers.
    void area(List<(int, Offset)> points, Color color) {
      if (points.length < 2) return;
      final path = _smooth([for (final (_, p) in points) p])
        ..lineTo(points.last.$2.dx, plot.bottom)
        ..lineTo(points.first.$2.dx, plot.bottom)
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: .24),
                  color.withValues(alpha: 0),
                ],
              ).createShader(
                // Du sommet de *cette* série jusqu'à l'axe : calé sur le haut du
                // tracé, le dégradé d'une série basse serait presque invisible.
                Rect.fromLTRB(
                  plot.left,
                  points.map((e) => e.$2.dy).reduce(math.min),
                  plot.right,
                  plot.bottom,
                ),
              ),
      );
    }

    void series(List<(int, Offset)> points, Color color) {
      if (points.isEmpty) return;
      if (points.length > 1) {
        canvas.drawPath(
          _smooth([for (final (_, p) in points) p]),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = color,
        );
      }
      for (final (i, p) in points) {
        final on = i == hover;
        // Liseré couleur de fond : deux points superposés restent lisibles.
        canvas.drawCircle(p, on ? 7 : 6, Paint()..color = tokens.surface);
        canvas.drawCircle(p, on ? 5 : 4, Paint()..color = color);
      }
    }

    // Les deux dégradés d'abord, pour qu'aucun ne voile une courbe ; puis
    // les entrants par-dessus : c'est la série qu'on vient lire.
    final primary = pointsOf((g) => g.primary);
    final secondary = pointsOf((g) => g.secondary);
    area(primary, primaryColor);
    area(secondary, secondaryColor);
    series(secondary, secondaryColor);
    series(primary, primaryColor);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) =>
      old.hover != hover ||
      old.groups != groups ||
      old.tokens != tokens ||
      old.scale != scale ||
      old.primaryColor != primaryColor ||
      old.secondaryColor != secondaryColor;
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
                // Sur une colonne étroite à texte agrandi, le pourcentage
                // s'efface avant le montant : c'est lui le moins informatif.
                Flexible(
                  child: Text(
                    total == 0 ? '—' : '${(e.$2 / total * 100).round()} %',
                    style: x.monoFaint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

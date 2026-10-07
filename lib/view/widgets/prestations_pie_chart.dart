import 'dart:math' as math;

import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ce que mesurent les parts : le chiffre d'affaires ou le nombre d'unités
/// vendues. Une prestation chère et rare pèse lourd dans l'un, peu dans l'autre.
enum PrestationsMetric {
  montant('Montant'),
  quantite('Quantité');

  const PrestationsMetric(this.label);
  final String label;
}

/// Ce que le tableau des prestations et leur anneau ont en commun : la mesure
/// affichée et la part survolée. Les deux cartes sont voisines, pas imbriquées —
/// d'où cet état partagé plutôt qu'un `setState` local.
class PrestationsView extends ChangeNotifier {
  PrestationsMetric _metric = PrestationsMetric.montant;
  int? _active;
  bool _activeFromChart = false;

  PrestationsMetric get metric => _metric;

  /// Rang de la part survolée, dans l'ordre commun à l'anneau et au tableau.
  int? get active => _active;

  /// Le survol vient de l'anneau : le tableau doit défiler jusqu'à la ligne.
  /// L'inverse ne défile pas — la ligne fuirait sous le pointeur.
  bool get activeFromChart => _activeFromChart;

  set metric(PrestationsMetric m) {
    if (m == _metric) return;
    _metric = m;
    _active = null;
    notifyListeners();
  }

  void hover(int? i, {bool fromChart = false}) {
    if (i == _active) return;
    _active = i;
    _activeFromChart = fromChart;
    notifyListeners();
  }
}

/// Porte un [PrestationsView] pour le tableau et l'anneau placés dessous.
class PrestationsScope extends StatefulWidget {
  const PrestationsScope({super.key, required this.child});

  final Widget child;

  static PrestationsView of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_PrestationsInherited>()!
      .notifier!;

  @override
  State<PrestationsScope> createState() => _PrestationsScopeState();
}

class _PrestationsScopeState extends State<PrestationsScope> {
  final _view = PrestationsView();

  @override
  void dispose() {
    _view.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _PrestationsInherited(notifier: _view, child: widget.child);
}

class _PrestationsInherited extends InheritedNotifier<PrestationsView> {
  const _PrestationsInherited({required super.notifier, required super.child});
}

/// Une part de l'anneau : une prestation, toutes ses lignes confondues.
typedef _Slice = ({String label, int value, Color color});

/// Une ligne du tableau. [slice] est le rang de sa part dans l'anneau, ou
/// `null` quand sa prestation n'en a pas — valeur nulle ou négative pour la
/// mesure en cours ; [color] suit.
typedef _Line = ({OperationRow row, int value, Color? color, int? slice});

typedef _Model = ({List<_Slice> slices, List<_Line> lines, int total});

/// Ce que le tableau et l'anneau montrent des mêmes opérations.
///
/// Les parts regroupent les lignes par prestation : en Semaine et en Mois le
/// contrôleur l'a déjà fait, au Jour une même prestation revient d'heure en
/// heure et ses lignes partagent alors une part et une couleur.
///
/// [byLine] garde les lignes dans l'ordre reçu (le fil de la journée) ;
/// sinon elles suivent l'ordre des parts.
_Model _modelOf(
  BuildContext context,
  List<OperationRow> operations,
  PrestationsMetric metric, {
  bool byLine = false,
}) {
  final t = context.tokens;
  // Les couleurs suivent la prestation, pas son rang : elles sont attribuées
  // une fois, par montant décroissant, et ne bougent pas quand la bascule
  // réordonne les parts. L'ordre des jetons garde deux voisines distinctes,
  // y compris pour un œil daltonien — ne pas le réarranger au goût.
  final palette = [
    t.income,
    t.drawing,
    t.expense,
    t.accent,
    t.electric,
    t.charge,
  ];
  final dark = Theme.of(context).brightness == Brightness.dark;
  // Au-delà des jetons, des teintes réparties par l'angle d'or : toujours
  // les mêmes d'un affichage à l'autre, jamais deux voisines proches.
  Color colorOf(int i) => i < palette.length
      ? palette[i]
      : HSLColor.fromAHSL(
          1,
          (i * 137.5) % 360,
          .42,
          dark ? .68 : .54,
        ).toColor();

  int valueOf(OperationRow o) =>
      metric == PrestationsMetric.montant ? o.total : o.quantite;
  String keyOf(OperationRow o) => o.nom.trim().toLowerCase();

  final groups = <String, ({String name, int total, int value, int first})>{};
  for (final (i, o) in operations.indexed) {
    final cur = groups[keyOf(o)];
    groups[keyOf(o)] = (
      name: cur?.name ?? _nameOf(o),
      total: (cur?.total ?? 0) + o.total,
      value: (cur?.value ?? 0) + valueOf(o),
      first: cur?.first ?? i,
    );
  }
  // `sort` n'est pas stable : l'ordre d'arrivée départage les égalités.
  final byAmount = groups.entries.toList()
    ..sort((a, b) {
      final c = b.value.total.compareTo(a.value.total);
      return c != 0 ? c : a.value.first.compareTo(b.value.first);
    });
  final rank = {for (final (i, e) in byAmount.indexed) e.key: i};
  final inRing = byAmount.where((e) => e.value.value > 0).toList()
    ..sort((a, b) {
      final c = b.value.value.compareTo(a.value.value);
      return c != 0 ? c : rank[a.key]!.compareTo(rank[b.key]!);
    });
  final sliceOf = {for (final (i, e) in inRing.indexed) e.key: i};

  final lines = [
    for (final (i, o) in operations.indexed)
      (
        i: i,
        line: (
          row: o,
          value: valueOf(o),
          color: sliceOf.containsKey(keyOf(o))
              ? colorOf(rank[keyOf(o)]!)
              : null,
          slice: sliceOf[keyOf(o)],
        ),
      ),
  ];
  if (!byLine) {
    lines.sort((a, b) {
      final c = (a.line.slice ?? lines.length).compareTo(
        b.line.slice ?? lines.length,
      );
      return c != 0 ? c : a.i.compareTo(b.i);
    });
  }
  return (
    slices: [
      for (final e in inRing)
        (
          label: e.value.name,
          value: e.value.value,
          color: colorOf(rank[e.key]!),
        ),
    ],
    lines: [for (final l in lines) l.line],
    total: inRing.fold<int>(0, (s, e) => s + e.value.value),
  );
}

String _nameOf(OperationRow o) => o.nom.isEmpty ? 'Sans libellé' : o.nom;

String _percent(int amount, int total) {
  final p = amount / total * 100;
  return '${p >= 10 ? p.round() : p.toStringAsFixed(1).replaceAll('.', ',')} %';
}

/// Tableau des prestations : agrégées en Semaine et en Mois, ligne à ligne
/// au Jour ([byLine]). Il sert de
/// légende à [PrestationsPieChart] — pastille de couleur et colonne « Part » —
/// au lieu qu'une seconde liste répète les mêmes lignes à côté de l'anneau.
/// À placer, comme lui, sous un [PrestationsScope].
class PrestationsPanel extends StatefulWidget {
  const PrestationsPanel({
    super.key,
    required this.operations,
    required this.totalEntrant,
    this.byLine = false,
  });

  final List<OperationRow> operations;
  final int totalEntrant;

  /// Vue Jour : une ligne par opération, dans l'ordre de la journée, et
  /// l'heure à la place du nombre de lignes.
  final bool byLine;

  @override
  State<PrestationsPanel> createState() => _PrestationsPanelState();
}

class _PrestationsPanelState extends State<PrestationsPanel> {
  final _scroll = ScrollController();
  int? _lastActive;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(int i) {
    if (!mounted || !_scroll.hasClients) return;
    final pos = _scroll.position;
    final rowHeight = context.tokens.rowHeight;
    _scroll.animateTo(
      (i * rowHeight - (pos.viewportDimension - rowHeight) / 2).clamp(
        0.0,
        pos.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final view = PrestationsScope.of(context);
    final model = _modelOf(
      context,
      widget.operations,
      view.metric,
      byLine: widget.byLine,
    );
    final lines = model.lines;
    final total = model.total;
    final active = view.active != null && view.active! < model.slices.length
        ? view.active
        : null;
    if (active != _lastActive && active != null && view.activeFromChart) {
      // Au Jour, plusieurs lignes partagent la part : on va à la première.
      final row = lines.indexWhere((l) => l.slice == active);
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(row));
    }
    _lastActive = active;
    final byAmount = view.metric == PrestationsMetric.montant;
    final scale = MediaQuery.textScalerOf(context).scale(1);

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(
            title: widget.byLine
                ? 'Opérations du jour'
                : 'Prestations agrégées',
            meta: '${lines.length} ${widget.byLine ? 'lignes' : 'prestations'}',
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final cols = [
                  const Col('Prestation', flex: 3),
                  const Col('P.U.', flex: 1, numeric: true),
                  const Col('Qté', flex: 1, numeric: true),
                  const Col('Total', flex: 2, numeric: true),
                  const Col('Part', flex: 1, numeric: true),
                  // Première colonne sacrifiée à l'étroit : la moins lue.
                  if (box.maxWidth >= 440 * scale)
                    Col(
                      widget.byLine ? 'Heure' : 'Lignes',
                      flex: 1,
                      numeric: true,
                    ),
                ];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TableHeaderRow(cols: cols),
                    Expanded(
                      child: lines.isEmpty
                          ? const EmptyState(
                              title: 'Aucune opération sur cette période.',
                            )
                          : ListView.builder(
                              controller: _scroll,
                              itemCount: lines.length,
                              itemBuilder: (context, i) {
                                final e = lines[i];
                                final o = e.row;
                                return MouseRegion(
                                  onEnter: (_) => view.hover(e.slice),
                                  onExit: (_) => view.hover(null),
                                  child: DataRow2(
                                    cols: cols,
                                    background:
                                        active != null && e.slice == active
                                        ? t.surfaceAlt
                                        : null,
                                    cells: [
                                      Row(
                                        children: [
                                          KindDot(
                                            e.color ?? t.lineStrong,
                                            size: 8,
                                          ),
                                          const SizedBox(width: 9),
                                          Expanded(
                                            child: Text(
                                              _nameOf(o),
                                              style: x.body,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        Fmt.num(o.prixUnitaire),
                                        style: x.monoMuted,
                                      ),
                                      // La colonne qui fait les parts ressort ;
                                      // l'autre s'efface.
                                      Text(
                                        '×${o.quantite}',
                                        style: byAmount
                                            ? x.monoMuted
                                            : x.monoBody,
                                      ),
                                      Text(
                                        Fmt.num(o.total),
                                        style: byAmount
                                            ? x.monoBody
                                            : x.monoMuted,
                                      ),
                                      Text(
                                        e.slice != null && e.value > 0
                                            ? _percent(e.value, total)
                                            : '—',
                                        style: x.monoMuted,
                                      ),
                                      if (cols.length > 5)
                                        Text(o.meta, style: x.monoFaint),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
          TotalBar(
            label: 'Total entrant',
            value: Fmt.ar(widget.totalEntrant),
            valueColor: t.income,
          ),
        ],
      ),
    );
  }
}

/// Étiquette d'une part, posée à gauche ou à droite de l'anneau.
class _Label {
  _Label(this.index, this.anchor, this.y);
  final int index;

  /// Point de l'anneau d'où part le trait de rappel.
  final Offset anchor;
  double y;
}

/// Anneau des parts de prestations, en montant ou en quantité. Les plus
/// grosses parts sont étiquetées autour de l'anneau ; le détail de chacune est
/// dans [PrestationsPanel], que le survol relie à l'anneau.
/// Les lignes d'une même prestation ne font qu'une part.
class PrestationsPieChart extends StatelessWidget {
  const PrestationsPieChart({super.key, required this.operations});

  final List<OperationRow> operations;

  /// Part minimale pour mériter une étiquette : en dessous, elles se
  /// chevaucheraient autour des petites parts.
  static const _labelFloor = .03;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    final view = PrestationsScope.of(context);
    final byAmount = view.metric == PrestationsMetric.montant;
    final (:slices, :total, lines: _) = _modelOf(
      context,
      operations,
      view.metric,
    );
    final active = view.active != null && view.active! < slices.length
        ? view.active
        : null;

    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  byAmount
                      ? 'Prestations · part du chiffre d’affaires'
                      : 'Prestations · part des quantités vendues',
                  style: x.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              SegmentedRow<PrestationsMetric>(
                values: PrestationsMetric.values,
                labelOf: (m) => m.label,
                selected: view.metric,
                onChanged: (m) => view.metric = m,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: total == 0
                ? EmptyState(
                    title: byAmount
                        ? 'Aucun chiffre d’affaires à répartir.'
                        : 'Aucune quantité à répartir.',
                  )
                : LayoutBuilder(
                    builder: (context, box) =>
                        _chart(context, box, view, slices, total, active),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chart(
    BuildContext context,
    BoxConstraints box,
    PrestationsView view,
    List<_Slice> slices,
    int total,
    int? active,
  ) {
    final t = context.tokens;
    final x = context.texts;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final w = box.maxWidth;
    final h = box.maxHeight;
    final r = math.min(h, math.min(w * .5, 190.0)) / 2;
    final c = Offset(w / 2, h / 2);
    final lineHeight = 18.0 * scale;
    final labelWidth = w / 2 - r - 30;

    // Étiquettes réparties des deux côtés, puis écartées pour ne pas se
    // chevaucher. Trop à l'étroit, l'anneau reste seul : le tableau a tout.
    final sides = (left: <_Label>[], right: <_Label>[]);
    if (labelWidth >= 84 * scale) {
      var start = -math.pi / 2;
      for (final (i, s) in slices.indexed) {
        final sweep = s.value / total * math.pi * 2;
        final mid = start + sweep / 2;
        start += sweep;
        if (s.value / total < _labelFloor) continue;
        final dir = Offset(math.cos(mid), math.sin(mid));
        (dir.dx >= 0 ? sides.right : sides.left).add(
          _Label(i, c + dir * (r - 3), c.dy + dir.dy * (r + 8)),
        );
      }
      _spread(sides.left, lineHeight, h);
      _spread(sides.right, lineHeight, h);
    }

    Widget label(_Label l, {required bool right}) {
      final s = slices[l.index];
      final on = l.index == active;
      return Positioned(
        left: right ? c.dx + r + 28 : c.dx - r - 28 - labelWidth,
        top: l.y - lineHeight / 2,
        width: labelWidth,
        height: lineHeight,
        child: MouseRegion(
          onEnter: (_) => view.hover(l.index, fromChart: true),
          onExit: (_) => view.hover(null),
          child: Row(
            mainAxisAlignment: right
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  s.label,
                  style: x.caption.copyWith(color: on ? t.text : t.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _percent(s.value, total),
                style: x.monoFaint.copyWith(color: on ? t.text : t.muted),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _LeaderPainter(
              center: c,
              radius: r,
              left: sides.left,
              right: sides.right,
              color: t.lineStrong,
            ),
          ),
        ),
        Positioned.fromRect(
          rect: Rect.fromCircle(center: c, radius: r),
          child: _ring(context, view, slices, total, active),
        ),
        for (final l in sides.left) label(l, right: false),
        for (final l in sides.right) label(l, right: true),
      ],
    );
  }

  /// Écarte les étiquettes d'un côté d'au moins [lineHeight], sans sortir de
  /// la hauteur [h]. S'il y en a trop, les plus petites parts cèdent.
  static void _spread(List<_Label> labels, double lineHeight, double h) {
    final max = math.max(1, (h / lineHeight).floor());
    // Les parts sont rangées par valeur décroissante : l'indice le plus grand
    // est la plus petite part.
    while (labels.length > max) {
      labels.remove(labels.reduce((a, b) => a.index > b.index ? a : b));
    }
    labels.sort((a, b) => a.y.compareTo(b.y));
    for (var i = 0; i < labels.length; i++) {
      final floor = i == 0 ? lineHeight / 2 : labels[i - 1].y + lineHeight;
      if (labels[i].y < floor) labels[i].y = floor;
    }
    for (var i = labels.length - 1; i >= 0; i--) {
      final ceil = i == labels.length - 1
          ? h - lineHeight / 2
          : labels[i + 1].y - lineHeight;
      if (labels[i].y > ceil) labels[i].y = ceil;
    }
  }

  Widget _ring(
    BuildContext context,
    PrestationsView view,
    List<_Slice> slices,
    int total,
    int? active,
  ) {
    final t = context.tokens;
    final x = context.texts;
    final byAmount = view.metric == PrestationsMetric.montant;
    final amounts = [for (final s in slices) s.value];
    final hovered = active == null ? null : slices[active];
    String withUnit(int v) =>
        byAmount ? Fmt.ar(v) : '${Fmt.num(v)} ${v > 1 ? 'unités' : 'unité'}';

    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        return Semantics(
          label:
              'Répartition des prestations par '
              '${view.metric.label.toLowerCase()}. Détail dans le tableau.',
          image: true,
          child: MouseRegion(
            onHover: (e) => view.hover(
              _DonutPainter.sliceAt(e.localPosition, size, amounts),
              fromChart: true,
            ),
            onExit: (_) => view.hover(null),
            child: CustomPaint(
              painter: _DonutPainter(
                amounts: amounts,
                colors: [for (final s in slices) s.color],
                active: active,
              ),
              child: Center(
                child: SizedBox(
                  width: size.shortestSide * .56,
                  // Au repos, le total ; au survol, la part pointée.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hovered == null ? 'TOTAL' : hovered.label,
                            style: hovered == null ? x.overline : x.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hovered == null
                                ? Fmt.num(total)
                                : _percent(hovered.value, total),
                            style: x.statAmount.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hovered == null
                                ? (byAmount ? 'Ar' : 'unités')
                                : withUnit(hovered.value),
                            style: x.monoFaint.copyWith(color: t.muted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Traits de rappel entre l'anneau et ses étiquettes.
class _LeaderPainter extends CustomPainter {
  _LeaderPainter({
    required this.center,
    required this.radius,
    required this.left,
    required this.right,
    required this.color,
  });

  final Offset center;
  final double radius;
  final List<_Label> left;
  final List<_Label> right;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = color;
    for (final (labels, sign) in [(left, -1.0), (right, 1.0)]) {
      for (final l in labels) {
        canvas.drawPath(
          Path()
            ..moveTo(l.anchor.dx, l.anchor.dy)
            ..lineTo(center.dx + sign * (radius + 12), l.y)
            ..lineTo(center.dx + sign * (radius + 22), l.y),
          paint,
        );
      }
    }
  }

  // Les étiquettes sont recalculées à chaque construction : pas de quoi
  // comparer, et le tracé tient en quelques segments.
  @override
  bool shouldRepaint(covariant _LeaderPainter old) => true;
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.amounts,
    required this.colors,
    required this.active,
  });

  final List<int> amounts;
  final List<Color> colors;
  final int? active;

  /// Épaisseur de l'anneau, en part du diamètre.
  static const _thickness = .15;

  /// Marge gardée pour l'épaississement de la part survolée.
  static const _grow = 3.0;

  /// Part sous le pointeur, ou `null` hors de l'anneau.
  static int? sliceAt(Offset p, Size size, List<int> amounts) {
    final total = amounts.fold<int>(0, (s, v) => s + v);
    if (total <= 0) return null;
    final d = size.shortestSide;
    final v = p - size.center(Offset.zero);
    final r = v.distance;
    if (r > d / 2 || r < d / 2 - d * _thickness - _grow * 2) return null;
    final angle = (math.atan2(v.dy, v.dx) + math.pi / 2) % (math.pi * 2);
    var end = 0.0;
    for (var i = 0; i < amounts.length; i++) {
      end += amounts[i] / total * math.pi * 2;
      if (angle < end) return i;
    }
    return amounts.length - 1;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final total = amounts.fold<int>(0, (s, v) => s + v);
    if (total <= 0) return;
    final d = size.shortestSide;
    final stroke = d * _thickness;
    final radius = d / 2 - _grow - stroke / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    // 2 px de fond entre deux parts : elles se distinguent sans liseré.
    final gap = amounts.length > 1 ? 2 / radius : 0.0;

    var start = -math.pi / 2;
    for (var i = 0; i < amounts.length; i++) {
      final sweep = amounts[i] / total * math.pi * 2;
      final on = i == active;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = on ? stroke + _grow * 2 : stroke
        ..color = active == null || on
            ? colors[i]
            : colors[i].withValues(alpha: .3);
      // Une part plus fine que l'interstice garde un trait visible.
      final drawn = math.max(sweep - gap, math.min(sweep, .012));
      canvas.drawArc(rect, start + (sweep - drawn) / 2, drawn, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.active != active ||
      !listEquals(old.amounts, amounts) ||
      !listEquals(old.colors, colors);
}

import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Carte de base : fond surface, bordure fine, ombre douce, rayon 14.
/// Toute zone de contenu du produit est un Panel — pas d'exception.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding, this.clip = true});

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.surface,
        border: t.border,
        borderRadius: t.br,
        boxShadow: t.shadow,
      ),
      child: ClipRRect(
        borderRadius: t.br,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

/// En-tête de carte : titre à gauche, métadonnée mono à droite.
/// Le titre s'ellipse, la métadonnée ne se comprime jamais.
class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, this.meta, this.trailing});

  final String title;
  final String? meta;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: x.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (meta != null) Text(meta!, style: x.monoFaint),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

/// Pastille de couleur sémantique (entrant / sortant / prélèvement / élec.).
class KindDot extends StatelessWidget {
  const KindDot(this.color, {super.key, this.size = 7});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// Description d'une colonne de tableau. `flex` reprend les proportions
/// de la maquette ; `numeric` aligne à droite et passe en mono tabulaire.
class Col {
  const Col(this.label, {this.flex = 1, this.numeric = false, this.width});
  final String label;
  final int flex;
  final bool numeric;
  final double? width;
}

/// Ligne d'en-tête de colonnes. Reste fixe : seul le corps défile.
class TableHeaderRow extends StatelessWidget {
  const TableHeaderRow({super.key, required this.cols, this.tinted = false});

  final List<Col> cols;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: tinted ? t.surfaceAlt : null,
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          for (final c in cols)
            _cell(
              c,
              Text(
                c.label.toUpperCase(),
                style: context.texts.columnHeader,
                textAlign: c.numeric ? TextAlign.right : TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
            ),
        ],
      ),
    );
  }
}

Widget _cell(Col c, Widget child) {
  final padded = Padding(
    padding: const EdgeInsets.only(right: 10),
    child: Align(
      alignment: c.numeric ? Alignment.centerRight : Alignment.centerLeft,
      child: child,
    ),
  );
  return c.width != null
      ? SizedBox(width: c.width, child: padded)
      : Expanded(flex: c.flex, child: padded);
}

/// Ligne de données. Hauteur = tokens.rowHeight, hover discret.
class DataRow2 extends StatefulWidget {
  const DataRow2({
    super.key,
    required this.cols,
    required this.cells,
    this.onTap,
    this.background,
  });

  final List<Col> cols;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? background;

  @override
  State<DataRow2> createState() => _DataRow2State();
}

class _DataRow2State extends State<DataRow2> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: t.rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _hover ? t.surfaceAlt : widget.background,
            border: Border(bottom: BorderSide(color: t.line)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < widget.cols.length; i++)
                _cell(widget.cols[i], widget.cells[i]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bandeau de sous-total (pied de tableau ou tête de groupe).
class TotalBar extends StatelessWidget {
  const TotalBar({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.meta,
    this.height = 32,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? meta;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: t.surfaceAlt,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: x.bodyMuted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (meta != null) ...[
            Text(meta!, style: x.monoFaint),
            const SizedBox(width: 14),
          ],
          Text(
            value,
            style: x.monoBody.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor ?? t.text,
            ),
          ),
        ],
      ),
    );
  }
}

/// Groupe segmenté (Jour/Semaine/Mois, tris, échelles de graphique).
class SegmentedRow<T> extends StatelessWidget {
  const SegmentedRow({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(border: t.border, borderRadius: t.brSmall),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final v in values)
            _SegButton(
              label: labelOf(v),
              selected: v == selected,
              onTap: () => onChanged(v),
            ),
        ],
      ),
    );
  }
}

class _SegButton extends StatelessWidget {
  const _SegButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        color: selected ? t.accentSoft : Colors.transparent,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: AppFonts.sans,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? t.accent : t.muted,
          ),
        ),
      ),
    );
  }
}

/// Bouton discret bordé — l'action secondaire par défaut du produit.
class GhostButton extends StatelessWidget {
  const GhostButton({super.key, required this.label, this.onTap, this.icon});
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: t.muted,
        side: BorderSide(color: t.line),
        shape: RoundedRectangleBorder(borderRadius: t.brSmall),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: const TextStyle(fontFamily: AppFonts.sans, fontSize: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
  }
}

// ─────────────────────────── États transverses ───────────────────────────
// Les cinq écrans secondaires partagent ces trois états. Aucun écran ne
// redéfinit son propre vide ou sa propre erreur.

/// Squelette animé pendant la lecture SQLite.
class LoadingBlocks extends StatefulWidget {
  const LoadingBlocks({super.key, this.heights = const [96, 220, 200]});
  final List<double> heights;

  @override
  State<LoadingBlocks> createState() => _LoadingBlocksState();
}

class _LoadingBlocksState extends State<LoadingBlocks>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Column(
        children: [
          for (final h in widget.heights)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: 0.35 + 0.4 * _c.value,
                child: Container(
                  height: h,
                  decoration: BoxDecoration(
                    color: t.surfaceAlt,
                    border: t.border,
                    borderRadius: t.br,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Vide : dire ce qui manque ET pourquoi (les données arrivent par import).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.hint});
  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final x = context.texts;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 14),
      child: Column(
        children: [
          Text(title, style: x.bodyMuted, textAlign: TextAlign.center),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: x.caption, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}

/// Erreur : rassurer sur l'intégrité de la base, proposer la reprise.
class ErrorPane extends StatelessWidget {
  const ErrorPane({
    super.key,
    this.title = 'Base illisible',
    this.message =
        'La sauvegarde chiffrée n\'a pas pu être déchiffrée. Aucune donnée n\'a été écrasée — la base précédente reste intacte.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Panel(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              KindDot(t.expense, size: 10),
              const SizedBox(height: 14),
              Text(title, style: x.cardTitle.copyWith(fontSize: 15)),
              const SizedBox(height: 6),
              Text(
                message,
                style: x.bodyMuted.copyWith(height: 1.55),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 18),
                GhostButton(label: 'Réessayer', onTap: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Enveloppe les trois états autour d'un contenu.
class AsyncPane extends StatelessWidget {
  const AsyncPane({
    super.key,
    required this.loading,
    required this.error,
    required this.child,
    this.onRetry,
  });

  final bool loading;
  final Object? error;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) return const LoadingBlocks();
    if (error != null) {
      return ErrorPane(message: '$error', onRetry: onRetry);
    }
    return child;
  }
}

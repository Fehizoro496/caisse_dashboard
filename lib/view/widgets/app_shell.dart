import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';

/// Les six destinations + l'écran Sauvegarde, désormais exposé.
enum AppSection {
  dashboard('Tableau de bord'),
  operations('Opérations'),
  expenses('Dépenses'),
  drawings('Prélèvements'),
  meterReadings('Relevés élec.'),
  jiroSharing('Partage JIRO'),
  backup('Sauvegarde');

  const AppSection(this.label);
  final String label;
}

/// Coquille de l'application : sidebar de navigation + barre de titre.
/// Chaque écran fournit son `title`, son `subtitle` et ses actions ;
/// aucun écran ne redessine l'ossature.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.section,
    required this.onSectionChanged,
    required this.title,
    required this.subtitle,
    required this.child,
    this.counts = const {},
    this.toolbar,
    this.onToggleTheme,
    this.isDark = false,
    this.dbCount,
    this.lastRecordLabel,
    this.onImport,
  });

  final AppSection section;
  final ValueChanged<AppSection> onSectionChanged;
  final String title;
  final String subtitle;
  final Widget child;

  /// Compteurs affichés à droite des entrées de nav (nombre d'enregistrements).
  final Map<AppSection, int> counts;

  /// Contrôles propres à l'écran, placés à droite de la barre de titre.
  final Widget? toolbar;

  final VoidCallback? onToggleTheme;
  final bool isDark;
  final int? dbCount;
  final String? lastRecordLabel;
  final VoidCallback? onImport;

  static const _navOrder = [
    AppSection.dashboard,
    AppSection.operations,
    AppSection.expenses,
    AppSection.drawings,
    AppSection.meterReadings,
    AppSection.jiroSharing,
  ];

  Color _dotOf(BuildContext context, AppSection s) {
    final t = context.tokens;
    return switch (s) {
      AppSection.dashboard => t.accent,
      AppSection.operations => t.income,
      AppSection.expenses => t.expense,
      AppSection.drawings => t.drawing,
      AppSection.meterReadings || AppSection.jiroSharing => t.electric,
      AppSection.backup => t.muted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return Scaffold(
      backgroundColor: t.bg,
      body: Row(
        children: [
          // ── Sidebar
          Container(
            width: 230,
            decoration: BoxDecoration(
              color: t.surface,
              border: Border(right: BorderSide(color: t.line)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: t.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CAISSE',
                        style: TextStyle(
                          fontFamily: AppFonts.sans,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: t.text,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('Multi-services · hors ligne', style: x.caption),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    children: [
                      for (final s in _navOrder)
                        _NavItem(
                          label: s.label,
                          dot: _dotOf(context, s),
                          badge: counts[s],
                          selected: s == section,
                          onTap: () => onSectionChanged(s),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: t.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GhostButton(
                        label: 'Sauvegarde',
                        icon: Icons.lock_outline,
                        onTap: () => onSectionChanged(AppSection.backup),
                      ),
                      if (dbCount != null) ...[
                        const SizedBox(height: 10),
                        Text('db · $dbCount enreg.', style: x.monoFaint),
                        if (lastRecordLabel != null)
                          Text(
                            'dernier · $lastRecordLabel',
                            style: x.monoFaint,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Zone de travail
          Expanded(
            child: Column(
              children: [
                Container(
                  // height: kToolbarHeight,
                  padding: EdgeInsets.symmetric(
                    horizontal: t.pad,
                    vertical: 17.0,
                  ),
                  decoration: BoxDecoration(
                    color: t.surface,
                    border: Border(bottom: BorderSide(color: t.line)),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    children: [
                      // Le titre est le SEUL élément compressible de la barre.
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: x.pageTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: x.pageSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (toolbar != null) ...[
                        const SizedBox(width: 14),
                        toolbar!,
                      ],
                      const SizedBox(width: 14),
                      if (onToggleTheme != null)
                        IconButton(
                          onPressed: onToggleTheme,
                          iconSize: 15,
                          tooltip: isDark ? 'Thème clair' : 'Thème sombre',
                          style: IconButton.styleFrom(
                            side: BorderSide(color: t.line),
                            shape: const CircleBorder(),
                            minimumSize: const Size(32, 32),
                          ),
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: t.muted,
                          ),
                        ),
                      const SizedBox(width: 10),
                      GhostButton(
                        label: 'Importer .enc',
                        onTap:
                            onImport ??
                            () => onSectionChanged(AppSection.backup),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(padding: EdgeInsets.all(t.pad), child: child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final Color dot;
  final bool selected;
  final VoidCallback onTap;
  final int? badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final bg = widget.selected
        ? t.accentSoft
        : _hover
        ? t.surfaceAlt
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(color: bg, borderRadius: t.brSmall),
            child: Row(
              children: [
                Opacity(
                  opacity: widget.selected ? 1 : .55,
                  child: KindDot(widget.dot, size: 8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: AppFonts.sans,
                      fontSize: 13,
                      fontWeight: widget.selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.selected ? t.accent : t.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.badge != null)
                  Text('${widget.badge}', style: x.monoFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation de date + cadrage Jour/Semaine/Mois du dashboard.
/// `onNext` est nul quand la date courante atteint le dernier enregistrement.
class DateToolbar extends StatelessWidget {
  const DateToolbar({
    super.key,
    required this.label,
    required this.period,
    required this.onPeriodChanged,
    required this.onPrev,
    this.onNext,
    this.onPickDate,
  });

  final String label;
  final Period period;
  final ValueChanged<Period> onPeriodChanged;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback? onPickDate;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(border: t.border, borderRadius: t.brSmall),
          clipBehavior: Clip.antiAlias,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(icon: Icons.chevron_left, onTap: onPrev),
              InkWell(
                onTap: onPickDate,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 120),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      vertical: BorderSide(color: t.line),
                    ),
                  ),
                  child: Text(
                    label,
                    style: context.texts.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              _StepButton(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SegmentedRow<Period>(
          values: Period.values,
          labelOf: (p) => p.label,
          selected: period,
          onChanged: onPeriodChanged,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 34,
        height: 32,
        child: Icon(
          icon,
          size: 18,
          color: onTap == null ? t.lineStrong : t.muted,
        ),
      ),
    );
  }
}

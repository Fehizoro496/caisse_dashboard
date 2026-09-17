import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart'
    show categoryColor;
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
import 'package:flutter/material.dart';

/// Charges fixes du mois — loyer, fournitures, factures.
///
/// Ce n'est pas un écran-liste comme les autres : [LedgerScreen] groupe ses
/// lignes par jour, or une charge n'a pas de jour. D'où un écran propre,
/// piloté par un mois et non par une date.
class ChargesScreen extends StatelessWidget {
  const ChargesScreen({
    super.key,
    required this.charges,
    required this.mois,
    required this.onMoisChanged,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
    required this.reportables,
    required this.onReport,
    this.incluses = true,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final List<ChargeMensuelle> charges;
  final DateTime mois;
  final ValueChanged<DateTime> onMoisChanged;

  final VoidCallback onAdd;
  final ValueChanged<ChargeMensuelle> onEdit;
  final ValueChanged<ChargeMensuelle> onDelete;

  /// Charges du mois précédent, proposées au report quand le mois est vide.
  final List<ChargeMensuelle> reportables;
  final VoidCallback onReport;

  /// Les charges pèsent-elles sur le solde du tableau de bord ? Rappelé ici
  /// pour que la saisie n'ait pas l'air sans effet quand la bascule est off.
  final bool incluses;

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  int get _total => charges.fold<int>(0, (s, c) => s + c.montant);

  static const _cols = [
    Col('Charge', flex: 3),
    Col('Catégorie', flex: 2),
    Col('Enregistrée le', flex: 2, numeric: true),
    Col('P.U.', flex: 2, numeric: true),
    Col('Qté', numeric: true),
    Col('Total', flex: 2, numeric: true),
    Col('', width: 76),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return AsyncPane(
      loading: loading,
      error: error,
      onRetry: onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _MonthStepper(mois: mois, onChanged: onMoisChanged),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  incluses
                      ? 'Imputées au solde du mois — jamais au jour ni à la semaine.'
                      : 'Actuellement exclues du solde : la bascule « Charges » '
                            'du tableau de bord les réintègre.',
                  style: x.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              GhostButton(
                label: 'Ajouter une charge',
                icon: Icons.add,
                onTap: onAdd,
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
                        const TableHeaderRow(cols: _cols, tinted: true),
                        Expanded(
                          child: charges.isEmpty
                              ? _empty(context)
                              : ListView.builder(
                                  itemCount: charges.length,
                                  itemBuilder: (context, i) {
                                    final c = charges[i];
                                    final cat = c.categorieEffective;
                                    return DataRow2(
                                      cols: _cols,
                                      onTap: () => onEdit(c),
                                      cells: [
                                        Text(
                                          c.libelle,
                                          style: x.body,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          cat,
                                          style: x.body.copyWith(
                                            color: categoryColor(context, cat),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        // Saisie hors du mois couvert : la
                                        // date passe en accent pour que le
                                        // décalage se voie sans se lire.
                                        Tooltip(
                                          message:
                                              'Enregistrée le '
                                              '${Fmt.longDate(c.dateEnregistrement)}'
                                              '${c.horsMois ? ' — imputée à ${Fmt.month(c.mois)}' : ''}',
                                          child: Text(
                                            Fmt.numericDate(
                                              c.dateEnregistrement,
                                            ),
                                            style: c.horsMois
                                                ? x.monoBody.copyWith(
                                                    color: t.charge,
                                                  )
                                                : x.monoMuted,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          Fmt.num(c.prixUnitaire),
                                          style: x.monoMuted,
                                        ),
                                        // « ×1 » n'apprend rien : le tiret
                                        // laisse la colonne parlante aux seules
                                        // lignes qui portent une quantité.
                                        Text(
                                          c.multiple ? "${c.quantite}" : '—',
                                          style: c.multiple
                                              ? x.monoBody
                                              : x.monoFaint,
                                        ),
                                        Text(
                                          Fmt.num(c.montant),
                                          style: x.monoBody,
                                        ),
                                        // Le crayon double le clic sur la
                                        // ligne : sans lui, la seule icône
                                        // visible serait la corbeille, et
                                        // rien ne dirait qu'une charge se
                                        // corrige.
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RowEditButton(
                                              onTap: () => onEdit(c),
                                            ),
                                            const SizedBox(width: 2),
                                            _DeleteButton(
                                              onConfirmed: () => onDelete(c),
                                              libelle: c.libelle,
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                        TotalBar(
                          label: 'Total des charges',
                          meta: '${charges.length} '
                              '${charges.length > 1 ? 'lignes' : 'ligne'}',
                          value: Fmt.ar(_total),
                          valueColor: t.charge,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(width: 236, child: _Summary(this)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    if (reportables.isEmpty) {
      return const EmptyState(
        title: 'Aucune charge pour ce mois.',
        hint: 'Loyer, fournitures, factures — ajoutez-les ici pour qu\'elles '
            'pèsent sur le solde du mois.',
      );
    }
    final total = reportables.fold<int>(0, (s, c) => s + c.montant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 14),
      child: Column(
        children: [
          Text(
            'Aucune charge pour ce mois.',
            style: context.texts.bodyMuted,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '${reportables.length} charge'
            '${reportables.length > 1 ? 's' : ''} le mois précédent, '
            '${Fmt.ar(total)} au total. Les montants restent corrigeables '
            'ligne par ligne après le report.',
            style: context.texts.caption.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GhostButton(
            label: 'Reporter le mois précédent',
            icon: Icons.content_copy_outlined,
            onTap: onReport,
          ),
        ],
      ),
    );
  }
}

/// Navigation de mois sans borne haute : préparer le loyer du mois prochain
/// est un usage normal, contrairement à la consultation d'une caisse future.
class _MonthStepper extends StatelessWidget {
  const _MonthStepper({required this.mois, required this.onChanged});
  final DateTime mois;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(border: t.border, borderRadius: t.brSmall),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Step(
            icon: Icons.chevron_left,
            onTap: () => onChanged(DateTime(mois.year, mois.month - 1)),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 140),
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.symmetric(vertical: BorderSide(color: t.line)),
            ),
            child: Text(Fmt.cap(Fmt.month(mois)), style: context.texts.body),
          ),
          _Step(
            icon: Icons.chevron_right,
            onTap: () => onChanged(DateTime(mois.year, mois.month + 1)),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: SizedBox(
      width: 34,
      height: 32,
      child: Icon(icon, size: 18, color: context.tokens.muted),
    ),
  );
}

/// Suppression en deux temps : la ligne entière ouvrant déjà la correction,
/// une corbeille sans confirmation effacerait sur un clic mal placé.
class _DeleteButton extends StatefulWidget {
  const _DeleteButton({required this.onConfirmed, required this.libelle});
  final VoidCallback onConfirmed;
  final String libelle;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _hover = false;

  Future<void> _confirm() async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: t.br),
        title: Text('Supprimer la charge ?', style: ctx.texts.cardTitle),
        content: Text(
          '« ${widget.libelle} » sera retirée du mois et du solde. '
          'Cette suppression ne peut pas être annulée.',
          style: ctx.texts.bodyMuted.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Annuler', style: TextStyle(color: t.muted)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: t.danger,
              shape: RoundedRectangleBorder(borderRadius: t.brSmall),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok == true) widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Tooltip(
      message: 'Supprimer',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: _confirm,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: _hover ? t.surfaceAlt : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              Icons.delete_outline,
              size: 14,
              color: _hover ? t.danger : t.faint,
            ),
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(this.screen);
  final ChargesScreen screen;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final charges = screen.charges;
    final total = screen._total;
    final byCat = <String, int>{};
    for (final c in charges) {
      final k = c.categorieEffective;
      byCat[k] = (byCat[k] ?? 0) + c.montant;
    }
    final entries = byCat.entries.map((e) => (e.key, e.value)).toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CHARGES DU MOIS', style: x.overline),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    Fmt.ar(total),
                    style: x.statAmount.copyWith(
                      color: screen.incluses ? t.charge : t.faint,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  screen.incluses ? 'imputées au solde' : 'hors solde net',
                  style: x.monoFaint,
                ),
              ],
            ),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 12),
            Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('PAR CATÉGORIE', style: x.overline),
                  const SizedBox(height: 12),
                  CategoryBreakdown(
                    entries: entries,
                    colorOf: (c) => categoryColor(context, c),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

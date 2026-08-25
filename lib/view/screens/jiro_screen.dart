import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Saisie validée, prête à être persistée puis imprimée.
class JiroDraft {
  const JiroDraft({
    required this.mois,
    required this.bill,
    required this.sousCompteurPrecedent,
    required this.sousCompteurActuel,
    required this.dateIndexPrecedent,
    required this.dateIndexActuel,
  });

  final String mois;
  final JiroBill bill;
  final double sousCompteurPrecedent;
  final double sousCompteurActuel;

  /// Dates issues de la résolution des sous-compteurs (relevé ou interpolation).
  final DateTime dateIndexPrecedent;
  final DateTime dateIndexActuel;
}

/// Valeurs de départ du formulaire, reprises de la dernière facture générée :
/// le prix du kWh et les frais fixes changent rarement d'un mois à l'autre.
class JiroDefaults {
  const JiroDefaults({
    required this.prixKwh,
    required this.redevance,
    required this.primeFixe,
    required this.taxes,
    required this.tva,
  });

  final double prixKwh;
  final double redevance;
  final double primeFixe;
  final double taxes;
  final double tva;
}

/// Partage JIRO — le seul écran producteur de l'application.
/// Il s'ouvre sur l'historique des partages générés ; le formulaire de saisie
/// apparaît à la demande via « Nouveau partage ».
class JiroScreen extends StatefulWidget {
  const JiroScreen({
    super.key,
    required this.history,
    required this.releves,
    required this.onGenerate,
    this.defaults,
    this.loading = false,
    this.error,
    this.onRetry,
    this.onOpenPdf,
    this.onDelete,
  });

  final List<JiroSharing> history;

  /// Sert à résoudre les sous-compteurs des index saisis.
  final List<ReleveElectricite> releves;

  /// Appelé à la validation : persiste la facture et génère le PDF.
  final void Function(JiroDraft draft) onGenerate;

  final JiroDefaults? defaults;
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;
  final void Function(JiroSharing)? onOpenPdf;
  final void Function(JiroSharing)? onDelete;

  @override
  State<JiroScreen> createState() => _JiroScreenState();
}

class _JiroScreenState extends State<JiroScreen> {
  bool _newSharing = false;

  final _periode = TextEditingController();
  final _idxPrec = TextEditingController();
  final _idxAct = TextEditingController();
  late final _prix = TextEditingController(text: _initial((d) => d.prixKwh));
  late final _redevance = TextEditingController(
    text: _initial((d) => d.redevance),
  );
  late final _prime = TextEditingController(text: _initial((d) => d.primeFixe));
  late final _taxes = TextEditingController(text: _initial((d) => d.taxes));
  late final _tva = TextEditingController(text: _initial((d) => d.tva));

  String _initial(double Function(JiroDefaults) pick) {
    final d = widget.defaults;
    if (d == null) return '';
    final v = pick(d);
    return v == v.roundToDouble() ? '${v.round()}' : '$v';
  }

  @override
  void dispose() {
    for (final c in [
      _periode,
      _idxPrec,
      _idxAct,
      _prix,
      _redevance,
      _prime,
      _taxes,
      _tva,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _n(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim()) ?? 0;

  SubMeterResolution _resolve(TextEditingController c) => resolveSubMeter(
    double.tryParse(c.text.replaceAll(',', '.').trim()),
    widget.releves,
    dateLabel: Fmt.shortDate,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return AsyncPane(
      loading: widget.loading,
      error: widget.error,
      onRetry: widget.onRetry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                _newSharing ? 'Nouveau partage' : 'Partages générés',
                style: x.cardTitle,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _newSharing
                      ? 'Saisie de la facture JIRAMA et résolution des sous-compteurs'
                      : '${widget.history.length} factures réparties · PDF archivés',
                  style: x.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_newSharing)
                GhostButton(
                  label: 'Retour à la liste',
                  icon: Icons.arrow_back,
                  onTap: () => setState(() => _newSharing = false),
                )
              else
                FilledButton(
                  onPressed: () => setState(() => _newSharing = true),
                  style: FilledButton.styleFrom(
                    backgroundColor: t.accent,
                    shape: RoundedRectangleBorder(borderRadius: t.brSmall),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Nouveau partage'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: _newSharing ? _form(context) : _history(context)),
        ],
      ),
    );
  }

  // ───────────────────────────── Historique ─────────────────────────────

  Widget _history(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    const cols = [
      Col('Période', flex: 2),
      Col('Index général', flex: 3),
      Col('Conso 1 / 2', flex: 3, numeric: true),
      Col('Part 1', flex: 3, numeric: true),
      Col('Part 2', flex: 3, numeric: true),
      Col('Facture', flex: 3, numeric: true),
      Col('Généré', flex: 2, numeric: true),
      Col('', width: 96),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TableHeaderRow(cols: cols, tinted: true),
          Expanded(
            child: widget.history.isEmpty
                ? const EmptyState(
                    title: 'Aucun partage généré pour l\'instant.',
                    hint: 'Le bouton « Nouveau partage » ouvre le formulaire.',
                  )
                : ListView.builder(
                    itemCount: widget.history.length,
                    itemBuilder: (context, i) {
                      final s = widget.history[i];
                      return DataRow2(
                        cols: cols,
                        cells: [
                          Text(
                            s.periode,
                            style: x.body.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${Fmt.dec(s.indexPrecedent)} → ${Fmt.dec(s.indexActuel)}',
                            style: x.monoMuted,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          RichText(
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: Fmt.dec(s.conso1),
                                  style: x.monoMuted.copyWith(color: t.drawing),
                                ),
                                TextSpan(text: ' / ', style: x.monoFaint),
                                TextSpan(
                                  text: Fmt.kwh(s.conso2),
                                  style: x.monoMuted.copyWith(
                                    color: t.electric,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(Fmt.ar(s.part1), style: x.monoBody),
                          Text(Fmt.ar(s.part2), style: x.monoBody),
                          Text(
                            Fmt.ar(s.total),
                            style: x.monoBody.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(Fmt.shortDate(s.genereLe), style: x.monoFaint),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: widget.onOpenPdf == null
                                    ? null
                                    : () => widget.onOpenPdf!(s),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 26),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  foregroundColor: t.muted,
                                  side: BorderSide(color: t.lineStrong),
                                  shape: const StadiumBorder(),
                                  textStyle: const TextStyle(fontSize: 11),
                                ),
                                child: const Text('PDF'),
                              ),
                              if (widget.onDelete != null)
                                IconButton(
                                  onPressed: () => _confirmDelete(context, s),
                                  iconSize: 14,
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Supprimer',
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: t.faint,
                                  ),
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
    );
  }

  Future<void> _confirmDelete(BuildContext context, JiroSharing s) async {
    final t = context.tokens;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: t.br),
        title: Text('Supprimer le partage ?', style: context.texts.cardTitle),
        content: Text(
          'Le partage de ${s.periode} sera retiré de l\'historique. '
          'Le PDF déjà généré, lui, reste sur le disque.',
          style: context.texts.bodyMuted.copyWith(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler', style: TextStyle(color: t.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer', style: TextStyle(color: t.expense)),
          ),
        ],
      ),
    );
    if (ok == true) widget.onDelete!(s);
  }

  // ────────────────────────────── Formulaire ──────────────────────────────

  Widget _form(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    final rp = _resolve(_idxPrec);
    final ra = _resolve(_idxAct);
    final bill = JiroBill(
      indexPrecedent: _n(_idxPrec),
      indexActuel: _n(_idxAct),
      prixKwh: _n(_prix),
      redevance: _n(_redevance),
      primeFixe: _n(_prime),
      taxes: _n(_taxes),
      tva: _n(_tva),
    );

    final conso1 = (rp.value != null && ra.value != null)
        ? ra.value! - rp.value!
        : null;
    final conso2 = conso1 == null ? null : bill.consoTotale - conso1;

    // Validation bloquée tant que les deux sous-compteurs ne sont pas résolus.
    final blocked =
        !rp.ok ||
        !ra.ok ||
        _periode.text.trim().isEmpty ||
        bill.consoTotale <= 0 ||
        bill.prixKwh <= 0 ||
        conso1 == null ||
        conso1 < 0 ||
        (conso2 ?? -1) < 0;

    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 380,
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PanelHeader(title: 'Facture JIRAMA'),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _labelled(
                          'Période facturée',
                          TextField(
                            controller: _periode,
                            style: x.body,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              hintText: 'Ex. Janvier 2026',
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _indexField('Index précédent (général)', _idxPrec, rp),
                        const SizedBox(height: 14),
                        _indexField('Index actuel (général)', _idxAct, ra),
                        const SizedBox(height: 14),
                        Divider(color: t.line),
                        const SizedBox(height: 6),
                        _money('Prix du kWh', _prix),
                        _money('Redevance', _redevance),
                        _money('Prime fixe', _prime),
                        _money('Taxes', _taxes),
                        _money('TVA', _tva),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: blocked
                              ? null
                              : () {
                                  widget.onGenerate(
                                    JiroDraft(
                                      mois: _periode.text.trim(),
                                      bill: bill,
                                      sousCompteurPrecedent: rp.value!,
                                      sousCompteurActuel: ra.value!,
                                      dateIndexPrecedent: rp.date!,
                                      dateIndexActuel: ra.date!,
                                    ),
                                  );
                                  setState(() => _newSharing = false);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: t.accent,
                            disabledBackgroundColor: t.surfaceAlt,
                            disabledForegroundColor: t.faint,
                            shape: RoundedRectangleBorder(
                              borderRadius: t.brSmall,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Générer le partage (PDF)'),
                        ),
                        if (blocked) ...[
                          const SizedBox(height: 10),
                          Text(
                            'Validation bloquée : période, prix du kWh et les deux '
                            'sous-compteurs doivent être résolus (relevé exact ou '
                            'interpolation) avant de générer le partage.',
                            style: x.caption.copyWith(
                              color: t.expense,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _kpi(
                      context,
                      'Conso totale',
                      bill.consoTotale > 0 ? Fmt.kwh(bill.consoTotale) : '—',
                      t.electric,
                      'index actuel − précédent',
                    ),
                    _kpi(
                      context,
                      'Conso 1',
                      conso1 == null ? '—' : Fmt.kwh(conso1),
                      t.drawing,
                      'sous-compteur',
                    ),
                    _kpi(
                      context,
                      'Conso 2',
                      conso2 == null ? '—' : Fmt.kwh(conso2),
                      t.electric,
                      'le reste',
                    ),
                    _kpi(
                      context,
                      'Facture totale',
                      Fmt.ar(bill.totalFacture),
                      t.text,
                      'frais fixes inclus',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _shareTable(
                        context,
                        'Occupant 1 — sous-compteur',
                        conso1 == null ? 'non résolu' : Fmt.kwh(conso1),
                        t.drawing,
                        bill,
                        conso1 ?? 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _shareTable(
                        context,
                        'Occupant 2 — le reste',
                        conso2 == null ? 'non résolu' : Fmt.kwh(conso2),
                        t.electric,
                        bill,
                        conso2 ?? 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Panel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          blocked
                              ? 'Contrôle indisponible tant que la répartition n\'est pas résolue.'
                              : 'Contrôle : occupant 1 + occupant 2 = facture totale',
                          style: x.bodyMuted,
                        ),
                      ),
                      Text(
                        blocked ? '—' : Fmt.ar(bill.totalFacture),
                        style: x.monoBody.copyWith(
                          color: blocked ? t.faint : t.income,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelled(String label, Widget field) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label.toUpperCase(), style: context.texts.overline),
      const SizedBox(height: 6),
      field,
    ],
  );

  /// Les trois états de résolution du sous-compteur, affichés par champ :
  /// relevé exact, interpolé, non résolu.
  Widget _indexField(
    String label,
    TextEditingController c,
    SubMeterResolution r,
  ) {
    final t = context.tokens;
    final x = context.texts;
    final (bg, fg, border) = switch (r.state) {
      SubMeterState.exact => (t.accentSoft, t.income, t.line),
      SubMeterState.interpolated => (t.surfaceAlt, t.electric, t.electric),
      SubMeterState.unresolved => (t.surfaceAlt, t.expense, t.expense),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label.toUpperCase(), style: x.overline)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                r.state.label,
                style: x.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          style: x.monoBody,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: t.brSmall,
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(r.message, style: x.caption)),
            Text(
              r.value == null
                  ? 'sous-compteur ?'
                  : 'sous-c. ${r.state == SubMeterState.interpolated ? r.value!.toStringAsFixed(1) : Fmt.dec(r.value!)}',
              style: x.monoFaint.copyWith(color: fg),
            ),
          ],
        ),
      ],
    );
  }

  Widget _money(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(child: Text(label, style: context.texts.bodyMuted)),
        SizedBox(
          width: 118,
          child: TextField(
            controller: c,
            textAlign: TextAlign.right,
            style: context.texts.monoBody,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(width: 26, child: Text('  Ar', style: context.texts.caption)),
      ],
    ),
  );

  Widget _kpi(
    BuildContext context,
    String label,
    String value,
    Color color,
    String sub,
  ) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Panel(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: context.texts.overline),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: context.texts.statAmount.copyWith(
                  fontSize: 19,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(sub, style: context.texts.caption),
          ],
        ),
      ),
    ),
  );

  /// Détail d'un occupant : conso valorisée, puis la moitié de chaque poste
  /// fixe — c'est la règle de partage déjà appliquée par le PDF.
  Widget _shareTable(
    BuildContext context,
    String title,
    String sub,
    Color color,
    JiroBill bill,
    double conso,
  ) {
    final x = context.texts;
    final s = bill.shareFor(conso);
    final lines = <(String, String, String, bool)>[
      (
        'Consommation',
        '${Fmt.kwh(conso)} × ${Fmt.num(bill.prixKwh)} Ar',
        Fmt.ar(s.variable),
        false,
      ),
      (
        'Redevance',
        '${Fmt.num(bill.redevance)} ÷ 2',
        Fmt.ar(s.redevance),
        false,
      ),
      (
        'Prime fixe',
        '${Fmt.num(bill.primeFixe)} ÷ 2',
        Fmt.ar(s.primeFixe),
        false,
      ),
      ('Taxes', '${Fmt.num(bill.taxes)} ÷ 2', Fmt.ar(s.taxes), false),
      ('Sous-total', '', Fmt.ar(s.sousTotal), true),
      ('TVA', '${Fmt.num(bill.tva)} ÷ 2', Fmt.ar(s.tva), false),
    ];

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelHeader(title: title, meta: sub, trailing: KindDot(color)),
          for (final l in lines)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.tokens.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l.$1,
                      style: x.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (l.$2.isNotEmpty)
                    Flexible(
                      child: Text(
                        l.$2,
                        style: x.monoFaint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const SizedBox(width: 10),
                  Text(
                    l.$3,
                    style: x.monoBody.copyWith(
                      fontWeight: l.$4 ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          TotalBar(height: 38, label: 'Total à payer', value: Fmt.ar(s.total)),
        ],
      ),
    );
  }
}

import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart'
    show categoryColor;
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Correction d'une opération déjà enregistrée. Rien d'autre que les champs
/// saisissables : l'identifiant ne bouge pas, c'est lui qui porte la fusion
/// à l'import.
class OperationEdit {
  const OperationEdit({
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.date,
  });

  final String nom;
  final int prixUnitaire;
  final int quantite;
  final DateTime date;
}

/// Correction d'une dépense déjà enregistrée. La catégorie n'est pas stockée :
/// elle se recalcule depuis le libellé, donc corriger le libellé la corrige.
class DepenseEdit {
  const DepenseEdit({
    required this.libelle,
    required this.montant,
    required this.date,
  });

  final String libelle;
  final int montant;
  final DateTime date;
}

/// Correction d'un prélèvement déjà enregistré.
class PrelevementEdit {
  const PrelevementEdit({required this.montant, required this.date});

  final int montant;
  final DateTime date;
}

/// Saisie ou correction d'une charge mensuelle. Elle porte deux dates aux
/// rôles distincts — le mois imputé, qui décide du cadrage où elle est
/// comptée, et le jour de la saisie, qui n'est qu'une trace.
class ChargeEdit {
  const ChargeEdit({
    required this.libelle,
    required this.prixUnitaire,
    required this.mois,
    required this.dateEnregistrement,
    required this.categorie,
    this.quantite = 1,
  });

  final String libelle;

  /// Prix d'une unité ; le total vaut [prixUnitaire] × [quantite].
  final int prixUnitaire;
  final int quantite;

  int get montant => prixUnitaire * quantite;

  /// Premier jour du mois d'imputation — ce qui décide du cadrage.
  final DateTime mois;

  /// Jour de la saisie, sans heure, indépendant du mois couvert.
  final DateTime dateEnregistrement;

  /// Catégorie retenue. Toujours renseignée : le formulaire part de la
  /// déduction et n'enregistre que ce qui est affiché à l'écran.
  final String categorie;
}

/// Correction d'un relevé électrique. Les index sont réels : un compteur ne
/// tombe pas sur un entier rond.
class ReleveEdit {
  const ReleveEdit({
    required this.compteur,
    required this.sousCompteur,
    required this.date,
  });

  final double compteur;
  final double sousCompteur;
  final DateTime date;
}

/// Ouvre le formulaire de correction d'une opération.
/// Retourne `null` si l'utilisateur annule ou ne change rien.
Future<OperationEdit?> showOperationEditor(
  BuildContext context, {
  required String nom,
  required int prixUnitaire,
  required int quantite,
  required DateTime date,
}) => showDialog<OperationEdit>(
  context: context,
  builder: (_) => _OperationDialog(
    nom: nom,
    prixUnitaire: prixUnitaire,
    quantite: quantite,
    date: date,
  ),
);

/// Ouvre le formulaire de correction d'une dépense.
/// Retourne `null` si l'utilisateur annule ou ne change rien.
Future<DepenseEdit?> showDepenseEditor(
  BuildContext context, {
  required String libelle,
  required int montant,
  required DateTime date,
}) => showDialog<DepenseEdit>(
  context: context,
  builder: (_) => _DepenseDialog(
    libelle: libelle,
    montant: montant,
    date: date,
  ),
);

/// Ouvre le formulaire de correction d'un prélèvement.
/// Retourne `null` si l'utilisateur annule ou ne change rien.
Future<PrelevementEdit?> showPrelevementEditor(
  BuildContext context, {
  required int montant,
  required DateTime date,
}) => showDialog<PrelevementEdit>(
  context: context,
  builder: (_) => _PrelevementDialog(montant: montant, date: date),
);

/// Ouvre le formulaire d'une charge mensuelle. Sans [libelle] ni
/// [prixUnitaire], c'est une création ; sinon une correction.
/// Retourne `null` si l'utilisateur annule ou ne change rien.
Future<ChargeEdit?> showChargeEditor(
  BuildContext context, {
  String? libelle,
  int? prixUnitaire,
  int? quantite,
  required DateTime mois,
  DateTime? dateEnregistrement,
  String? categorie,
  List<ChargeSuggestion> suggestions = const [],
}) => showDialog<ChargeEdit>(
  context: context,
  builder: (_) => _ChargeDialog(
    libelle: libelle,
    prixUnitaire: prixUnitaire,
    quantite: quantite,
    mois: mois,
    dateEnregistrement: dateEnregistrement,
    categorie: categorie,
    suggestions: suggestions,
  ),
);

/// Ouvre le formulaire de correction d'un relevé électrique.
/// Retourne `null` si l'utilisateur annule ou ne change rien.
Future<ReleveEdit?> showReleveEditor(
  BuildContext context, {
  required double compteur,
  required double sousCompteur,
  required DateTime date,
}) => showDialog<ReleveEdit>(
  context: context,
  builder: (_) => _ReleveDialog(
    compteur: compteur,
    sousCompteur: sousCompteur,
    date: date,
  ),
);

// ──────────────────────────────── Opération ────────────────────────────────

class _OperationDialog extends StatefulWidget {
  const _OperationDialog({
    required this.nom,
    required this.prixUnitaire,
    required this.quantite,
    required this.date,
  });

  final String nom;
  final int prixUnitaire;
  final int quantite;
  final DateTime date;

  @override
  State<_OperationDialog> createState() => _OperationDialogState();
}

class _OperationDialogState extends State<_OperationDialog> {
  late final _nom = TextEditingController(text: widget.nom);
  late final _prix = TextEditingController(text: '${widget.prixUnitaire}');
  late final _qte = TextEditingController(text: '${widget.quantite}');
  late DateTime _date = widget.date;

  @override
  void dispose() {
    for (final c in [_nom, _prix, _qte]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _nomValue => _nom.text.trim();
  int get _prixValue => int.tryParse(_prix.text.trim()) ?? -1;
  int get _qteValue => int.tryParse(_qte.text.trim()) ?? 0;

  String? get _blocage {
    if (_nomValue.isEmpty) return 'La prestation ne peut pas être vide.';
    if (_prixValue < 0) return 'Le prix unitaire doit être un nombre entier.';
    if (_qteValue < 1) return 'La quantité doit être au moins 1.';
    return null;
  }

  bool get _modifie =>
      _nomValue != widget.nom ||
      _prixValue != widget.prixUnitaire ||
      _qteValue != widget.quantite ||
      _date != widget.date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _EditorShell(
      title: 'Modifier l\'opération',
      subtitle: 'Enregistrée le ${Fmt.numericDate(widget.date)} '
          'à ${Fmt.hour(widget.date)}',
      accent: t.income,
      blocage: _blocage,
      canSave: _modifie,
      onSave: () => Navigator.of(context).pop(
        OperationEdit(
          nom: _nomValue,
          prixUnitaire: _prixValue,
          quantite: _qteValue,
          date: _date,
        ),
      ),
      fields: [
        _LabelledField(
          label: 'Prestation',
          child: TextField(
            controller: _nom,
            autofocus: true,
            style: context.texts.body,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ex. Photocopie A4',
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _LabelledField(
                label: 'Prix unitaire (Ar)',
                child: _IntegerField(
                  controller: _prix,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabelledField(
                label: 'Quantité',
                child: _IntegerField(
                  controller: _qte,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DateTimeField(
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 14),
        _Preview(
          label: 'Total de la ligne',
          value: _blocage != null
              ? '—'
              : Fmt.ar(_prixValue * _qteValue),
          color: t.income,
          note: _blocage != null
              ? null
              : '${Fmt.num(_prixValue)} × $_qteValue',
        ),
      ],
    );
  }
}

// ───────────────────────────────── Dépense ─────────────────────────────────

class _DepenseDialog extends StatefulWidget {
  const _DepenseDialog({
    required this.libelle,
    required this.montant,
    required this.date,
  });

  final String libelle;
  final int montant;
  final DateTime date;

  @override
  State<_DepenseDialog> createState() => _DepenseDialogState();
}

class _DepenseDialogState extends State<_DepenseDialog> {
  late final _libelle = TextEditingController(text: widget.libelle);
  late final _montant = TextEditingController(text: '${widget.montant}');
  late DateTime _date = widget.date;

  @override
  void dispose() {
    _libelle.dispose();
    _montant.dispose();
    super.dispose();
  }

  String get _libelleValue => _libelle.text.trim();
  int get _montantValue => int.tryParse(_montant.text.trim()) ?? 0;

  String? get _blocage {
    if (_libelleValue.isEmpty) return 'Le libellé ne peut pas être vide.';
    if (_montantValue <= 0) return 'Le montant doit être supérieur à zéro.';
    return null;
  }

  bool get _modifie =>
      _libelleValue != widget.libelle ||
      _montantValue != widget.montant ||
      _date != widget.date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final categorie = CategoryRules.of(_libelleValue);

    return _EditorShell(
      title: 'Modifier la dépense',
      subtitle: 'Enregistrée le ${Fmt.numericDate(widget.date)} '
          'à ${Fmt.hour(widget.date)}',
      accent: t.expense,
      blocage: _blocage,
      canSave: _modifie,
      onSave: () => Navigator.of(context).pop(
        DepenseEdit(
          libelle: _libelleValue,
          montant: _montantValue,
          date: _date,
        ),
      ),
      fields: [
        _LabelledField(
          label: 'Libellé',
          child: TextField(
            controller: _libelle,
            autofocus: true,
            style: context.texts.body,
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ex. Ramette A4',
            ),
          ),
        ),
        const SizedBox(height: 14),
        _LabelledField(
          label: 'Montant (Ar)',
          child: _IntegerField(
            controller: _montant,
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        _DateTimeField(
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 14),
        // La catégorie se déduit du libellé : la montrer évite la surprise
        // d'une dépense qui change de couleur après correction d'une faute.
        _Preview(
          label: 'Catégorie déduite',
          value: categorie,
          color: categoryColor(context, categorie),
          note: _blocage == null ? Fmt.ar(_montantValue) : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────── Prélèvement ───────────────────────────────

class _PrelevementDialog extends StatefulWidget {
  const _PrelevementDialog({required this.montant, required this.date});

  final int montant;
  final DateTime date;

  @override
  State<_PrelevementDialog> createState() => _PrelevementDialogState();
}

class _PrelevementDialogState extends State<_PrelevementDialog> {
  late final _montant = TextEditingController(text: '${widget.montant}');
  late DateTime _date = widget.date;

  @override
  void dispose() {
    _montant.dispose();
    super.dispose();
  }

  int get _montantValue => int.tryParse(_montant.text.trim()) ?? 0;

  String? get _blocage => _montantValue <= 0
      ? 'Le montant doit être supérieur à zéro.'
      : null;

  bool get _modifie => _montantValue != widget.montant || _date != widget.date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _EditorShell(
      title: 'Modifier le prélèvement',
      subtitle:
          'Enregistré le ${Fmt.numericDate(widget.date)} '
          'à ${Fmt.hour(widget.date)}',
      accent: t.drawing,
      blocage: _blocage,
      canSave: _modifie,
      onSave: () => Navigator.of(
        context,
      ).pop(PrelevementEdit(montant: _montantValue, date: _date)),
      fields: [
        _LabelledField(
          label: 'Montant (Ar)',
          child: _IntegerField(
            controller: _montant,
            autofocus: true,
            onChanged: () => setState(() {}),
          ),
        ),
        const SizedBox(height: 14),
        _DateTimeField(
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 14),
        // Le mois porte le filtre de l'écran : changer la date déplace la
        // ligne d'un onglet à l'autre, autant l'annoncer.
        _Preview(
          label: 'Rattaché au mois',
          value: Fmt.cap(Fmt.month(_date)),
          color: t.drawing,
          note: _blocage == null ? Fmt.ar(_montantValue) : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────── Charge mens. ───────────────────────────────

class _ChargeDialog extends StatefulWidget {
  const _ChargeDialog({
    required this.libelle,
    required this.prixUnitaire,
    required this.quantite,
    required this.mois,
    required this.dateEnregistrement,
    required this.categorie,
    required this.suggestions,
  });

  final String? libelle;
  final int? prixUnitaire;
  final int? quantite;
  final DateTime mois;

  /// Libellés déjà employés en base, proposés pendant la frappe, avec ce
  /// qu'ils valaient la dernière fois.
  final List<ChargeSuggestion> suggestions;
  final DateTime? dateEnregistrement;

  /// Catégorie déjà choisie, ou `null` : ni choix antérieur, ni création.
  final String? categorie;

  bool get creation => libelle == null;

  @override
  State<_ChargeDialog> createState() => _ChargeDialogState();
}

class _ChargeDialogState extends State<_ChargeDialog> {
  late final _libelle = _InlineCompletionController()
    ..text = widget.libelle ?? '';
  late final _prix = TextEditingController(
    text: widget.prixUnitaire == null ? '' : '${widget.prixUnitaire}',
  );
  // Une charge sans quantité est une charge d'une unité : le champ part à 1
  // plutôt que vide, pour que le loyer se saisisse sans y toucher.
  late final _qte = TextEditingController(text: '${widget.quantite ?? 1}');
  late DateTime _mois = DateTime(widget.mois.year, widget.mois.month);

  /// À la création, l'enregistrement est daté d'aujourd'hui — la valeur juste
  /// dans l'immense majorité des cas, et corrigeable pour les autres.
  /// Sans heure : c'est un jour de règlement, pas un horodatage.
  late DateTime _date = _jour(widget.dateEnregistrement ?? DateTime.now());

  static DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Catégorie retenue par l'utilisateur. Tant qu'elle est nulle, l'affichage
  /// suit le libellé au fil de la frappe ; dès qu'une puce est cliquée, le
  /// choix est figé et le libellé ne le rattrape plus.
  late String? _categorie = widget.categorie;

  String get _categorieValue =>
      CategoryRules.resolveCharge(_categorie, _libelleValue);

  /// Vrai tant que la catégorie affichée n'est qu'une proposition.
  bool get _categorieDeduite => _categorie == null;

  @override
  void dispose() {
    for (final c in [_libelle, _prix, _qte]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Longueur précédente du libellé, pour distinguer une frappe d'un effacement.
  late int _libelleAvant = (widget.libelle ?? '').length;

  /// Recalcule la complétion grisée après chaque frappe.
  ///
  /// Rien après un effacement : reproposer ce que l'utilisateur vient de
  /// retirer l'empêcherait de corriger sa saisie, la fin du mot repoussant
  /// chaque caractère supprimé.
  void _majCompletion() {
    final t = _libelle.text;
    final efface = t.length < _libelleAvant;
    _libelleAvant = t.length;
    _inline = efface ? null : _suggestionPour(t);
    _libelle.propose(_inline?.libelle);
  }

  /// La proposition affichée en gris, retenue pour que Tab reprenne aussi son
  /// prix et non le seul libellé.
  ChargeSuggestion? _inline;

  /// Ce que la frappe en cours rappelle en base. Rien tant que le champ est
  /// vide — ouvrir le formulaire sur deux cents libellés n'aiderait personne —
  /// et rien non plus quand la saisie tombe déjà pile sur une proposition.
  /// Le libellé connu que la frappe en cours prolonge, s'il y en a un.
  ///
  /// Un préfixe, et rien d'autre : une proposition qui ne commencerait pas par
  /// ce qui est tapé ne pourrait pas s'afficher à sa suite. Rien non plus tant
  /// que le champ est vide, ni quand la saisie tombe déjà pile dessus.
  ChargeSuggestion? _suggestionPour(String saisie) {
    final q = saisie.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final s in widget.suggestions) {
      final b = s.libelle.toLowerCase();
      if (b == q) return null;
      if (b.startsWith(q)) return s;
    }
    return null;
  }

  /// Reprend ce que la proposition valait la dernière fois.
  ///
  /// Le prix et la quantité écrasent ce qui était déjà saisi : accepter une
  /// proposition, c'est demander la ligne précédente en entier, et un prix
  /// resté sur une autre valeur serait un piège. Les deux vont ensemble — le
  /// prix des ramettes sans leurs douze unités donnerait un total faux.
  ///
  /// La catégorie fait exception quand elle a été choisie à la main : c'est un
  /// geste délibéré, que la frappe du libellé ne doit pas défaire.
  void _appliquer(ChargeSuggestion s) {
    if (s.prixUnitaire != null) _prix.text = '${s.prixUnitaire}';
    _qte.text = '${s.quantite}';
    _categorie ??= s.categorie;
  }

  String get _libelleValue => _libelle.text.trim();
  int get _prixValue => int.tryParse(_prix.text.trim()) ?? 0;
  /// Un champ de quantité laissé vide vaut une unité : c'est le cas du loyer
  /// et des factures, qui ne se comptent pas. Seul un zéro saisi bloque.
  int get _qteValue {
    final t = _qte.text.trim();
    return t.isEmpty ? 1 : (int.tryParse(t) ?? 0);
  }

  int get _totalValue => _prixValue * _qteValue;

  String? get _blocage {
    if (_libelleValue.isEmpty) return 'Le libellé ne peut pas être vide.';
    if (_prixValue <= 0) return 'Le prix unitaire doit être supérieur à zéro.';
    if (_qteValue < 1) return 'La quantité doit être au moins 1.';
    return null;
  }

  bool get _modifie =>
      widget.creation ||
      _libelleValue != widget.libelle ||
      _prixValue != widget.prixUnitaire ||
      _qteValue != (widget.quantite ?? 1) ||
      _mois != DateTime(widget.mois.year, widget.mois.month) ||
      widget.dateEnregistrement == null ||
      _date != _jour(widget.dateEnregistrement!) ||
      _categorieValue != CategoryRules.resolveCharge(widget.categorie, widget.libelle ?? '');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date d\'enregistrement',
    );
    if (picked == null) return;
    setState(() => _date = _jour(picked));
  }

  Future<void> _pickMois() async {
    // Flutter n'offre pas de sélecteur de mois : on ouvre le calendrier sur
    // l'année et on ne retient que l'année et le mois du jour choisi.
    final picked = await showDatePicker(
      context: context,
      initialDate: _mois,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
      locale: const Locale('fr', 'FR'),
      helpText: 'Mois d\'imputation',
    );
    if (picked == null) return;
    setState(() => _mois = DateTime(picked.year, picked.month));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return _EditorShell(
      title: widget.creation ? 'Nouvelle charge' : 'Modifier la charge',
      subtitle: 'Imputée au mois entier · jamais au jour ni à la semaine',
      accent: t.charge,
      blocage: _blocage,
      canSave: _modifie,
      onSave: () => Navigator.of(context).pop(
        ChargeEdit(
          libelle: _libelleValue,
          prixUnitaire: _prixValue,
          quantite: _qteValue,
          mois: _mois,
          dateEnregistrement: _date,
          // On enregistre ce qui est à l'écran, choix explicite ou simple
          // proposition acceptée : une charge relue plus tard doit retrouver
          // sa catégorie même si les mots-clés changent entre-temps.
          categorie: _categorieValue,
        ),
      ),
      fields: [
        _LabelledField(
          label: 'Libellé',
          // Pas de liste déroulée sous le champ : la complétion se lit en
          // gris à la suite de la frappe, et Tab l'accepte.
          child: Focus(
            // Le Focus est un ancêtre du champ : posées sur son propre nœud,
            // ces touches seraient déjà consommées par l'édition de texte.
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent || _libelle.reste.isEmpty) {
                return KeyEventResult.ignored;
              }
              final k = event.logicalKey;
              if (k == LogicalKeyboardKey.tab ||
                  k == LogicalKeyboardKey.arrowRight) {
                setState(() {
                  final s = _inline;
                  _libelle.accept();
                  _libelleAvant = _libelle.text.length;
                  if (s != null) _appliquer(s);
                  _inline = null;
                });
                return KeyEventResult.handled;
              }
              if (k == LogicalKeyboardKey.escape) {
                setState(() {
                  _libelle.propose(null);
                  _inline = null;
                });
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: _libelle,
              autofocus: true,
              style: context.texts.body,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(_majCompletion),
              decoration: const InputDecoration(
                hintText: 'Ex. Loyer, Facture JIRAMA, Fournitures bureau',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _LabelledField(
                label: 'Prix unitaire (Ar)',
                child: _IntegerField(
                  controller: _prix,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabelledField(
                label: 'Quantité',
                child: _IntegerField(
                  controller: _qte,
                  hint: '1',
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _LabelledField(
          label: 'Mois imputé',
          child: _PickerButton(
            icon: Icons.event_repeat_outlined,
            label: Fmt.cap(Fmt.month(_mois)),
            onTap: _pickMois,
          ),
        ),
        const SizedBox(height: 14),
        // Deux dates, deux rôles : le mois ci-dessus décide du cadrage où la
        // charge est comptée, celle-ci ne fait que dater la saisie.
        _LabelledField(
          label: 'Enregistrée le',
          child: _PickerButton(
            icon: Icons.calendar_today_outlined,
            label: Fmt.cap(Fmt.longDate(_date)),
            onTap: _pickDate,
          ),
        ),
        const SizedBox(height: 14),
        // Le total est calculé, jamais saisi : le montrer évite de multiplier
        // de tête pour vérifier ce qui partira dans le solde du mois.
        _Preview(
          label: 'Total imputé au mois',
          value: _blocage != null ? '—' : Fmt.ar(_totalValue),
          color: t.charge,
          note: _blocage != null || _qteValue == 1
              ? null
              : '${Fmt.num(_prixValue)} × $_qteValue',
        ),
        const SizedBox(height: 14),
        _LabelledField(
          label: _categorieDeduite
              ? 'Catégorie · proposée d\'après le libellé'
              : 'Catégorie · choisie',
          child: _CategoryDropdown(
            selected: _categorieValue,
            onChanged: (c) => setState(() => _categorie = c),
          ),
        ),
        // Un règlement en retard ou par avance est courant : on le signale
        // pour qu'il soit voulu, jamais on ne le corrige.
        if (_date.year != _mois.year || _date.month != _mois.month) ...[
          const SizedBox(height: 12),
          Text(
            'Enregistrée en ${Fmt.month(_date)}, imputée à '
            '${Fmt.month(_mois)} — le solde de ${Fmt.cap(Fmt.monthShort(_mois))} '
            'la comptera.',
            style: context.texts.caption.copyWith(height: 1.5),
          ),
        ],
      ],
    );
  }
}

/// Contrôleur qui affiche la fin d'un libellé connu en gris, à la suite de ce
/// qui est tapé — le « texte fantôme » de Copilot ou de la barre de recherche.
///
/// La complétion n'entre jamais dans [text] : tant qu'elle n'est pas acceptée,
/// elle n'existe pas pour le formulaire, qui ne validera donc jamais un libellé
/// que personne n'a voulu. C'est la différence avec la complétion par sélection
/// des navigateurs, où le texte proposé fait déjà partie de la valeur.
class _InlineCompletionController extends TextEditingController {
  String _suggestion = '';

  /// Libellé complet proposé, ou vide. Retenu en entier plutôt que par son
  /// suffixe : accepter « fact » doit rendre « Facture JIRAMA », avec sa
  /// majuscule d'origine, et non « facture JIRAMA ».
  String get suggestion => _suggestion;

  /// La part restant à taper, celle qui s'affiche en gris.
  String get reste {
    if (_suggestion.isEmpty || _suggestion.length <= text.length) return '';
    return _suggestion.substring(text.length);
  }

  /// Retient un libellé s'il prolonge vraiment la frappe. Tout le reste — une
  /// casse qui ne correspond pas, un texte vide, une proposition déjà tapée en
  /// entier — efface la complétion plutôt que d'en afficher une trompeuse.
  void propose(String? libelle) {
    final t = text;
    final valide =
        libelle != null &&
        t.isNotEmpty &&
        libelle.length > t.length &&
        libelle.toLowerCase().startsWith(t.toLowerCase());
    final next = valide ? libelle : '';
    if (next == _suggestion) return;
    _suggestion = next;
    notifyListeners();
  }

  /// Écrit la proposition dans le champ et place le curseur au bout.
  void accept() {
    if (reste.isEmpty) return;
    final v = _suggestion;
    _suggestion = '';
    value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = super.buildTextSpan(
      context: context,
      style: style,
      withComposing: withComposing,
    );
    // Rien de gris quand le curseur n'est pas au bout : la complétion se lit
    // comme une suite du texte, elle n'aurait aucun sens au milieu d'un mot.
    final auBout =
        selection.isCollapsed && selection.baseOffset == text.length;
    if (reste.isEmpty || !auBout) return base;
    return TextSpan(
      style: style,
      children: [
        base,
        TextSpan(
          text: reste,
          style: (style ?? const TextStyle()).copyWith(
            color: context.tokens.faint,
          ),
        ),
      ],
    );
  }
}

/// Les catégories en liste déroulante, au gabarit des autres champs du
/// formulaire : même hauteur, même bordure, même rayon que [_PickerButton],
/// pour que la ligne ne se désaligne pas.
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    // `DropdownButton` exige que sa valeur figure parmi ses entrées, sous
    // peine d'assertion. Une charge enregistrée sous une catégorie retirée
    // depuis de `CategoryRules` ouvrirait donc sur un plantage : on lui rend
    // son entrée plutôt que d'écraser en silence ce qui a été choisi.
    final options = [
      ...CategoryRules.chargeCategories,
      if (!CategoryRules.chargeCategories.contains(selected)) selected,
    ];

    return ConstrainedBox(
      // Plancher et non hauteur imposée : à texte agrandi, le champ grandit
      // au lieu de rogner son contenu.
      constraints: const BoxConstraints(minHeight: 39),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: t.brSmall,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selected,
            isExpanded: true,
            isDense: true,
            borderRadius: t.brSmall,
            dropdownColor: t.surface,
            focusColor: Colors.transparent,
            icon: Icon(Icons.expand_more, size: 16, color: t.faint),
            style: x.body,
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            items: [
              for (final c in options)
                DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      // La pastille reprend le code couleur du tableau de
                      // bord : la catégorie se reconnaît avant de se lire.
                      KindDot(categoryColor(context, c), size: 6),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          c,
                          style: x.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────── Relevé élec. ───────────────────────────────

class _ReleveDialog extends StatefulWidget {
  const _ReleveDialog({
    required this.compteur,
    required this.sousCompteur,
    required this.date,
  });

  final double compteur;
  final double sousCompteur;
  final DateTime date;

  @override
  State<_ReleveDialog> createState() => _ReleveDialogState();
}

class _ReleveDialogState extends State<_ReleveDialog> {
  late final _compteur = TextEditingController(text: _text(widget.compteur));
  late final _sous = TextEditingController(text: _text(widget.sousCompteur));
  late DateTime _date = widget.date;

  /// 22160 plutôt que 22160.0 : la saisie doit ressembler à ce qu'on lit
  /// sur le compteur.
  static String _text(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  void dispose() {
    _compteur.dispose();
    _sous.dispose();
    super.dispose();
  }

  static double? _parse(TextEditingController c) =>
      double.tryParse(c.text.replaceAll(',', '.').trim());

  double? get _compteurValue => _parse(_compteur);
  double? get _sousValue => _parse(_sous);

  String? get _blocage {
    final g = _compteurValue, s = _sousValue;
    if (g == null || s == null) return 'Les deux index doivent être renseignés.';
    if (g <= 0 || s < 0) return 'Un index de compteur ne peut pas être négatif.';
    if (s > g) {
      return 'Le sous-compteur dépasse le compteur général — vérifiez la saisie.';
    }
    return null;
  }

  bool get _modifie =>
      _compteurValue != widget.compteur ||
      _sousValue != widget.sousCompteur ||
      _date != widget.date;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return _EditorShell(
      title: 'Modifier le relevé',
      subtitle: 'Relevé du ${Fmt.numericDate(widget.date)}',
      accent: t.electric,
      blocage: _blocage,
      canSave: _modifie,
      onSave: () => Navigator.of(context).pop(
        ReleveEdit(
          compteur: _compteurValue!,
          sousCompteur: _sousValue!,
          date: _date,
        ),
      ),
      fields: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _LabelledField(
                label: 'Compteur général',
                child: _DecimalField(
                  controller: _compteur,
                  autofocus: true,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LabelledField(
                label: 'Sous-compteur',
                child: _DecimalField(
                  controller: _sous,
                  onChanged: () => setState(() {}),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DateTimeField(
          value: _date,
          onChanged: (d) => setState(() => _date = d),
        ),
        const SizedBox(height: 14),
        // Pas de total à afficher : la consommation n'est pas dans la ligne,
        // elle se calcule par différence avec le relevé voisin. Corriger un
        // index rejoue donc les deux périodes qui l'encadrent.
        Text(
          'La consommation n\'est pas stockée : corriger cet index recalcule '
          'les deux périodes voisines, et les partages JIRO qui s\'y appuient.',
          style: context.texts.caption.copyWith(height: 1.5),
        ),
      ],
    );
  }
}

// ──────────────────────────── Pièces communes ────────────────────────────

/// Coquille des deux formulaires : même largeur, même pied, même message
/// de blocage. Les écrans ne diffèrent que par leurs champs.
class _EditorShell extends StatefulWidget {
  const _EditorShell({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.fields,
    required this.canSave,
    required this.onSave,
    this.blocage,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final List<Widget> fields;

  /// Y a-t-il quelque chose à enregistrer ? Ne dit rien de la validité : un
  /// formulaire fautif garde son bouton actif, c'est le clic qui révèle la
  /// raison du refus.
  final bool canSave;
  final VoidCallback onSave;

  /// Raison pour laquelle la saisie n'est pas enregistrable, s'il y en a une.
  final String? blocage;

  @override
  State<_EditorShell> createState() => _EditorShellState();
}

class _EditorShellState extends State<_EditorShell> {
  /// L'enregistrement a-t-il déjà été tenté ? Avant cela, rien n'est signalé :
  /// reprocher un champ vide à quelqu'un qui n'a pas fini de le remplir est
  /// une remontrance, pas une aide. Une fois la tentative faite, le message
  /// suit la correction en direct.
  bool _tente = false;

  void _enregistrer() {
    if (widget.blocage != null) {
      setState(() => _tente = true);
      return;
    }
    widget.onSave();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    final blocage = _tente ? widget.blocage : null;

    return AlertDialog(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: t.br),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      title: Row(
        children: [
          KindDot(widget.accent, size: 8),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: x.cardTitle),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  style: x.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ...widget.fields,
              if (blocage != null) ...[
                const SizedBox(height: 12),
                Text(
                  blocage,
                  style: x.caption.copyWith(color: t.danger, height: 1.5),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Annuler', style: TextStyle(color: t.muted)),
        ),
        FilledButton(
          // Actif même sur un formulaire fautif : c'est le clic qui
          // révèle la raison du refus.
          onPressed: widget.canSave ? _enregistrer : null,
          style: FilledButton.styleFrom(
            backgroundColor: t.accent,
            disabledBackgroundColor: t.surfaceAlt,
            disabledForegroundColor: t.faint,
            shape: RoundedRectangleBorder(borderRadius: t.brSmall),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          ),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label.toUpperCase(), style: context.texts.overline),
      const SizedBox(height: 6),
      child,
    ],
  );
}

/// Montants et quantités : entiers nus, comme en base. Le séparateur de
/// milliers est un affichage, pas une saisie.
class _IntegerField extends StatelessWidget {
  const _IntegerField({
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
    this.hint,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool autofocus;

  /// Valeur retenue quand le champ reste vide, montrée en gris. N'a de sens
  /// que là où le vide est permis — la quantité d'une charge.
  final String? hint;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    style: context.texts.monoBody,
    textAlign: TextAlign.right,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    // Toujours une décoration, même sans indication : un `null` ici ne veut
    // pas dire « celle par défaut » mais « aucune », et le champ perdrait la
    // bordure, le fond et le padding que lui donne `inputDecorationTheme`.
    decoration: InputDecoration(hintText: hint),
    onChanged: (_) => onChanged(),
  );
}

/// Index de compteur : réel, saisi avec la virgule ou le point.
class _DecimalField extends StatelessWidget {
  const _DecimalField({
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    style: context.texts.monoBody,
    textAlign: TextAlign.right,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
    onChanged: (_) => onChanged(),
  );
}

/// Date et heure côte à côte : une faute de frappe porte parfois sur le jour,
/// et l'heure sert de repère dans la liste groupée.
class _DateTimeField extends StatelessWidget {
  const _DateTimeField({required this.value, required this.onChanged});
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2015),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      locale: const Locale('fr', 'FR'),
    );
    if (picked == null) return;
    onChanged(
      DateTime(
        picked.year,
        picked.month,
        picked.day,
        value.hour,
        value.minute,
        value.second,
      ),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
      builder: (context, child) => MediaQuery(
        // Saisie 24 h : l'app n'affiche jamais d'AM/PM.
        data: MediaQuery.of(
          context,
        ).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    onChanged(
      DateTime(
        value.year,
        value.month,
        value.day,
        picked.hour,
        picked.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: _LabelledField(
          label: 'Date',
          child: _PickerButton(
            icon: Icons.calendar_today_outlined,
            label: Fmt.cap(Fmt.longDate(value)),
            onTap: () => _pickDate(context),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _LabelledField(
          label: 'Heure',
          child: _PickerButton(
            icon: Icons.schedule,
            label: Fmt.hour(value),
            onTap: () => _pickTime(context),
          ),
        ),
      ),
    ],
  );
}

/// Un champ qui n'accepte pas la frappe : même hauteur et même bordure que
/// les TextField voisins, pour que la ligne ne se désaligne pas.
class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      borderRadius: t.brSmall,
      child: Container(
        height: 39,
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line),
          borderRadius: t.brSmall,
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: t.faint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: context.texts.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ce que la saisie produira une fois enregistrée — total recalculé ou
/// catégorie déduite. Lecture seule.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.label,
    required this.value,
    required this.color,
    this.note,
  });

  final String label;
  final String value;
  final Color color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: t.brSmall,
        border: Border.all(color: t.line),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: x.bodyMuted)),
          if (note != null) ...[
            Text(note!, style: x.monoFaint),
            const SizedBox(width: 10),
          ],
          Text(
            value,
            style: x.monoBody.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

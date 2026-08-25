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
      canSave: _blocage == null && _modifie,
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
      canSave: _blocage == null && _modifie,
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
      canSave: _blocage == null && _modifie,
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
      canSave: _blocage == null && _modifie,
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
class _EditorShell extends StatelessWidget {
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
  final bool canSave;
  final VoidCallback onSave;

  /// Raison pour laquelle la saisie n'est pas enregistrable, s'il y en a une.
  final String? blocage;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return AlertDialog(
      backgroundColor: t.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: t.br),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      title: Row(
        children: [
          KindDot(accent, size: 8),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: x.cardTitle),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
              ...fields,
              if (blocage != null) ...[
                const SizedBox(height: 12),
                Text(
                  blocage!,
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
          onPressed: canSave ? onSave : null,
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
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

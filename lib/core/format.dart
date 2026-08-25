// `Fmt.num` masque le type `num` à l'intérieur de la classe : on garde un alias
// vers dart:core pour pouvoir continuer à typer les paramètres.
import 'dart:core';
import 'dart:core' as core;

import 'package:intl/intl.dart';

/// Formatage Ariary / dates. Une seule source de vérité : si un montant
/// s'affiche sans séparateur ou sans « Ar » quelque part, c'est un oubli d'appel.
class Fmt {
  Fmt._();

  static const _fr = 'fr_FR';
  static final _int = NumberFormat.decimalPattern(_fr);
  static final _dec1 = NumberFormat('#,##0.0', _fr);

  /// 76 200 — nombre nu, pour les cellules de tableau.
  static String num(core.num v) => _int.format(v.round());

  /// 402,1 — un décimal, mais seulement quand il y en a un.
  static String dec(core.num v) =>
      v == v.roundToDouble() ? _int.format(v.round()) : _dec1.format(v);

  /// 76 200 Ar — partout où l'unité n'est pas déjà dans l'en-tête.
  static String ar(core.num v) => '${_int.format(v.round())} Ar';

  /// Solde négatif avec le signe moins typographique.
  static String arSigned(core.num v) =>
      '${v < 0 ? '−' : ''}${_int.format(v.abs().round())} Ar';

  /// 402,1 kWh
  static String kwh(core.num v) => '${_dec1.format(v)} kWh';

  /// Axes de graphiques uniquement : 1,2M / 76K.
  static String compact(core.num v) {
    final a = v.abs();
    if (a >= 1e6) {
      return '${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')}M';
    }
    if (a >= 1e3) return '${(v / 1e3).round()}K';
    return v.round().toString();
  }

  /// vendredi 21 août 2026
  static String longDate(DateTime d) =>
      DateFormat('EEEE d MMMM y', _fr).format(d);

  /// 21 août
  static String shortDate(DateTime d) => DateFormat('d MMM', _fr).format(d);

  /// 21/08/2026
  static String numericDate(DateTime d) => DateFormat('dd/MM/y', _fr).format(d);

  /// août 2026
  static String month(DateTime d) => DateFormat('MMMM y', _fr).format(d);

  /// août — sans l'année, pour les segments de mois.
  static String monthShort(DateTime d) => DateFormat('MMMM', _fr).format(d);

  /// 07h28 — l'heure d'une opération, jamais 7:28 AM.
  static String hour(DateTime d) => DateFormat("HH'h'mm", _fr).format(d);

  static String cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Les quatre natures de flux. La distinction est sémantique avant d'être
/// colorée : un prélèvement n'est pas une dépense.
enum FlowKind { income, expense, drawing, electric }

/// Période de cadrage du dashboard.
enum Period {
  day('Jour'),
  week('Semaine'),
  month('Mois');

  const Period(this.label);
  final String label;
}

/// Modèles de lecture. L'application ne crée aucune donnée : ces objets sont
/// hydratés depuis SQLite après import d'une sauvegarde .enc. Seule la facture
/// JIRO est produite par l'app.
///
/// Les tables Drift (`Operation`, `Depense`, `Prelevement`, `Releve`) restent la
/// source ; ce fichier ne décrit que ce que les écrans manipulent.
library;

/// Relevé électrique, projeté depuis la table `Releves`.
class ReleveElectricite {
  const ReleveElectricite({
    required this.id,
    required this.date,
    required this.compteur,
    required this.sousCompteur,
  });

  final String id;
  final DateTime date;

  /// Index du compteur général. Réel en base : les relevés ne sont pas entiers.
  final double compteur;
  final double sousCompteur;
}

/// Catégorisation des dépenses. La base ne stocke pas de catégorie :
/// on la dérive du libellé par mots-clés, avec « Divers » en repli.
class CategoryRules {
  static const fallback = 'Divers';

  static const Map<String, List<String>> _rules = {
    'Papier': ['ramette', 'papier', 'a4', 'a3'],
    'Consommables': [
      'toner',
      'cartouche',
      'encre',
      'spirale',
      'pochette',
      'couverture',
      'plastification',
    ],
    'Maintenance': [
      'maintenance',
      'réparation',
      'reparation',
      'entretien',
      'outillage',
      'pièce',
      'piece',
    ],
    'Électricité': [
      'jirama',
      'jiro',
      'électricité',
      'electricite',
      'groupe électrogène',
      'carburant',
    ],
    'Internet': ['internet', 'forfait', 'crédit', 'credit', 'téléphone'],
    'Salaires': ['salaire', 'journalier', 'opérateur', 'operateur'],
    'Loyer': ['loyer'],
  };

  static String of(String libelle) {
    final l = libelle.toLowerCase();
    for (final e in _rules.entries) {
      if (e.value.any(l.contains)) return e.key;
    }
    return fallback;
  }

  static const all = [
    'Papier',
    'Consommables',
    'Maintenance',
    'Électricité',
    'Internet',
    'Salaires',
    'Loyer',
    fallback,
  ];
}

/// Totaux d'une période, avec le solde net que l'ancienne app n'affichait pas.
class PeriodTotals {
  const PeriodTotals({
    required this.entrant,
    required this.sortant,
    required this.prelevement,
    required this.nbOperations,
    required this.nbDepenses,
    required this.nbPrelevements,
  });

  final int entrant;
  final int sortant;
  final int prelevement;
  final int nbOperations;
  final int nbDepenses;
  final int nbPrelevements;

  int get soldeNet => entrant - sortant - prelevement;

  static const empty = PeriodTotals(
    entrant: 0,
    sortant: 0,
    prelevement: 0,
    nbOperations: 0,
    nbDepenses: 0,
    nbPrelevements: 0,
  );
}

/// Résolution d'un sous-compteur pour le partage JIRO.
enum SubMeterState {
  /// Un relevé porte exactement cet index.
  exact('Relevé exact'),

  /// Valeur interpolée linéairement entre deux relevés encadrants.
  interpolated('Interpolé'),

  /// Hors plage ou index absent — validation bloquée.
  unresolved('Non résolu');

  const SubMeterState(this.label);
  final String label;
}

class SubMeterResolution {
  const SubMeterResolution(
    this.state, {
    this.value,
    this.date,
    required this.message,
  });

  final SubMeterState state;
  final double? value;

  /// Date du relevé exact, ou date interpolée : c'est elle qui est enregistrée
  /// comme date d'index sur la facture JIRO.
  final DateTime? date;
  final String message;

  bool get ok => state != SubMeterState.unresolved;
}

/// Cherche le sous-compteur correspondant à un index de compteur général.
/// Interpole entre les deux relevés encadrants quand l'index n'existe pas ;
/// hors plage, la résolution échoue plutôt que d'extrapoler.
SubMeterResolution resolveSubMeter(
  double? index,
  List<ReleveElectricite> releves, {
  String Function(DateTime)? dateLabel,
}) {
  final fmt = dateLabel ?? (d) => '${d.day}/${d.month}';
  if (index == null || index <= 0) {
    return const SubMeterResolution(
      SubMeterState.unresolved,
      message: 'Index non renseigné',
    );
  }
  final r = [...releves]..sort((a, b) => a.compteur.compareTo(b.compteur));
  if (r.isEmpty) {
    return const SubMeterResolution(
      SubMeterState.unresolved,
      message: 'Aucun relevé en base',
    );
  }

  for (final x in r) {
    // Tolérance : les index sont réels, l'égalité stricte n'a pas de sens.
    if ((x.compteur - index).abs() < 0.01) {
      return SubMeterResolution(
        SubMeterState.exact,
        value: x.sousCompteur,
        date: x.date,
        message: 'Relevé du ${fmt(x.date)}',
      );
    }
  }
  if (index < r.first.compteur || index > r.last.compteur) {
    return SubMeterResolution(
      SubMeterState.unresolved,
      message:
          'Hors plage des relevés '
          '(${r.first.compteur.round()}–${r.last.compteur.round()})',
    );
  }
  for (var i = 0; i < r.length - 1; i++) {
    final a = r[i], b = r[i + 1];
    if (index > a.compteur && index < b.compteur) {
      final ratio = (index - a.compteur) / (b.compteur - a.compteur);
      final millis = b.date.difference(a.date).inMilliseconds;
      return SubMeterResolution(
        SubMeterState.interpolated,
        value: a.sousCompteur + ratio * (b.sousCompteur - a.sousCompteur),
        date: a.date.add(Duration(milliseconds: (millis * ratio).round())),
        message: 'Interpolé · ${fmt(a.date)} → ${fmt(b.date)}',
      );
    }
  }
  return const SubMeterResolution(
    SubMeterState.unresolved,
    message: 'Non résolu',
  );
}

/// Facture JIRAMA saisie, puis répartie entre les deux occupants.
///
/// La répartition suit la règle métier déjà en base (`FactureJiroModel`) :
/// chaque occupant paie sa consommation au prix du kWh, et **la moitié** de
/// chacun des postes fixes — redevance, prime fixe, taxes et TVA. La TVA est
/// donc un montant facturé, pas un taux.
class JiroBill {
  const JiroBill({
    required this.indexPrecedent,
    required this.indexActuel,
    required this.prixKwh,
    required this.redevance,
    required this.primeFixe,
    required this.taxes,
    required this.tva,
  });

  final double indexPrecedent;
  final double indexActuel;
  final double prixKwh;
  final double redevance;
  final double primeFixe;
  final double taxes;
  final double tva;

  double get consoTotale => indexActuel - indexPrecedent;
  double get fraisFixes => redevance + primeFixe + taxes + tva;

  /// Conso 1 = différence des sous-compteurs. Conso 2 = le reste.
  JiroShare shareFor(double conso) {
    final variable = conso * prixKwh;
    return JiroShare(
      conso: conso,
      variable: variable,
      redevance: redevance / 2,
      primeFixe: primeFixe / 2,
      taxes: taxes / 2,
      tva: tva / 2,
    );
  }

  double get totalFacture => consoTotale * prixKwh + fraisFixes;
}

class JiroShare {
  const JiroShare({
    required this.conso,
    required this.variable,
    required this.redevance,
    required this.primeFixe,
    required this.taxes,
    required this.tva,
  });

  final double conso;
  final double variable;
  final double redevance;
  final double primeFixe;
  final double taxes;
  final double tva;

  double get sousTotal => variable + redevance + primeFixe + taxes;
  double get total => sousTotal + tva;
}

/// Partage déjà généré, tel qu'affiché dans l'historique de l'écran JIRO.
class JiroSharing {
  const JiroSharing({
    required this.id,
    required this.periode,
    required this.indexPrecedent,
    required this.indexActuel,
    required this.conso1,
    required this.conso2,
    required this.part1,
    required this.part2,
    required this.total,
    required this.genereLe,
  });

  final String id;
  final String periode;
  final double indexPrecedent;
  final double indexActuel;
  final double conso1;
  final double conso2;
  final double part1;
  final double part2;
  final double total;
  final DateTime genereLe;
}

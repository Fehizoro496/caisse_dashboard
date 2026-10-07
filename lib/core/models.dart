/// Modèles de lecture. La caisse elle-même — opérations, dépenses,
/// prélèvements, relevés — n'est jamais créée ici : ces objets sont hydratés
/// depuis SQLite après import d'une sauvegarde .enc. Deux exceptions, toutes
/// deux saisies dans l'app : la facture JIRO et les charges mensuelles.
///
/// Les tables Drift (`Operation`, `Depense`, `Prelevement`, `Releve`, `Charge`)
/// restent la source ; ce fichier ne décrit que ce que les écrans manipulent.
library;

import 'package:caisse_dashboard/core/format.dart' show Period;

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

/// Catégorisation par mots-clés, avec « Divers » en repli.
///
/// Deux jeux distincts, et c'est voulu : une dépense se classe parmi huit
/// familles dérivées de son libellé, jamais stockées ; une charge se classe
/// parmi cinq, et son choix est enregistré. Les règles des dépenses ne
/// s'appliquent donc pas aux charges — voir [ofCharge].
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
    'Loyer': ['loyer', 'bail', 'charges locatives'],
    'Fournitures': ['fourniture', 'bureau', 'nettoyage', 'eau'],
  };

  static String of(String libelle) {
    final l = libelle.toLowerCase();
    for (final e in _rules.entries) {
      if (e.value.any(l.contains)) return e.key;
    }
    return fallback;
  }

  // ── Charges
  // Les charges ont leur propre jeu, plus court : une charge est un loyer,
  // une facture, des fournitures ou de la maintenance — les huit familles des
  // dépenses n'auraient pas de sens ici. « Facture » y remplace à elle seule
  // Électricité et Internet.

  static const chargeCategories = [
    'Fournitures',
    'Loyer',
    'Facture',
    'Maintenance',
    fallback,
  ];

  static const Map<String, List<String>> _chargeRules = {
    'Loyer': ['loyer', 'bail', 'charges locatives'],
    'Facture': [
      'facture',
      'jirama',
      'jiro',
      'électricité',
      'electricite',
      'internet',
      'fibre',
      'abonnement',
      'forfait',
      'téléphone',
      'telephone',
    ],
    'Maintenance': [
      'maintenance',
      'réparation',
      'reparation',
      'entretien',
      'outillage',
    ],
    'Fournitures': [
      'fourniture',
      'bureau',
      'nettoyage',
      'papier',
      'ramette',
      'consommable',
      'toner',
      'cartouche',
      'encre',
    ],
  };

  /// Catégorie proposée pour une charge. Volontairement sans mot-clé « eau » :
  /// la recherche est une sous-chaîne, et « bureau » le contient — la facture
  /// d'eau est déjà couverte par « facture ».
  static String ofCharge(String libelle) {
    final l = libelle.toLowerCase();
    for (final e in _chargeRules.entries) {
      if (e.value.any(l.contains)) return e.key;
    }
    return fallback;
  }

  /// Catégorie retenue pour une charge : le choix de la saisie s'il existe,
  /// sinon la déduction par mots-clés. Un choix explicite ne bouge plus, même
  /// si le libellé est corrigé ensuite — c'est tout l'intérêt de l'avoir fait.
  static String resolveCharge(String? choisie, String libelle) {
    final c = choisie?.trim();
    return c == null || c.isEmpty ? ofCharge(libelle) : c;
  }

  static const all = [
    'Papier',
    'Consommables',
    'Maintenance',
    'Électricité',
    'Internet',
    'Salaires',
    'Loyer',
    'Fournitures',
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
    this.charges = 0,
    this.nbCharges = 0,
  });

  final int entrant;
  final int sortant;
  final int prelevement;
  final int nbOperations;
  final int nbDepenses;
  final int nbPrelevements;

  /// Charges du mois. Vaut 0 hors cadrage Mois — une charge n'a pas de jour,
  /// elle ne peut donc être imputée ni à un jour ni à une semaine. Vaut 0
  /// aussi quand l'utilisateur les exclut depuis le tableau de bord ; d'où le
  /// défaut, qui est l'état normal des deux tiers des cadrages.
  final int charges;
  final int nbCharges;

  /// Solde après charges. La conséquence assumée : sur un mois chargé,
  /// `soldeNet` du mois ne vaut plus la somme des `soldeNet` de ses jours.
  int get soldeNet => entrant - sortant - prelevement - charges;

  int get prelevementCalcule => entrant - sortant;
  int get ecartPrelevement => prelevement - prelevementCalcule;

  /// Le prélèvement réellement saisi est la référence du résultat mensuel.
  int soldeNetPour(Period period) =>
      period == Period.month ? prelevement - charges : soldeNet;

  static const empty = PeriodTotals(
    entrant: 0,
    sortant: 0,
    prelevement: 0,
    nbOperations: 0,
    nbDepenses: 0,
    nbPrelevements: 0,
  );
}

/// Un libellé déjà employé, avec ce qu'il valait la dernière fois.
///
/// Sert la complétion du formulaire de charge : accepter une proposition
/// reprend son prix, sa quantité et sa catégorie, plutôt que de laisser tout
/// retaper pour une ligne qu'on reconduit chaque mois.
class ChargeSuggestion {
  const ChargeSuggestion({
    required this.libelle,
    this.prixUnitaire,
    this.quantite = 1,
    this.categorie,
  });

  final String libelle;

  /// Dernier prix connu, ou `null` pour un libellé dont on ne sait rien.
  final int? prixUnitaire;
  final int quantite;

  /// Catégorie choisie la dernière fois. `null` laisse jouer la déduction.
  final String? categorie;

  /// La catégorie à montrer dans la liste : le choix passé, sinon la déduction.
  String get categorieEffective =>
      CategoryRules.resolveCharge(categorie, libelle);
}

/// Une charge du mois, projetée depuis la table `Charges`.
class ChargeMensuelle {
  const ChargeMensuelle({
    required this.id,
    required this.libelle,
    required this.prixUnitaire,
    required this.mois,
    required this.dateEnregistrement,
    this.quantite = 1,
    this.categorie,
  });

  final String id;
  final String libelle;

  /// Prix d'une unité. Le total de la ligne est [montant].
  final int prixUnitaire;

  /// Nombre d'unités — 1 pour un loyer ou une facture, qui ne se comptent pas.
  final int quantite;

  /// Ce que la ligne coûte réellement. C'est cette valeur, et non le prix
  /// unitaire, qui entre dans les totaux et le solde du mois.
  int get montant => prixUnitaire * quantite;

  /// Vrai quand la quantité mérite d'être montrée : à un exemplaire, « ×1 »
  /// n'apprend rien et alourdit la ligne.
  bool get multiple => quantite > 1;

  /// Catégorie choisie à la saisie, ou `null` pour une charge antérieure au
  /// choix explicite. Passer par [categorieEffective] plutôt que par ce champ.
  final String? categorie;

  /// La catégorie à afficher et à compter : le choix, sinon la déduction.
  String get categorieEffective =>
      CategoryRules.resolveCharge(categorie, libelle);

  /// Premier jour du mois d'imputation — ce qui décide du cadrage.
  final DateTime mois;

  /// Jour de la saisie, à 00:00 — les charges ne portent pas d'heure. Peut
  /// tomber dans un autre mois que [mois] : un loyer d'août réglé début
  /// septembre s'impute toujours à août.
  final DateTime dateEnregistrement;

  /// La saisie a-t-elle eu lieu hors du mois qu'elle couvre ? Vrai pour un
  /// règlement en retard ou par avance — à signaler, jamais à corriger.
  bool get horsMois =>
      dateEnregistrement.year != mois.year ||
      dateEnregistrement.month != mois.month;
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

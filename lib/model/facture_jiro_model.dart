class FactureJiroModel {
  String? idFactureJiro;
  late String mois;
  late DateTime dateAncienIndex;
  late DateTime dateNouvelIndex;
  late double ancienIndexCompteur;
  late double nouvelIndexCompteur;
  late double ancienIndexSousCompteur;
  late double nouvelIndexSousCompteur;
  late double prixUnitaireKwh;
  late double redevanceJirama;
  late double primeFixeJirama;
  late double taxesRedevances;
  late double tva;
  DateTime? dateFacture;

  FactureJiroModel({
    this.idFactureJiro,
    required this.mois,
    required this.dateAncienIndex,
    required this.dateNouvelIndex,
    required this.ancienIndexCompteur,
    required this.nouvelIndexCompteur,
    required this.ancienIndexSousCompteur,
    required this.nouvelIndexSousCompteur,
    required this.prixUnitaireKwh,
    required this.redevanceJirama,
    required this.primeFixeJirama,
    required this.taxesRedevances,
    required this.tva,
    this.dateFacture,
  });

  // Calculs automatiques
  double get consommationTotale => nouvelIndexCompteur - ancienIndexCompteur;
  double get consommation1 => nouvelIndexSousCompteur - ancienIndexSousCompteur;
  double get consommation2 => consommationTotale - consommation1;

  double get prixConsommation1 => prixUnitaireKwh * consommation1;
  double get prixConsommation2 => prixUnitaireKwh * consommation2;
  double get prixConsommationTotal => prixUnitaireKwh * consommationTotale;

  double get redevance1 => redevanceJirama / 2;
  double get redevance2 => redevanceJirama / 2;

  double get primeFix1 => primeFixeJirama / 2;
  double get primeFix2 => primeFixeJirama / 2;

  double get taxes1 => taxesRedevances / 2;
  double get taxes2 => taxesRedevances / 2;

  double get tva1 => tva / 2;
  double get tva2 => tva / 2;

  double get total1 =>
      prixConsommation1 + redevance1 + primeFix1 + taxes1 + tva1;
  double get total2 =>
      prixConsommation2 + redevance2 + primeFix2 + taxes2 + tva2;
  double get totalGeneral => total1 + total2;

  factory FactureJiroModel.fromJson(Map<String, dynamic> json) =>
      FactureJiroModel(
        idFactureJiro: json['idFactureJiro'],
        mois: json['mois'],
        dateAncienIndex: json['dateAncienIndex'],
        dateNouvelIndex: json['dateNouvelIndex'],
        ancienIndexCompteur: json['ancienIndexCompteur'],
        nouvelIndexCompteur: json['nouvelIndexCompteur'],
        ancienIndexSousCompteur: json['ancienIndexSousCompteur'],
        nouvelIndexSousCompteur: json['nouvelIndexSousCompteur'],
        prixUnitaireKwh: json['prixUnitaireKwh'],
        redevanceJirama: json['redevanceJirama'],
        primeFixeJirama: json['primeFixeJirama'],
        taxesRedevances: json['taxesRedevances'],
        tva: json['tva'],
        dateFacture: json['dateFacture'],
      );

  Map<String, dynamic> toJson() => {
        'idFactureJiro': idFactureJiro,
        'mois': mois,
        'dateAncienIndex': dateAncienIndex,
        'dateNouvelIndex': dateNouvelIndex,
        'ancienIndexCompteur': ancienIndexCompteur,
        'nouvelIndexCompteur': nouvelIndexCompteur,
        'ancienIndexSousCompteur': ancienIndexSousCompteur,
        'nouvelIndexSousCompteur': nouvelIndexSousCompteur,
        'prixUnitaireKwh': prixUnitaireKwh,
        'redevanceJirama': redevanceJirama,
        'primeFixeJirama': primeFixeJirama,
        'taxesRedevances': taxesRedevances,
        'tva': tva,
        'dateFacture': dateFacture,
      };

  @override
  String toString() {
    return "Facture JIRO $mois:\nTotal Conso 1: $total1\nTotal Conso 2: $total2";
  }
}

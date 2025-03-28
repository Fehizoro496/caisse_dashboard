class ReleveModel {
  String? idReleve;
  late double compteur;
  late double sousCompteur;
  DateTime? dateReleve;

  ReleveModel(
      {this.idReleve,
      required this.compteur,
      required this.sousCompteur,
      this.dateReleve});

  factory ReleveModel.fromJson(Map<String, dynamic> json) => ReleveModel(
      idReleve: json['idReleve'],
      compteur: json['compteur'],
      sousCompteur: json['sousCompteur'],
      dateReleve: json['dateReleve']);

  Map<String, dynamic> toJson() => {
        'idFacture': idReleve,
        'compteur': compteur,
        'sous-compteur': sousCompteur,
        'dateFacture': dateReleve
      };

  @override
  String toString() {
    return "Relevé du $dateReleve:\ncompteur: $compteur\nsous-compteur: $sousCompteur";
  }
}

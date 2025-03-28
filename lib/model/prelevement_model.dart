class PrelevementModel {
  String? idPrelevement;
  late int montant;
  DateTime? datePrelevement;

  PrelevementModel(
      {this.idPrelevement, required this.montant, this.datePrelevement});

  factory PrelevementModel.fromJson(Map<String, dynamic> json) =>
      PrelevementModel(
          idPrelevement: json['idPrelevement'],
          montant: json['montant'],
          datePrelevement: json['datePrelevement']);

  Map<String, dynamic> toJson() => {
        'idFacture': idPrelevement,
        'client': montant,
        'dateFacture': datePrelevement
      };

  @override
  String toString() {
    return "Prelevement du $datePrelevement:\nmontant: ${montant}Ar";
  }
}

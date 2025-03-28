class DepenseModel {
  String? idDepense;
  late String libelle;
  late int montant;
  DateTime? dateDepense;

  DepenseModel(
      {this.idDepense,
      required this.libelle,
      required this.montant,
      required this.dateDepense});

  factory DepenseModel.fromJson(Map<String, dynamic> json) => DepenseModel(
      idDepense: json['idDepense'],
      libelle: json['libelle'],
      montant: json['montant'],
      dateDepense: json['dateDepense']);

  Map<String, dynamic> toJson() => {
        'idDepense': idDepense,
        'libelle': libelle,
        'montant': montant,
        'dateDepense': dateDepense
      };

  @override
  String toString() {
    return "Depense $idDepense :$libelle \n$montant Ar\n$dateDepense";
  }
}

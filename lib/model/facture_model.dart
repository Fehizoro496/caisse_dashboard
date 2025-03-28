class FactureModel {
  String? idFacture;
  late String client;
  // late int fournisseur;
  DateTime? dateFacture;

  FactureModel({this.idFacture, required this.client, this.dateFacture});

  factory FactureModel.fromJson(Map<String, dynamic> json) => FactureModel(
      idFacture: json['idFacture'],
      client: json['client'],
      dateFacture: json['dateFacture']);

  Map<String, dynamic> toJson() =>
      {'idFacture': idFacture, 'client': client, 'dateFacture': dateFacture};

  @override
  String toString() {
    return "Facture $idFacture:\nClient: $client \ndate:$dateFacture";
  }
}

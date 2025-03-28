class OperationModel {
  String? idOperation;
  late String nomOperation;
  late int quantiteOperation;
  late int prixOperation;
  DateTime? dateOperation;

  OperationModel(
      {this.idOperation,
      required this.nomOperation,
      required this.quantiteOperation,
      required this.prixOperation,
      this.dateOperation});

  factory OperationModel.fromJson(Map<String, dynamic> json) => OperationModel(
      idOperation: json['idOperation'],
      nomOperation: json['nomOperation'],
      quantiteOperation: json['quantiteOperation'],
      prixOperation: json['prixOperation'],
      dateOperation: json['dateOperation']);

  Map<String, dynamic> toJson() => {
        'idOperation': idOperation,
        'nomOperation': nomOperation,
        'quantiteOperation': quantiteOperation,
        'prixOperation': prixOperation,
        'dateOperation': dateOperation
      };

  @override
  String toString() {
    return "Service $idOperation :$nomOperation \n$prixOperation Ar x $quantiteOperation \nTotal : ${prixOperation * quantiteOperation} Ar";
  }
} //Operation


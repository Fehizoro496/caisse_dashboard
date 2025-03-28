import 'package:caisse_dashboard/utils/chiffre_en_lettre.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:flutter/material.dart';
import './db_service.dart';
import '../model/operation_model.dart';

class InvoiceService extends GetxService {
  List<OperationModel> listInvoiceLine = [];
  List<String> listOperationsID = [];
  late String client;
  TextEditingController clientController = TextEditingController();

  final DBService dbService = Get.find();

  Future<InvoiceService> init() async {
    return this;
  }

  void _clearData() {
    listInvoiceLine.clear();
    listOperationsID.clear();
    client = "";
    clientController.text = "";
  }

  void _getClientName() {
    Get.dialog(AlertDialog(
      surfaceTintColor: const Color(0xFFFFFFFF),
      title: const Text(
        "Client Name",
        textAlign: TextAlign.center,
      ),
      content: TextFormField(
        controller: clientController,
        decoration: const InputDecoration(label: Text("Nom du client")),
      ),
      actions: [
        TextButton(
            onPressed: () {
              client = clientController.text;
              _generateInvoicePdf().then((value) {
                _clearData();
                Get.close(1);
              });
            },
            child: const Text("OUI"))
      ],
    ));
  }

  void invoiceProcess(
      List<OperationModel> listInvoiceLine, List<String> listID) {
    this.listInvoiceLine.addAll(listInvoiceLine);
    listOperationsID.addAll(listID);

    Get.dialog(AlertDialog(
      surfaceTintColor: const Color(0xFFFFFFFF),
      title: const Text('Facturation', textAlign: TextAlign.center),
      content: const Text('Voulez vous imprimer une facture?'),
      actions: [
        TextButton(
            onPressed: () {
              Get.close(1);
              _getClientName();
            },
            child: const Text("OUI")),
        TextButton(
          onPressed: () {
            Get.close(1);
          },
          child: const Text(
            "NON",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ));
  }

  Future<bool> _generateInvoicePdf() async {
    // print(listOperationsID);
    String factureID = await dbService.saveFacture(client: client);
    for (String id in listOperationsID) {
      await dbService.assignFactureInOperation(id, factureID);
    }

    pw.Document pdf = pw.Document();
    int total = 0;
    for (var element in listInvoiceLine) {
      total += element.prixOperation * element.quantiteOperation;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('FACTURE',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.Text('Ref: $factureID',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 40),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('MULTI-SERVICE ITAOSY ANDRANONAHOATRA',
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('033 60 371 38',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text('Doit:',
                                    style: const pw.TextStyle(
                                        fontSize: 12,
                                        decoration:
                                            pw.TextDecoration.underline)),
                                pw.Text(' $client',
                                    style: const pw.TextStyle(fontSize: 12)),
                              ]),
                          pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.start,
                              children: [
                                pw.Text('Date:',
                                    style: const pw.TextStyle(
                                        fontSize: 12,
                                        decoration:
                                            pw.TextDecoration.underline)),
                                pw.Text(
                                    ' ${DateTime.now().day.toString().length == 1 ? '0' : ''}${DateTime.now().day}/${DateTime.now().month.toString().length == 1 ? '0' : ''}${DateTime.now().month}/${DateTime.now().year}',
                                    style: const pw.TextStyle(fontSize: 12)),
                              ]),
                        ]),
                  ]),
              pw.SizedBox(height: 20),
              pw.TableHelper.fromTextArray(
                headerAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(
                  fontSize: 10,
                ),
                cellDecoration: (index, row, col) {
                  if (index == listInvoiceLine.length &&
                      (col == 3 || col == 4)) {
                    return const pw.BoxDecoration(
                        border: pw.Border(
                      top: pw.BorderSide(width: 1),
                      bottom: pw.BorderSide(width: 1),
                    ));
                  }
                  if (index != listInvoiceLine.length) {
                    return pw.BoxDecoration(
                      border: pw.Border.all(width: 1),
                    );
                  }
                  return const pw.BoxDecoration();
                },
                columnWidths: const {
                  0: pw.FractionColumnWidth(0.05),
                  1: pw.FractionColumnWidth(0.35),
                  2: pw.FractionColumnWidth(0.15),
                  3: pw.FractionColumnWidth(0.2),
                  4: pw.FractionColumnWidth(0.25),
                },
                cellAlignments: const {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.centerRight,
                },
                headers: <String>[
                  'N',
                  'Désignation',
                  'Quantité',
                  'PU (en Ar)',
                  'Total'
                ],
                data: [
                  ...listInvoiceLine.mapIndexed((index, operation) {
                    return <String>[
                      '${index + 1}',
                      operation.nomOperation,
                      formatNumber(operation.quantiteOperation),
                      formatNumber(operation.prixOperation),
                      "${formatNumber(operation.quantiteOperation * operation.prixOperation)} Ar"
                    ];
                  }).toList(),
                  ['', '', '', 'TOTAL', "${formatNumber(total)} Ar"],
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                  "Présente facture arrêtée à la somme de ${chiffreEnLettre(total.floor()).trim()} Ariary."),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.SizedBox(),
                  pw.Text(
                    'Le responsable',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // final output = await getTemporaryDirectory();
    // final file = File("${output.path}\invoice.pdf");

    String filePath =
        "C:\\Users\\${_getWindowsUsername()}\\Desktop\\facture ${client.trim()}.pdf";
    int counter = 1;
    while (File(filePath).existsSync()) {
      filePath =
          "C:\\Users\\${_getWindowsUsername()}\\Desktop\\facture ${client.trim()} ($counter).pdf";
      counter++;
    }
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save()).then((value) {
      Get.snackbar(
        'PDF Generated',
        'Invoice PDF has been generated successfully!',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 0, 225, 0),
        colorText: Colors.white,
      );
    });
    // print("Chemin vers la facture => ${file.path}");

    return true;
  }

  String _getWindowsUsername() {
    return Platform.environment['USERNAME'] ?? 'Utilisateur inconnu';
  }

  // String formatNumber(int i) {
  //   List<String> tab = [];
  //   int temp = i;
  //   while (temp > 0) {
  //     tab.add('${temp % 1000}');
  //     temp = (temp / 1000).ceil();
  //   }
  //   return tab.reversed.toList().join(' ');
  // }
}

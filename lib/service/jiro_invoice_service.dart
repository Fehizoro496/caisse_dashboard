import 'dart:io';
import 'package:caisse_dashboard/model/facture_jiro_model.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class JiroInvoiceService extends GetxService {
  Future<JiroInvoiceService> init() async {
    return this;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM').format(date);
  }

  String _formatDecimal(double value) {
    if (value == value.roundToDouble()) {
      return formatNumber(value.round());
    }
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = formatNumber(int.parse(parts[0]));
    final decPart = parts[1].replaceAll(RegExp(r'0+$'), '');
    if (decPart.isEmpty) {
      return intPart;
    }
    return '$intPart,$decPart';
  }

  Future<bool> generateJiroPdf(FactureJiroModel facture) async {
    final pdf = pw.Document();

    // Calculs
    final conso1 = facture.consommation1;
    final conso2 = facture.consommation2;
    final consoTotal = facture.consommationTotale;

    final prixConso1 = facture.prixConsommation1;
    final prixConso2 = facture.prixConsommation2;
    final prixConsoTotal = facture.prixConsommationTotal;

    final redevance1 = facture.redevance1;
    final redevance2 = facture.redevance2;
    final redevanceTotal = facture.redevanceJirama;

    final prime1 = facture.primeFix1;
    final prime2 = facture.primeFix2;
    final primeTotal = facture.primeFixeJirama;

    final taxes1 = facture.taxes1;
    final taxes2 = facture.taxes2;
    final taxesTotal = facture.taxesRedevances;

    final tva1 = facture.tva1;
    final tva2 = facture.tva2;
    final tvaTotal = facture.tva;

    final total1 = facture.total1;
    final total2 = facture.total2;
    final totalGeneral = facture.totalGeneral;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Titre
              pw.Center(
                child: pw.Text(
                  'JIRO mois de ${facture.mois}',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Tableau principal de répartition
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1.2),
                  2: const pw.FlexColumnWidth(1.2),
                  3: const pw.FlexColumnWidth(1.2),
                },
                children: [
                  // En-tête
                  _buildTableRow([' ', ' ', ' ', 'TOTAL'], isHeader: true),
                  // Données
                  _buildTableRow([
                    'Quantité consommée',
                    _formatDecimal(conso1),
                    _formatDecimal(conso2),
                    _formatDecimal(consoTotal),
                  ]),
                  _buildTableRow([
                    'Prix consommation',
                    _formatDecimal(prixConso1),
                    _formatDecimal(prixConso2),
                    _formatDecimal(prixConsoTotal),
                  ]),
                  _buildTableRow([
                    'Redevance JIRAMA',
                    _formatDecimal(redevance1),
                    _formatDecimal(redevance2),
                    _formatDecimal(redevanceTotal),
                  ]),
                  _buildTableRow([
                    'Prime fixe JIRAMA',
                    _formatDecimal(prime1),
                    _formatDecimal(prime2),
                    _formatDecimal(primeTotal),
                  ]),
                  _buildTableRow([
                    'Taxes et Redevances',
                    _formatDecimal(taxes1),
                    _formatDecimal(taxes2),
                    _formatDecimal(taxesTotal),
                  ]),
                  _buildTableRow([
                    'TVA',
                    _formatDecimal(tva1),
                    _formatDecimal(tva2),
                    _formatDecimal(tvaTotal),
                  ]),
                  _buildTableRow([
                    'TOTAL à payer',
                    _formatDecimal(total1),
                    _formatDecimal(total2),
                    _formatDecimal(totalGeneral),
                  ], isTotal: true),
                ],
              ),

              pw.SizedBox(height: 30),

              // Tableau des index
              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
                cellStyle: const pw.TextStyle(fontSize: 14),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                cellHeight: 30,
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerRight,
                  2: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                },
                headers: ['', 'Compteur principal', 'Sous-compteur'],
                data: [
                  [
                    'Nouvel index (${_formatDate(facture.dateNouvelIndex)})',
                    _formatDecimal(facture.nouvelIndexCompteur),
                    _formatDecimal(facture.nouvelIndexSousCompteur),
                  ],
                  [
                    'Ancien index (${_formatDate(facture.dateAncienIndex)})',
                    _formatDecimal(facture.ancienIndexCompteur),
                    _formatDecimal(facture.ancienIndexSousCompteur),
                  ],
                  [
                    'Consommation',
                    _formatDecimal(consoTotal),
                    _formatDecimal(conso1),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );

    // Sauvegarde du fichier
    String filePath =
        "C:\\Users\\${_getWindowsUsername()}\\Desktop\\JIRO ${facture.mois}.pdf";
    int counter = 1;
    while (File(filePath).existsSync()) {
      filePath =
          "C:\\Users\\${_getWindowsUsername()}\\Desktop\\JIRO ${facture.mois} ($counter).pdf";
      counter++;
    }

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    Get.snackbar(
      'PDF Généré',
      'Le fichier a été enregistré sur le Bureau',
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
      backgroundColor: const Color.fromARGB(175, 0, 225, 0),
      colorText: Colors.white,
    );

    return true;
  }

  Future<bool> generateJiroPdfFromData(FacturesJiroData data) async {
    final facture = FactureJiroModel(
      idFactureJiro: data.idFactureJiro,
      mois: data.mois,
      dateAncienIndex: data.dateAncienIndex,
      dateNouvelIndex: data.dateNouvelIndex,
      ancienIndexCompteur: data.ancienIndexCompteur,
      nouvelIndexCompteur: data.nouvelIndexCompteur,
      ancienIndexSousCompteur: data.ancienIndexSousCompteur,
      nouvelIndexSousCompteur: data.nouvelIndexSousCompteur,
      prixUnitaireKwh: data.prixUnitaireKwh,
      redevanceJirama: data.redevanceJirama,
      primeFixeJirama: data.primeFixeJirama,
      taxesRedevances: data.taxesRedevances,
      tva: data.tva,
      dateFacture: data.dateFacture,
    );
    return generateJiroPdf(facture);
  }

  String _getWindowsUsername() {
    return Platform.environment['USERNAME'] ?? 'Utilisateur inconnu';
  }

  /// Construit une ligne de tableau avec la colonne 1 (Conso 1) grisée
  pw.TableRow _buildTableRow(
    List<String> cells, {
    bool isHeader = false,
    bool isTotal = false,
  }) {
    return pw.TableRow(
      children: cells.asMap().entries.map((entry) {
        final idx = entry.key;
        final text = entry.value;

        // Déterminer la couleur de fond
        PdfColor? bgColor;
        if (isHeader) {
          bgColor = PdfColors.grey300;
        } else if (isTotal) {
          bgColor = PdfColors.grey200;
        } else if (idx == 1) {
          // Colonne "Conso 1" grisée
          bgColor = PdfColors.grey200;
        }

        return pw.Container(
          padding: const pw.EdgeInsets.all(8),
          decoration: bgColor != null ? pw.BoxDecoration(color: bgColor) : null,
          alignment: idx == 0
              ? pw.Alignment.centerLeft
              : pw.Alignment.centerRight,
          child: pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: isHeader || isTotal
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
            ),
          ),
        );
      }).toList(),
    );
  }
}

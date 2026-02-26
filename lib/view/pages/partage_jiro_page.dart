import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/model/facture_jiro_model.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/jiro_invoice_service.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class PartageJiroPage extends StatefulWidget {
  const PartageJiroPage({super.key});

  @override
  State<PartageJiroPage> createState() => _PartageJiroPageState();
}

class _PartageJiroPageState extends State<PartageJiroPage> {
  final DBService _dbService = Get.find<DBService>();
  final JiroInvoiceService _jiroService = Get.find<JiroInvoiceService>();

  List<FacturesJiroData> _factures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFactures();
  }

  Future<void> _loadFactures() async {
    setState(() => _isLoading = true);
    final factures = await _dbService.getAllFacturesJiro();
    setState(() {
      _factures = factures;
      _isLoading = false;
    });
  }

  void _showAddFactureDialog() {
    final formKey = GlobalKey<FormState>();
    final moisController = TextEditingController();
    final ancienCompteurController = TextEditingController();
    final nouvelCompteurController = TextEditingController();
    final prixKwhController = TextEditingController();
    final redevanceController = TextEditingController();
    final primeFixeController = TextEditingController();
    final taxesController = TextEditingController();
    final tvaController = TextEditingController();

    DateTime dateAncienIndex = DateTime.now().subtract(
      const Duration(days: 30),
    );
    DateTime dateNouvelIndex = DateTime.now();

    // Valeurs du sous-compteur récupérées automatiquement
    double? ancienSousCompteur;
    double? nouvelSousCompteur;
    bool isLoadingAncien = false;
    bool isLoadingNouvel = false;
    String? ancienReleveInfo;
    String? nouvelReleveInfo;

    // Fonction pour récupérer le sous-compteur depuis les relevés
    Future<void> fetchSousCompteurAncien(
      StateSetter setDialogState,
      double compteurValue,
    ) async {
      setDialogState(() => isLoadingAncien = true);
      final result = await _dbService.getSousCompteurForCompteurValue(
        compteurValue,
      );
      setDialogState(() {
        isLoadingAncien = false;
        if (result != null) {
          ancienSousCompteur = result['sousCompteur'] as double;
          dateAncienIndex = result['date'] as DateTime;
          final isInterpolated = result['isInterpolated'] as bool;
          if (isInterpolated) {
            ancienReleveInfo =
                'Calculé (${DateFormat('dd/MM/yyyy').format(dateAncienIndex)})';
          } else {
            ancienReleveInfo =
                'Relevé du ${DateFormat('dd/MM/yyyy').format(dateAncienIndex)}';
          }
        } else {
          ancienSousCompteur = null;
          ancienReleveInfo = 'Aucun relevé trouvé';
        }
      });
    }

    Future<void> fetchSousCompteurNouvel(
      StateSetter setDialogState,
      double compteurValue,
    ) async {
      setDialogState(() => isLoadingNouvel = true);
      final result = await _dbService.getSousCompteurForCompteurValue(
        compteurValue,
      );
      setDialogState(() {
        isLoadingNouvel = false;
        if (result != null) {
          nouvelSousCompteur = result['sousCompteur'] as double;
          dateNouvelIndex = result['date'] as DateTime;
          final isInterpolated = result['isInterpolated'] as bool;
          if (isInterpolated) {
            nouvelReleveInfo =
                'Calculé (${DateFormat('dd/MM/yyyy').format(dateNouvelIndex)})';
          } else {
            nouvelReleveInfo =
                'Relevé du ${DateFormat('dd/MM/yyyy').format(dateNouvelIndex)}';
          }
        } else {
          nouvelSousCompteur = null;
          nouvelReleveInfo = 'Aucun relevé trouvé';
        }
      });
    }

    Get.dialog(
      StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Get.find<ThemeController>().isDarkMode;
          final textColor = isDark ? AppColors.darkText : AppColors.lightText;
          final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
          final secondaryColor = isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary;

          return AlertDialog(
            backgroundColor: bgColor,
            title: Text(
              'Nouvelle Facture JIRO',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor),
            ),
            content: SizedBox(
              width: 500,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: moisController,
                        label: 'Mois de la facture',
                        hint: 'Ex: Janvier 2026',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // Compteur principal - Ancien index
                      Text(
                        'Compteur principal',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  controller: ancienCompteurController,
                                  label: 'Ancien index',
                                  isNumber: true,
                                  isDark: isDark,
                                  onChanged: (value) {
                                    final compteur = double.tryParse(value);
                                    if (compteur != null && compteur > 0) {
                                      fetchSousCompteurAncien(
                                        setDialogState,
                                        compteur,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 4),
                                if (isLoadingAncien)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Recherche...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (ancienReleveInfo != null)
                                  Text(
                                    ancienReleveInfo!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: ancienSousCompteur != null
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  controller: nouvelCompteurController,
                                  label: 'Nouvel index',
                                  isNumber: true,
                                  isDark: isDark,
                                  onChanged: (value) {
                                    final compteur = double.tryParse(value);
                                    if (compteur != null && compteur > 0) {
                                      fetchSousCompteurNouvel(
                                        setDialogState,
                                        compteur,
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 4),
                                if (isLoadingNouvel)
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Recherche...',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondaryColor,
                                        ),
                                      ),
                                    ],
                                  )
                                else if (nouvelReleveInfo != null)
                                  Text(
                                    nouvelReleveInfo!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: nouvelSousCompteur != null
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Sous-compteur (affiché automatiquement)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: AppColors.info,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Sous-compteur (récupéré automatiquement)',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.info,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ancien index',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      Text(
                                        ancienSousCompteur != null
                                            ? _formatNum(ancienSousCompteur!)
                                            : '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Nouvel index',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: secondaryColor,
                                        ),
                                      ),
                                      Text(
                                        nouvelSousCompteur != null
                                            ? _formatNum(nouvelSousCompteur!)
                                            : '-',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Prix kWh
                      _buildTextField(
                        controller: prixKwhController,
                        label: 'Prix unitaire kWh (Ar)',
                        isNumber: true,
                        isDecimal: true,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),

                      // Frais à diviser par 2
                      Text(
                        'Frais totaux (seront divisés par 2)',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: redevanceController,
                              label: 'Redevance JIRAMA',
                              isNumber: true,
                              isDecimal: true,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: primeFixeController,
                              label: 'Prime fixe JIRAMA',
                              isNumber: true,
                              isDecimal: true,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: taxesController,
                              label: 'Taxes et Redevances',
                              isNumber: true,
                              isDecimal: true,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: tvaController,
                              label: 'TVA',
                              isNumber: true,
                              isDecimal: true,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text(
                  'Annuler',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                ),
                onPressed:
                    (ancienSousCompteur == null || nouvelSousCompteur == null)
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final facture = FactureJiroModel(
                            mois: moisController.text,
                            dateAncienIndex: dateAncienIndex,
                            dateNouvelIndex: dateNouvelIndex,
                            ancienIndexCompteur:
                                double.tryParse(
                                  ancienCompteurController.text,
                                ) ??
                                0,
                            nouvelIndexCompteur:
                                double.tryParse(
                                  nouvelCompteurController.text,
                                ) ??
                                0,
                            ancienIndexSousCompteur: ancienSousCompteur!,
                            nouvelIndexSousCompteur: nouvelSousCompteur!,
                            prixUnitaireKwh:
                                double.tryParse(prixKwhController.text) ?? 0,
                            redevanceJirama:
                                double.tryParse(redevanceController.text) ?? 0,
                            primeFixeJirama:
                                double.tryParse(primeFixeController.text) ?? 0,
                            taxesRedevances:
                                double.tryParse(taxesController.text) ?? 0,
                            tva: double.tryParse(tvaController.text) ?? 0,
                          );

                          await _dbService.saveFactureJiro(facture);
                          await _jiroService.generateJiroPdf(facture);
                          Get.back();
                          _loadFactures();
                        }
                      },
                child: const Text(
                  'Créer et Générer PDF',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isNumber = false,
    bool isDecimal = false,
    required bool isDark,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? (isDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number)
          : TextInputType.text,
      inputFormatters: isNumber
          ? [
              FilteringTextInputFormatter.allow(
                isDecimal ? RegExp(r'[\d.,]') : RegExp(r'\d'),
              ),
            ]
          : null,
      style: TextStyle(
        color: isDark ? AppColors.darkText : AppColors.lightText,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Champ requis';
        }
        return null;
      },
    );
  }

  void _showFactureDetails(FacturesJiroData data) {
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

    final isDark = Get.find<ThemeController>().isDarkMode;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        title: Text(
          'JIRO ${facture.mois}',
          textAlign: TextAlign.center,
          style: TextStyle(color: textColor),
        ),
        content: SizedBox(
          width: 450,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailTable(facture, textColor, secondaryColor),
                const SizedBox(height: 16),
                _buildIndexTable(facture, textColor, secondaryColor),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Get.back();
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: const Text('Confirmer la suppression'),
                  content: Text(
                    'Voulez-vous supprimer la facture de ${facture.mois} ?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: const Text('Non'),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text(
                        'Oui',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await _dbService.deleteFactureJiro(data.idFactureJiro);
                _loadFactures();
              }
            },
            child: Text('Supprimer', style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () {
              _jiroService.generateJiroPdfFromData(data);
              Get.back();
            },
            child: const Text(
              'Régénérer PDF',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTable(
    FactureJiroModel f,
    Color textColor,
    Color secondaryColor,
  ) {
    return Table(
      border: TableBorder.all(color: secondaryColor.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1.2),
        2: FlexColumnWidth(1.2),
        3: FlexColumnWidth(1.2),
      },
      children: [
        _buildTableRow(
          ['', '', '', 'TOTAL'],
          isHeader: true,
          textColor: textColor,
        ),
        _buildTableRow([
          'Quantité consommée',
          _formatNum(f.consommation1),
          _formatNum(f.consommation2),
          _formatNum(f.consommationTotale),
        ], textColor: textColor),
        _buildTableRow([
          'Prix consommation',
          _formatNum(f.prixConsommation1),
          _formatNum(f.prixConsommation2),
          _formatNum(f.prixConsommationTotal),
        ], textColor: textColor),
        _buildTableRow([
          'Redevance JIRAMA',
          _formatNum(f.redevance1),
          _formatNum(f.redevance2),
          _formatNum(f.redevanceJirama),
        ], textColor: textColor),
        _buildTableRow([
          'Prime fixe JIRAMA',
          _formatNum(f.primeFix1),
          _formatNum(f.primeFix2),
          _formatNum(f.primeFixeJirama),
        ], textColor: textColor),
        _buildTableRow([
          'Taxes et Redevances',
          _formatNum(f.taxes1),
          _formatNum(f.taxes2),
          _formatNum(f.taxesRedevances),
        ], textColor: textColor),
        _buildTableRow([
          'TVA',
          _formatNum(f.tva1),
          _formatNum(f.tva2),
          _formatNum(f.tva),
        ], textColor: textColor),
        _buildTableRow(
          [
            'TOTAL à payer',
            _formatNum(f.total1),
            _formatNum(f.total2),
            _formatNum(f.totalGeneral),
          ],
          isTotal: true,
          textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildIndexTable(
    FactureJiroModel f,
    Color textColor,
    Color secondaryColor,
  ) {
    return Table(
      border: TableBorder.all(color: secondaryColor.withValues(alpha: 0.3)),
      columnWidths: const {
        0: FlexColumnWidth(1.5),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
      },
      children: [
        _buildTableRow(
          ['', 'Compteur principal', 'Sous-compteur'],
          isHeader: true,
          textColor: textColor,
        ),
        _buildTableRow([
          'Nouvel index (${DateFormat('dd/MM').format(f.dateNouvelIndex)})',
          _formatNum(f.nouvelIndexCompteur),
          _formatNum(f.nouvelIndexSousCompteur),
        ], textColor: textColor),
        _buildTableRow([
          'Ancien index (${DateFormat('dd/MM').format(f.dateAncienIndex)})',
          _formatNum(f.ancienIndexCompteur),
          _formatNum(f.ancienIndexSousCompteur),
        ], textColor: textColor),
        _buildTableRow([
          'Consommation',
          _formatNum(f.consommationTotale),
          _formatNum(f.consommation1),
        ], textColor: textColor),
      ],
    );
  }

  TableRow _buildTableRow(
    List<String> cells, {
    bool isHeader = false,
    bool isTotal = false,
    required Color textColor,
  }) {
    return TableRow(
      decoration: isHeader
          ? BoxDecoration(color: AppColors.warning.withValues(alpha: 0.2))
          : isTotal
          ? BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1))
          : null,
      children: cells.asMap().entries.map((entry) {
        final idx = entry.key;
        final cell = entry.value;
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            cell,
            textAlign: idx == 0 ? TextAlign.left : TextAlign.right,
            style: TextStyle(
              fontWeight: isHeader || isTotal
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: textColor,
              fontSize: 12,
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatNum(double value) {
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

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        final secondaryTextColor = isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary;

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddFactureDialog,
            backgroundColor: AppColors.warning,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Nouvelle facture',
              style: TextStyle(color: Colors.white),
            ),
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.darkBackgroundGradient
                  : AppColors.lightBackgroundGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(textColor, secondaryTextColor, isDark),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.warning,
                            ),
                          )
                        : _buildContent(textColor, secondaryTextColor, isDark),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color textColor, Color secondaryTextColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(Icons.arrow_back_rounded, color: textColor),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Partage JIRO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_factures.length} facture(s) enregistrée(s)',
                  style: TextStyle(fontSize: 14, color: secondaryTextColor),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.electric_meter_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Color textColor, Color secondaryTextColor, bool isDark) {
    if (_factures.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune facture de partage',
              style: TextStyle(color: secondaryTextColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur + pour créer une nouvelle facture',
              style: TextStyle(
                color: secondaryTextColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _factures.length,
      itemBuilder: (context, index) {
        final facture = _factures[index];
        return _buildFactureCard(
          facture,
          textColor,
          secondaryTextColor,
          isDark,
        );
      },
    );
  }

  Widget _buildFactureCard(
    FacturesJiroData facture,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final model = FactureJiroModel(
      mois: facture.mois,
      dateAncienIndex: facture.dateAncienIndex,
      dateNouvelIndex: facture.dateNouvelIndex,
      ancienIndexCompteur: facture.ancienIndexCompteur,
      nouvelIndexCompteur: facture.nouvelIndexCompteur,
      ancienIndexSousCompteur: facture.ancienIndexSousCompteur,
      nouvelIndexSousCompteur: facture.nouvelIndexSousCompteur,
      prixUnitaireKwh: facture.prixUnitaireKwh,
      redevanceJirama: facture.redevanceJirama,
      primeFixeJirama: facture.primeFixeJirama,
      taxesRedevances: facture.taxesRedevances,
      tva: facture.tva,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () => _showFactureDetails(facture),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.electric_bolt_rounded,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'JIRO ${facture.mois}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créé le ${DateFormat('dd/MM/yyyy').format(facture.dateFacture)}',
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Conso 1: ${_formatNum(model.total1)} Ar',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Conso 2: ${_formatNum(model.total2)} Ar',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded, color: secondaryTextColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

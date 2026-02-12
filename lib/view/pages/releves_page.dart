import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RelevesPage extends StatefulWidget {
  const RelevesPage({super.key});

  @override
  State<RelevesPage> createState() => _RelevesPageState();
}

class _RelevesPageState extends State<RelevesPage> {
  final MainController _controller = Get.find<MainController>();

  List<Releve> _allReleves = [];
  List<Releve> _filteredReleves = [];
  bool _isLoading = true;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadReleves();
  }

  Future<void> _loadReleves() async {
    setState(() => _isLoading = true);
    final releves = await _controller.dbService.getAllReleves();
    setState(() {
      _allReleves = releves;
      _filteredReleves = releves;
      _sortReleves();
      _isLoading = false;
    });
  }

  void _sortReleves() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredReleves.sort(
            (a, b) => _sortAscending
                ? a.dateReleve.compareTo(b.dateReleve)
                : b.dateReleve.compareTo(a.dateReleve),
          );
          break;
        case 'compteur':
          _filteredReleves.sort(
            (a, b) => _sortAscending
                ? a.compteur.compareTo(b.compteur)
                : b.compteur.compareTo(a.compteur),
          );
          break;
        case 'sousCompteur':
          _filteredReleves.sort(
            (a, b) => _sortAscending
                ? a.sousCompteur.compareTo(b.sousCompteur)
                : b.sousCompteur.compareTo(a.sousCompteur),
          );
          break;
      }
    });
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
                  _buildSortOptions(textColor, secondaryTextColor, isDark),
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
                  'Relevés Électricité',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_filteredReleves.length} relevés enregistrés',
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
              Icons.electric_bolt_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text('Trier par:', style: TextStyle(color: secondaryTextColor)),
            const SizedBox(width: 12),
            _buildSortChip('Date', 'date', isDark),
            const SizedBox(width: 8),
            _buildSortChip('Compteur', 'compteur', isDark),
            const SizedBox(width: 8),
            _buildSortChip('Sous-compteur', 'sousCompteur', isDark),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                  _sortReleves();
                });
              },
              icon: Icon(
                _sortAscending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortReleves();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.warning
              : isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : isDark
                ? AppColors.darkText
                : AppColors.lightText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor, Color secondaryTextColor, bool isDark) {
    if (_filteredReleves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.electric_meter_outlined,
              size: 64,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun relevé enregistré',
              style: TextStyle(color: secondaryTextColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // Chart showing evolution
          if (_filteredReleves.length > 1)
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.show_chart_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Évolution des relevés',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 200, child: _buildChart(isDark)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // List of releves
          _buildRelevesList(textColor, secondaryTextColor, isDark),
        ],
      ),
    );
  }

  Widget _buildChart(bool isDark) {
    // Sort by date for chart
    final sortedReleves = List<Releve>.from(_filteredReleves)
      ..sort((a, b) => a.dateReleve.compareTo(b.dateReleve));

    final chartData = sortedReleves.map((r) {
      return _ChartData(
        DateFormat('dd/MM').format(r.dateReleve),
        r.compteur.toDouble(),
        r.sousCompteur.toDouble(),
      );
    }).toList();

    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: EdgeInsets.zero,
      primaryXAxis: CategoryAxis(
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontSize: 10,
        ),
        axisLine: AxisLine(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      primaryYAxis: NumericAxis(
        majorGridLines: MajorGridLines(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
        labelStyle: TextStyle(
          color: isDark
              ? AppColors.darkTextSecondary
              : AppColors.lightTextSecondary,
          fontSize: 10,
        ),
        axisLine: const AxisLine(width: 0),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        textStyle: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.lightText,
          fontSize: 11,
        ),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CartesianSeries>[
        SplineSeries<_ChartData, String>(
          name: 'Compteur',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.compteur,
          color: AppColors.warning,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.circle,
            width: 6,
            height: 6,
            color: AppColors.warning,
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        ),
        SplineSeries<_ChartData, String>(
          name: 'Sous-compteur',
          dataSource: chartData,
          xValueMapper: (data, _) => data.date,
          yValueMapper: (data, _) => data.sousCompteur,
          color: AppColors.info,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            shape: DataMarkerType.diamond,
            width: 6,
            height: 6,
            color: AppColors.info,
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildRelevesList(
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    // Calculate consumption between readings
    final sortedByDate = List<Releve>.from(_filteredReleves)
      ..sort((a, b) => b.dateReleve.compareTo(a.dateReleve));

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sortedByDate.length,
        separatorBuilder: (_, __) => Divider(
          color: secondaryTextColor.withValues(alpha: 0.2),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final releve = sortedByDate[index];

          // Calculate consumption (difference with previous reading)
          double? consumption;
          double? sousConsumption;
          if (index < sortedByDate.length - 1) {
            final previousReleve = sortedByDate[index + 1];
            consumption = releve.compteur - previousReleve.compteur;
            sousConsumption = releve.sousCompteur - previousReleve.sousCompteur;
          }

          return ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.electric_meter_rounded,
                color: AppColors.warning,
                size: 20,
              ),
            ),
            title: Text(
              DateFormat('dd MMMM yyyy', 'fr_FR').format(releve.dateReleve),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'Compteur: ${formatNumber(releve.compteur)} kWh',
              style: TextStyle(color: secondaryTextColor, fontSize: 12),
            ),
            trailing: consumption != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: consumption > 0
                          ? AppColors.warning.withValues(alpha: 0.1)
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${formatNumber(consumption)} kWh',
                      style: TextStyle(
                        color: consumption > 0
                            ? AppColors.warning
                            : AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Compteur principal',
                      '${formatNumber(releve.compteur)} kWh',
                      AppColors.warning,
                      textColor,
                      secondaryTextColor,
                    ),
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Sous-compteur',
                      '${formatNumber(releve.sousCompteur)} kWh',
                      AppColors.info,
                      textColor,
                      secondaryTextColor,
                    ),
                    if (consumption != null) ...[
                      const SizedBox(height: 12),
                      Divider(color: secondaryTextColor.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Consommation compteur',
                        '+${formatNumber(consumption)} kWh',
                        AppColors.warning,
                        textColor,
                        secondaryTextColor,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Consommation sous-compteur',
                        '+${formatNumber(sousConsumption!)} kWh',
                        AppColors.info,
                        textColor,
                        secondaryTextColor,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Enregistré le ${DateFormat('dd/MM/yyyy à HH:mm').format(releve.dateReleve)}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color accentColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: secondaryTextColor, fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final String date;
  final double compteur;
  final double sousCompteur;

  _ChartData(this.date, this.compteur, this.sousCompteur);
}

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:caisse_dashboard/utils/format_number.dart';

/// Graphique camembert des dépenses par catégorie
class ExpensePieChart extends StatelessWidget {
  const ExpensePieChart({super.key});

  // Palette de couleurs pour le graphique
  static const List<Color> _chartColors = [
    AppColors.primary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.info,
    AppColors.error,
    AppColors.primaryLight,
    AppColors.accentLight,
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      builder: (controller) {
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            final isDark = themeController.isDarkMode;
            final textColor = isDark ? AppColors.darkText : AppColors.lightText;
            final secondaryTextColor =
                isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.pie_chart,
                          color: AppColors.accent,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Répartition des dépenses',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<PieData>>(
                      future: _getExpenseData(controller),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pie_chart_outline,
                                  size: 48,
                                  color: secondaryTextColor.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucune dépense',
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              ],
                            ),
                          );
                        }
                        return SfCircularChart(
                          margin: const EdgeInsets.all(0),
                          legend: Legend(
                            isVisible: true,
                            position: LegendPosition.bottom,
                            overflowMode: LegendItemOverflowMode.wrap,
                            textStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                            iconHeight: 10,
                            iconWidth: 10,
                          ),
                          tooltipBehavior: TooltipBehavior(
                            enable: true,
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            textStyle: TextStyle(color: textColor),
                            builder: (data, point, series, pointIndex, seriesIndex) {
                              final pieData = data as PieData;
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '${pieData.label}: ${formatNumber(pieData.value.toInt())} Ar',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          series: <CircularSeries>[
                            DoughnutSeries<PieData, String>(
                              dataSource: snapshot.data!,
                              xValueMapper: (PieData data, _) => data.label,
                              yValueMapper: (PieData data, _) => data.value,
                              pointColorMapper: (PieData data, index) =>
                                  _chartColors[index % _chartColors.length],
                              innerRadius: '55%',
                              radius: '85%',
                              dataLabelSettings: DataLabelSettings(
                                isVisible: true,
                                labelPosition: ChartDataLabelPosition.outside,
                                textStyle: TextStyle(
                                  color: textColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                                connectorLineSettings: ConnectorLineSettings(
                                  color: secondaryTextColor.withValues(alpha: 0.5),
                                  width: 1,
                                  length: '10%',
                                ),
                                labelIntersectAction: LabelIntersectAction.shift,
                              ),
                              dataLabelMapper: (PieData data, _) =>
                                  '${data.percentage.toStringAsFixed(0)}%',
                              animationDuration: 1500,
                              explode: true,
                              explodeIndex: 0,
                              explodeOffset: '5%',
                            ),
                          ],
                          annotations: <CircularChartAnnotation>[
                            CircularChartAnnotation(
                              widget: FutureBuilder<double>(
                                future: controller.getAmountExpenses(),
                                builder: (context, snapshot) {
                                  final total = snapshot.data ?? 0;
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Total',
                                        style: TextStyle(
                                          color: secondaryTextColor,
                                          fontSize: 11,
                                        ),
                                      ),
                                      Text(
                                        _formatCompact(total),
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<List<PieData>> _getExpenseData(MainController controller) async {
    final depenses = await controller.getDepensesByDate(controller.currentDate);

    if (depenses.isEmpty) return [];

    // Grouper les dépenses par libellé
    final Map<String, int> grouped = {};
    int total = 0;

    for (var dep in depenses) {
      grouped[dep.libelle] = (grouped[dep.libelle] ?? 0) + dep.montant;
      total += dep.montant;
    }

    // Convertir en liste de PieData avec pourcentage
    return grouped.entries.map((e) {
      final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
      return PieData(e.key, e.value.toDouble(), percentage);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Trier par valeur décroissante
  }

  String _formatCompact(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M Ar';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K Ar';
    }
    return '${number.toStringAsFixed(0)} Ar';
  }
}

/// Modèle de données pour le graphique pie
class PieData {
  final String label;
  final double value;
  final double percentage;

  PieData(this.label, this.value, this.percentage);
}

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';

/// Graphique comparatif Entrants vs Prélèvements sur 7 jours
class IncomeChart extends StatelessWidget {
  const IncomeChart({super.key});

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
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.insights_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Entrants vs Prélèvements',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Légende
                  Row(
                    children: [
                      _LegendItem(
                        color: AppColors.success,
                        label: 'Entrants',
                      ),
                      const SizedBox(width: 16),
                      _LegendItem(
                        color: AppColors.accent,
                        label: 'Prélèvements',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: FutureBuilder<ChartDataSet>(
                      future: _getWeeklyData(controller),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return Center(
                            child: Text(
                              'Aucune donnée',
                              style: TextStyle(color: secondaryTextColor),
                            ),
                          );
                        }

                        final dataSet = snapshot.data!;

                        return SfCartesianChart(
                          plotAreaBorderWidth: 0,
                          margin: const EdgeInsets.all(0),
                          primaryXAxis: CategoryAxis(
                            majorGridLines: const MajorGridLines(width: 0),
                            axisLine: const AxisLine(width: 0),
                            labelStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 11,
                            ),
                            majorTickLines: const MajorTickLines(width: 0),
                          ),
                          primaryYAxis: NumericAxis(
                            majorGridLines: MajorGridLines(
                              width: 0.5,
                              color: secondaryTextColor.withValues(alpha: 0.2),
                              dashArray: const <double>[5, 5],
                            ),
                            axisLine: const AxisLine(width: 0),
                            labelStyle: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 10,
                            ),
                            majorTickLines: const MajorTickLines(width: 0),
                            labelFormat: '{value}',
                            axisLabelFormatter: (AxisLabelRenderDetails details) {
                              final num value = details.value;
                              String text;
                              if (value >= 1000000) {
                                text = '${(value / 1000000).toStringAsFixed(0)}M';
                              } else if (value >= 1000) {
                                text = '${(value / 1000).toStringAsFixed(0)}K';
                              } else {
                                text = value.toStringAsFixed(0);
                              }
                              return ChartAxisLabel(text, details.textStyle);
                            },
                          ),
                          tooltipBehavior: TooltipBehavior(
                            enable: true,
                            shared: true,
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            textStyle: TextStyle(color: textColor),
                          ),
                          series: <CartesianSeries>[
                            // Courbe des Entrants (opérations)
                            SplineSeries<ChartData, String>(
                              name: 'Entrants',
                              dataSource: dataSet.operations,
                              xValueMapper: (ChartData data, _) => data.label,
                              yValueMapper: (ChartData data, _) => data.value,
                              color: AppColors.success,
                              width: 3,
                              animationDuration: 1500,
                              splineType: SplineType.natural,
                              markerSettings: const MarkerSettings(
                                isVisible: true,
                                shape: DataMarkerType.circle,
                                width: 8,
                                height: 8,
                                color: Colors.white,
                                borderColor: AppColors.success,
                                borderWidth: 2,
                              ),
                            ),
                            // Courbe des Prélèvements
                            SplineSeries<ChartData, String>(
                              name: 'Prélèvements',
                              dataSource: dataSet.prelevements,
                              xValueMapper: (ChartData data, _) => data.label,
                              yValueMapper: (ChartData data, _) => data.value,
                              color: AppColors.accent,
                              width: 3,
                              animationDuration: 1500,
                              animationDelay: 300,
                              splineType: SplineType.natural,
                              markerSettings: const MarkerSettings(
                                isVisible: true,
                                shape: DataMarkerType.diamond,
                                width: 8,
                                height: 8,
                                color: Colors.white,
                                borderColor: AppColors.accent,
                                borderWidth: 2,
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

  Future<ChartDataSet> _getWeeklyData(MainController controller) async {
    final List<ChartData> operationsData = [];
    final List<ChartData> prelevementsData = [];
    final today = controller.currentDate;
    final dayNames = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayLabel = dayNames[date.weekday - 1];

      // Récupérer les opérations (entrants)
      final operations = await controller.getOperationsByDate(date);
      double totalOperations = 0;
      for (var op in operations) {
        totalOperations += op.prixOperation * op.quantiteOperation;
      }
      operationsData.add(ChartData(dayLabel, totalOperations));

      // Récupérer les prélèvements
      final prelevements = await controller.getPrelevementsByDate(date);
      double totalPrelevements = 0;
      for (var prel in prelevements) {
        totalPrelevements += prel.montant;
      }
      prelevementsData.add(ChartData(dayLabel, totalPrelevements));
    }

    return ChartDataSet(
      operations: operationsData,
      prelevements: prelevementsData,
    );
  }
}

/// Widget de légende pour le graphique
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }
}

/// Ensemble de données pour le graphique
class ChartDataSet {
  final List<ChartData> operations;
  final List<ChartData> prelevements;

  ChartDataSet({
    required this.operations,
    required this.prelevements,
  });
}

/// Modèle de données pour le graphique
class ChartData {
  final String label;
  final double value;

  ChartData(this.label, this.value);
}

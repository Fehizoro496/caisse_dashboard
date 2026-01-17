import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/core/theme/responsive.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:caisse_dashboard/view/widgets/stat_card.dart';
import 'package:caisse_dashboard/view/widgets/date_navigator.dart';
import 'package:caisse_dashboard/view/widgets/charts/income_chart.dart';
import 'package:caisse_dashboard/view/widgets/charts/expense_pie_chart.dart';
import 'package:caisse_dashboard/view/widgets/animated/fade_slide_widget.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});
  final MainController mainController = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      builder: (controller) {
        return GetBuilder<ThemeController>(
          builder: (themeController) {
            final isDark = themeController.isDarkMode;

            return Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? AppColors.darkBackgroundGradient
                    : AppColors.lightBackgroundGradient,
              ),
              child: SafeArea(
                child: Responsive.builder(
                  context: context,
                  builder: (context, deviceType) {
                    final padding = context.responsive(
                      mobile: 12.0,
                      tablet: 16.0,
                      desktop: 24.0,
                    );

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: padding,
                        vertical: 12,
                      ),
                      child: _buildLayout(context, controller, deviceType),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLayout(
    BuildContext context,
    MainController controller,
    DeviceType deviceType,
  ) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileLayout(context, controller);
      case DeviceType.tablet:
        return _buildTabletLayout(context, controller);
      case DeviceType.desktop:
        return _buildDesktopLayout(context, controller);
    }
  }

  /// Layout Desktop : 4 colonnes en haut + 3 colonnes en bas
  Widget _buildDesktopLayout(BuildContext context, MainController controller) {
    return Column(
      children: [
        // Top row: Date Navigator + 3 Stat Cards
        SizedBox(
          height: 85,
          child: Row(
            children: [
              const Expanded(flex: 2, child: DateNavigator()),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Entrant',
                  valueFuture: controller.getAmountOperations(),
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.success,
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Sortant',
                  valueFuture: controller.getAmountExpenses(),
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.error,
                  index: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Prélèvement',
                  valueFuture: controller.getAmountPrelevement(),
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: AppColors.accent,
                  index: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Main content: 3 columns
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Operations list
              Expanded(
                child: FadeSlideWidget(
                  index: 0,
                  child: _buildOperationsList(context, controller),
                ),
              ),
              const SizedBox(width: 12),
              // Expenses list
              Expanded(
                child: FadeSlideWidget(
                  index: 1,
                  child: _buildExpensesList(context, controller),
                ),
              ),
              const SizedBox(width: 12),
              // Charts column
              const Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: FadeSlideWidget(
                        index: 2,
                        child: IncomeChart(),
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: FadeSlideWidget(
                        index: 3,
                        child: ExpensePieChart(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout Tablet : Stats en ligne + 2 colonnes de contenu
  Widget _buildTabletLayout(BuildContext context, MainController controller) {
    return Column(
      children: [
        // Date navigator full width
        const SizedBox(height: 65, child: DateNavigator()),
        const SizedBox(height: 12),
        // 3 stat cards in row
        SizedBox(
          height: 75,
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Entrant',
                  valueFuture: controller.getAmountOperations(),
                  icon: Icons.arrow_downward_rounded,
                  accentColor: AppColors.success,
                  index: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Sortant',
                  valueFuture: controller.getAmountExpenses(),
                  icon: Icons.arrow_upward_rounded,
                  accentColor: AppColors.error,
                  index: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Prélèvement',
                  valueFuture: controller.getAmountPrelevement(),
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: AppColors.accent,
                  index: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 2 columns: lists and charts
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _buildOperationsList(context, controller)),
                    const SizedBox(height: 12),
                    Expanded(child: _buildExpensesList(context, controller)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  children: [
                    Expanded(child: IncomeChart()),
                    SizedBox(height: 12),
                    Expanded(child: ExpensePieChart()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout Mobile : Tout empilé verticalement avec scroll
  Widget _buildMobileLayout(BuildContext context, MainController controller) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const DateNavigator(compact: true),
          const SizedBox(height: 12),
          // Stat cards en scroll horizontal
          SizedBox(
            height: 75,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(
                  width: 150,
                  child: StatCard(
                    title: 'Entrant',
                    valueFuture: controller.getAmountOperations(),
                    icon: Icons.arrow_downward_rounded,
                    accentColor: AppColors.success,
                    index: 0,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: StatCard(
                    title: 'Sortant',
                    valueFuture: controller.getAmountExpenses(),
                    icon: Icons.arrow_upward_rounded,
                    accentColor: AppColors.error,
                    index: 1,
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 150,
                  child: StatCard(
                    title: 'Prélèvement',
                    valueFuture: controller.getAmountPrelevement(),
                    icon: Icons.account_balance_wallet_rounded,
                    accentColor: AppColors.accent,
                    index: 2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stacked cards for mobile
          SizedBox(
            height: 280,
            child: _buildOperationsList(context, controller),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: _buildExpensesList(context, controller),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 220, child: IncomeChart()),
          const SizedBox(height: 12),
          const SizedBox(height: 260, child: ExpensePieChart()),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Widget de liste des opérations
  Widget _buildOperationsList(BuildContext context, MainController controller) {
    final isDark = Get.find<ThemeController>().isDarkMode;
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
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Opérations',
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
            child: FutureBuilder(
              future: controller.getOperationsByDate(controller.currentDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_rounded,
                          size: 48,
                          color: secondaryTextColor.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune opération',
                          style: TextStyle(color: secondaryTextColor),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => Divider(
                    color: secondaryTextColor.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final op = snapshot.data![index];
                    return _AnimatedListItem(
                      index: index,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${op.nomOperation} x${op.quantiteOperation}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${formatNumber(op.quantiteOperation * op.prixOperation)} Ar',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          '${op.dateOperation.hour.toString().padLeft(2, '0')}:${op.dateOperation.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Widget de liste des dépenses
  Widget _buildExpensesList(BuildContext context, MainController controller) {
    final isDark = Get.find<ThemeController>().isDarkMode;
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Dépenses',
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
            child: FutureBuilder(
              future: controller.getDepensesByDate(controller.currentDate),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.error),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.money_off_rounded,
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
                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: snapshot.data!.length,
                  separatorBuilder: (_, __) => Divider(
                    color: secondaryTextColor.withValues(alpha: 0.2),
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final dep = snapshot.data![index];
                    return _AnimatedListItem(
                      index: index,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          dep.libelle,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${formatNumber(dep.montant)} Ar',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Text(
                          '${dep.dateDepense.hour.toString().padLeft(2, '0')}:${dep.dateDepense.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget pour animer chaque item de liste
class _AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;

  const _AnimatedListItem({required this.index, required this.child});

  @override
  State<_AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<_AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

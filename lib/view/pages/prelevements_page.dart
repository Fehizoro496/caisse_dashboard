import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class PrelevementsPage extends StatefulWidget {
  const PrelevementsPage({super.key});

  @override
  State<PrelevementsPage> createState() => _PrelevementsPageState();
}

class _PrelevementsPageState extends State<PrelevementsPage> {
  final MainController _controller = Get.find<MainController>();

  List<Prelevement> _allPrelevements = [];
  List<Prelevement> _filteredPrelevements = [];
  bool _isLoading = true;
  String _sortBy = 'date';
  bool _sortAscending = false;

  // Filter by month
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPrelevements();
  }

  Future<void> _loadPrelevements() async {
    setState(() => _isLoading = true);
    final prelevements = await _controller.dbService.getAllPrelevements();
    setState(() {
      _allPrelevements = prelevements;
      _applyFilters();
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredPrelevements = _allPrelevements.where((p) {
        return p.datePrelevement.year == _selectedMonth.year &&
            p.datePrelevement.month == _selectedMonth.month;
      }).toList();
      _sortPrelevements();
    });
  }

  void _sortPrelevements() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredPrelevements.sort((a, b) => _sortAscending
              ? a.datePrelevement.compareTo(b.datePrelevement)
              : b.datePrelevement.compareTo(a.datePrelevement));
          break;
        case 'amount':
          _filteredPrelevements.sort((a, b) => _sortAscending
              ? a.montant.compareTo(b.montant)
              : b.montant.compareTo(a.montant));
          break;
      }
    });
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;
        final textColor = isDark ? AppColors.darkText : AppColors.lightText;
        final secondaryTextColor =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

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
                  _buildMonthSelector(textColor, secondaryTextColor, isDark),
                  _buildSortOptions(textColor, secondaryTextColor, isDark),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.accent,
                            ),
                          )
                        : _buildPrelevementsList(
                            textColor, secondaryTextColor, isDark),
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
    final total =
        _filteredPrelevements.fold<int>(0, (sum, p) => sum + p.montant);

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
                  'Prélèvements',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_filteredPrelevements.length} entrées - Total: ${formatNumber(total)} Ar',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.accentGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(
      Color textColor, Color secondaryTextColor, bool isDark) {
    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left_rounded),
              color: AppColors.accent,
            ),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedMonth,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDatePickerMode: DatePickerMode.year,
                );
                if (picked != null) {
                  setState(() {
                    _selectedMonth = picked;
                    _applyFilters();
                  });
                }
              },
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    monthName.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _selectedMonth.year == DateTime.now().year &&
                      _selectedMonth.month == DateTime.now().month
                  ? null
                  : () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right_rounded),
              color: AppColors.accent,
              disabledColor: secondaryTextColor.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOptions(
      Color textColor, Color secondaryTextColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text('Trier par:', style: TextStyle(color: secondaryTextColor)),
          const SizedBox(width: 12),
          _buildSortChip('Date', 'date', isDark),
          const SizedBox(width: 8),
          _buildSortChip('Montant', 'amount', isDark),
          const Spacer(),
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
                _sortPrelevements();
              });
            },
            icon: Icon(
              _sortAscending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(String label, String value, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
          _sortPrelevements();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
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

  Widget _buildPrelevementsList(
      Color textColor, Color secondaryTextColor, bool isDark) {
    if (_filteredPrelevements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun prélèvement ce mois',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date
    final groupedPrelevements = <String, List<Prelevement>>{};
    for (final p in _filteredPrelevements) {
      final dateKey = DateFormat('dd MMMM yyyy', 'fr_FR').format(p.datePrelevement);
      groupedPrelevements.putIfAbsent(dateKey, () => []).add(p);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: groupedPrelevements.length,
      itemBuilder: (context, index) {
        final dateKey = groupedPrelevements.keys.elementAt(index);
        final prelevements = groupedPrelevements[dateKey]!;
        final dayTotal =
            prelevements.fold<int>(0, (sum, p) => sum + p.montant);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    dateKey,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatNumber(dayTotal)} Ar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            GlassCard(
              padding: EdgeInsets.zero,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: prelevements.length,
                separatorBuilder: (_, __) => Divider(
                  color: secondaryTextColor.withValues(alpha: 0.2),
                  height: 1,
                ),
                itemBuilder: (context, pIndex) {
                  final p = prelevements[pIndex];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Prélèvement',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      DateFormat('HH:mm').format(p.datePrelevement),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Text(
                      '${formatNumber(p.montant)} Ar',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}

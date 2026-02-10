import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class DepensesPage extends StatefulWidget {
  const DepensesPage({super.key});

  @override
  State<DepensesPage> createState() => _DepensesPageState();
}

class _DepensesPageState extends State<DepensesPage> {
  final MainController _controller = Get.find<MainController>();
  final TextEditingController _searchController = TextEditingController();

  List<Depense> _allDepenses = [];
  List<Depense> _filteredDepenses = [];
  bool _isLoading = true;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadDepenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepenses() async {
    setState(() => _isLoading = true);
    final depenses = await _controller.dbService.getAllDepenses();
    setState(() {
      _allDepenses = depenses;
      _filteredDepenses = depenses;
      _sortDepenses();
      _isLoading = false;
    });
  }

  void _filterDepenses(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDepenses = _allDepenses;
      } else {
        _filteredDepenses = _allDepenses
            .where((dep) =>
                dep.libelle.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _sortDepenses();
    });
  }

  void _sortDepenses() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredDepenses.sort((a, b) => _sortAscending
              ? a.dateDepense.compareTo(b.dateDepense)
              : b.dateDepense.compareTo(a.dateDepense));
          break;
        case 'name':
          _filteredDepenses.sort((a, b) => _sortAscending
              ? a.libelle.compareTo(b.libelle)
              : b.libelle.compareTo(a.libelle));
          break;
        case 'amount':
          _filteredDepenses.sort((a, b) => _sortAscending
              ? a.montant.compareTo(b.montant)
              : b.montant.compareTo(a.montant));
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
                  _buildSearchAndFilter(textColor, secondaryTextColor, isDark),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.error,
                            ),
                          )
                        : _buildDepensesList(
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
    final total = _filteredDepenses.fold<int>(0, (sum, dep) => sum + dep.montant);

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
                  'Dépenses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_filteredDepenses.length} entrées - Total: ${formatNumber(total)} Ar',
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
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.payments_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(
      Color textColor, Color secondaryTextColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterDepenses,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Rechercher une dépense...',
                hintStyle: TextStyle(color: secondaryTextColor),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Trier par:', style: TextStyle(color: secondaryTextColor)),
                const SizedBox(width: 12),
                _buildSortChip('Date', 'date', isDark),
                const SizedBox(width: 8),
                _buildSortChip('Libellé', 'name', isDark),
                const SizedBox(width: 8),
                _buildSortChip('Montant', 'amount', isDark),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortDepenses();
                    });
                  },
                  icon: Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                  tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
                ),
              ],
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
          _sortDepenses();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error
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

  Widget _buildDepensesList(
      Color textColor, Color secondaryTextColor, bool isDark) {
    if (_filteredDepenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.money_off_rounded,
              size: 64,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune dépense trouvée',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group depenses by date
    final groupedDepenses = <String, List<Depense>>{};
    for (final dep in _filteredDepenses) {
      final dateKey = DateFormat('dd MMMM yyyy', 'fr_FR').format(dep.dateDepense);
      groupedDepenses.putIfAbsent(dateKey, () => []).add(dep);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: groupedDepenses.length,
      itemBuilder: (context, index) {
        final dateKey = groupedDepenses.keys.elementAt(index);
        final depenses = groupedDepenses[dateKey]!;
        final dayTotal = depenses.fold<int>(0, (sum, dep) => sum + dep.montant);

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
                      color: AppColors.error,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '-${formatNumber(dayTotal)} Ar',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.error,
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
                itemCount: depenses.length,
                separatorBuilder: (_, __) => Divider(
                  color: secondaryTextColor.withValues(alpha: 0.2),
                  height: 1,
                ),
                itemBuilder: (context, depIndex) {
                  final dep = depenses[depIndex];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      dep.libelle,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '-${formatNumber(dep.montant)} Ar',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${dep.dateDepense.hour.toString().padLeft(2, '0')}:${dep.dateDepense.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
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

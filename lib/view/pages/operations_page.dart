import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';
import 'package:intl/intl.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});

  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  final MainController _controller = Get.find<MainController>();
  final TextEditingController _searchController = TextEditingController();

  List<Operation> _allOperations = [];
  List<Operation> _filteredOperations = [];
  bool _isLoading = true;
  String _sortBy = 'date';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOperations() async {
    setState(() => _isLoading = true);
    final operations = await _controller.dbService.getAllOperations();
    setState(() {
      _allOperations = operations;
      _filteredOperations = operations;
      _sortOperations();
      _isLoading = false;
    });
  }

  void _filterOperations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredOperations = _allOperations;
      } else {
        _filteredOperations = _allOperations
            .where((op) =>
                op.nomOperation.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      _sortOperations();
    });
  }

  void _sortOperations() {
    setState(() {
      switch (_sortBy) {
        case 'date':
          _filteredOperations.sort((a, b) => _sortAscending
              ? a.dateOperation.compareTo(b.dateOperation)
              : b.dateOperation.compareTo(a.dateOperation));
          break;
        case 'name':
          _filteredOperations.sort((a, b) => _sortAscending
              ? a.nomOperation.compareTo(b.nomOperation)
              : b.nomOperation.compareTo(a.nomOperation));
          break;
        case 'amount':
          _filteredOperations.sort((a, b) {
            final totalA = a.prixOperation * a.quantiteOperation;
            final totalB = b.prixOperation * b.quantiteOperation;
            return _sortAscending
                ? totalA.compareTo(totalB)
                : totalB.compareTo(totalA);
          });
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
                              color: AppColors.primary,
                            ),
                          )
                        : _buildOperationsList(
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
    final total = _filteredOperations.fold<int>(
        0, (sum, op) => sum + (op.prixOperation * op.quantiteOperation));

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
                  'Opérations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  '${_filteredOperations.length} entrées - Total: ${formatNumber(total)} Ar',
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
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
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
              onChanged: _filterOperations,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Rechercher une opération...',
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
                _buildSortChip('Nom', 'name', isDark),
                const SizedBox(width: 8),
                _buildSortChip('Montant', 'amount', isDark),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _sortOperations();
                    });
                  },
                  icon: Icon(
                    _sortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    color: AppColors.primary,
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
          _sortOperations();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
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

  Widget _buildOperationsList(
      Color textColor, Color secondaryTextColor, bool isDark) {
    if (_filteredOperations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 64,
              color: secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune opération trouvée',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Group operations by date
    final groupedOperations = <String, List<Operation>>{};
    for (final op in _filteredOperations) {
      final dateKey = DateFormat('dd MMMM yyyy', 'fr_FR').format(op.dateOperation);
      groupedOperations.putIfAbsent(dateKey, () => []).add(op);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: groupedOperations.length,
      itemBuilder: (context, index) {
        final dateKey = groupedOperations.keys.elementAt(index);
        final operations = groupedOperations[dateKey]!;
        final dayTotal = operations.fold<int>(
            0, (sum, op) => sum + (op.prixOperation * op.quantiteOperation));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Text(
                    dateKey,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatNumber(dayTotal)} Ar',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.success,
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
                itemCount: operations.length,
                separatorBuilder: (_, __) => Divider(
                  color: secondaryTextColor.withValues(alpha: 0.2),
                  height: 1,
                ),
                itemBuilder: (context, opIndex) {
                  final op = operations[opIndex];
                  final total = op.prixOperation * op.quantiteOperation;
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.success,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      op.nomOperation,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${formatNumber(op.prixOperation)} Ar x ${op.quantiteOperation}',
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatNumber(total)} Ar',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${op.dateOperation.hour.toString().padLeft(2, '0')}:${op.dateOperation.minute.toString().padLeft(2, '0')}',
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

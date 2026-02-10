import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/core/routes/app_routes.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  MyAppBar({super.key});
  final MainController mainController = Get.find<MainController>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;

        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      // Logo/Title avec gradient
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.primaryGradient.createShader(bounds),
                        child: const Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Menu rapide
                      _QuickMenu(isDark: isDark),
                      const SizedBox(width: 12),
                      // Bouton Import
                      _GlassButton(
                        onPressed: () => mainController.syncDatabase(),
                        icon: Icons.cloud_upload_outlined,
                        label: 'Import',
                      ),
                      const SizedBox(width: 12),
                      // Toggle Theme
                      _ThemeToggle(
                        isDark: isDark,
                        onToggle: () => themeController.toggleTheme(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight * 2);
}

/// Bouton glassmorphism avec gradient
class _GlassButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Toggle animé pour le thème clair/sombre
class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 56,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDark
                  ? [AppColors.primaryDark, AppColors.primary]
                  : [AppColors.primaryLight, AppColors.accent],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Indicateur animé
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                left: isDark ? 28 : 4,
                top: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        key: ValueKey(isDark),
                        size: 14,
                        color: isDark
                            ? AppColors.primaryDark
                            : AppColors.warning,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu rapide pour accéder aux différentes pages
class _QuickMenu extends StatelessWidget {
  final bool isDark;

  const _QuickMenu({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.menu_rounded,
          color: isDark ? AppColors.darkText : AppColors.lightText,
          size: 20,
        ),
      ),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      onSelected: (value) => Get.toNamed(value),
      itemBuilder: (context) => [
        _buildMenuItem(
          route: AppRoutes.operations,
          icon: Icons.receipt_long_rounded,
          label: 'Opérations',
          color: AppColors.success,
        ),
        _buildMenuItem(
          route: AppRoutes.depenses,
          icon: Icons.payments_rounded,
          label: 'Dépenses',
          color: AppColors.error,
        ),
        _buildMenuItem(
          route: AppRoutes.prelevements,
          icon: Icons.account_balance_wallet_rounded,
          label: 'Prélèvements',
          color: AppColors.accent,
        ),
        const PopupMenuDivider(),
        _buildMenuItem(
          route: AppRoutes.releves,
          icon: Icons.electric_bolt_rounded,
          label: 'Relevés Électricité',
          color: AppColors.warning,
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem({
    required String route,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return PopupMenuItem<String>(
      value: route,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.darkText : AppColors.lightText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

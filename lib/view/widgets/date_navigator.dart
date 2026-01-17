import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';
import 'package:caisse_dashboard/utils/which_day.dart';
import 'package:caisse_dashboard/view/widgets/glass_card.dart';

/// Navigateur de date avec boutons précédent/suivant et sélecteur
class DateNavigator extends StatelessWidget {
  final bool compact;

  const DateNavigator({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      builder: (controller) {
        return GlassCard(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 16,
            vertical: compact ? 4 : 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedNavButton(
                icon: Icons.arrow_back_ios_new,
                onPressed: () => controller.previousDay(),
                tooltip: 'Jour précédent',
                compact: compact,
              ),
              SizedBox(width: compact ? 4 : 8),
              Expanded(
                child: _DateButton(
                  date: controller.currentDate,
                  onTap: () => controller.setDate(context),
                  compact: compact,
                ),
              ),
              SizedBox(width: compact ? 4 : 8),
              _AnimatedNavButton(
                icon: Icons.arrow_forward_ios,
                onPressed: () => controller.nextDay(),
                tooltip: 'Jour suivant',
                compact: compact,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bouton de navigation animé avec effet hover
class _AnimatedNavButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool compact;

  const _AnimatedNavButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.compact = false,
  });

  @override
  State<_AnimatedNavButton> createState() => _AnimatedNavButtonState();
}

class _AnimatedNavButtonState extends State<_AnimatedNavButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
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
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: IconButton(
          tooltip: widget.tooltip,
          onPressed: widget.onPressed,
          iconSize: widget.compact ? 18 : 22,
          padding: EdgeInsets.all(widget.compact ? 4 : 8),
          constraints: BoxConstraints(
            minWidth: widget.compact ? 32 : 40,
            minHeight: widget.compact ? 32 : 40,
          ),
          icon: Icon(
            widget.icon,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// Bouton de sélection de date avec gradient
class _DateButton extends StatefulWidget {
  final DateTime date;
  final VoidCallback onTap;
  final bool compact;

  const _DateButton({
    required this.date,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<_DateButton>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final day = whichDay(date) ?? '';
    final dateStr = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return widget.compact ? dateStr : '$day $dateStr';
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 12 : 20,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: widget.compact ? 14 : 16,
                ),
                SizedBox(width: widget.compact ? 6 : 8),
                Flexible(
                  child: Text(
                    _formatDate(widget.date),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.compact ? 12 : 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

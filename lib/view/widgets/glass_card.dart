import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_colors.dart';

/// Carte avec effet glassmorphism (verre dépoli)
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool animate;
  final Duration animationDuration;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.15,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.gradient,
    this.onTap,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 400),
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        final isDark = themeController.isDarkMode;

        Widget card = Container(
          margin: margin,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: padding ?? const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: gradient,
                  color: gradient == null
                      ? (isDark
                          ? Colors.white.withValues(alpha: opacity)
                          : Colors.white.withValues(alpha: opacity + 0.6))
                      : null,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      spreadRadius: -5,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        );

        if (onTap != null) {
          card = _HoverScaleWidget(
            onTap: onTap!,
            child: card,
          );
        }

        if (animate) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.0),
            duration: animationDuration,
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: card,
          );
        }

        return card;
      },
    );
  }
}

/// Widget interne pour effet de hover avec scale
class _HoverScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverScaleWidget({
    required this.child,
    required this.onTap,
  });

  @override
  State<_HoverScaleWidget> createState() => _HoverScaleWidgetState();
}

class _HoverScaleWidgetState extends State<_HoverScaleWidget>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Variante de GlassCard avec gradient prédéfini
class GradientGlassCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;

  const GradientGlassCard({
    super.key,
    required this.child,
    this.gradient = AppColors.primaryGradient,
    this.borderRadius = 16.0,
    this.padding,
    this.margin,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      gradient: gradient,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      onTap: onTap,
      child: child,
    );
  }
}

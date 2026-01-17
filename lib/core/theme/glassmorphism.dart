import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Utilitaires pour créer des effets glassmorphism
class Glassmorphism {
  Glassmorphism._();

  /// Crée une décoration de type verre dépoli
  static BoxDecoration decoration({
    bool isDark = false,
    double borderRadius = 16.0,
    double opacity = 0.15,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: opacity)
          : Colors.white.withValues(alpha: opacity + 0.6),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ??
            (isDark ? AppColors.glassBorderDark : AppColors.glassBorderLight),
        width: 1.5,
      ),
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, 10),
            ),
          ],
    );
  }

  /// Crée une décoration avec gradient
  static BoxDecoration gradientDecoration({
    required Gradient gradient,
    double borderRadius = 16.0,
    Color? borderColor,
    List<BoxShadow>? boxShadow,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: 1.5)
          : null,
      boxShadow: boxShadow ??
          [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
    );
  }

  /// Widget container avec effet de flou
  static Widget blurContainer({
    required Widget child,
    bool isDark = false,
    double blur = 10.0,
    double opacity = 0.15,
    double borderRadius = 16.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: decoration(
              isDark: isDark,
              borderRadius: borderRadius,
              opacity: opacity,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

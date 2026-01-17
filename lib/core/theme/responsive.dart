import 'package:flutter/material.dart';

/// Types d'appareils supportés
enum DeviceType { mobile, tablet, desktop }

/// Utilitaires pour le design responsive
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  /// Retourne le type d'appareil basé sur la largeur de l'écran
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  /// Vérifie si l'appareil est mobile
  static bool isMobile(BuildContext context) =>
      getDeviceType(context) == DeviceType.mobile;

  /// Vérifie si l'appareil est une tablette
  static bool isTablet(BuildContext context) =>
      getDeviceType(context) == DeviceType.tablet;

  /// Vérifie si l'appareil est un desktop
  static bool isDesktop(BuildContext context) =>
      getDeviceType(context) == DeviceType.desktop;

  /// Retourne une valeur différente selon le type d'appareil
  static T value<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    switch (getDeviceType(context)) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? desktop;
      case DeviceType.desktop:
        return desktop;
    }
  }

  /// Widget builder responsive
  static Widget builder({
    required BuildContext context,
    required Widget Function(BuildContext context, DeviceType deviceType)
        builder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, getDeviceType(context));
      },
    );
  }
}

/// Extension pour un accès plus simple via context
extension ResponsiveExtension on BuildContext {
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  DeviceType get deviceType => Responsive.getDeviceType(this);

  /// Retourne une valeur selon le type d'appareil
  T responsive<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    return Responsive.value(
      context: this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

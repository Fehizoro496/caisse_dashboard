import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôleur pour gérer le thème de l'application (clair/sombre)
class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  final _isDarkMode = false.obs;

  /// Retourne true si le mode sombre est actif
  bool get isDarkMode => _isDarkMode.value;

  /// Retourne le ThemeMode actuel pour GetMaterialApp
  ThemeMode get themeMode =>
      _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  /// Charge le thème depuis les préférences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode.value = prefs.getBool(_themeKey) ?? false;
      Get.changeThemeMode(themeMode);
      update();
    } catch (e) {
      debugPrint('Erreur chargement thème: $e');
    }
  }

  /// Bascule entre le mode clair et sombre
  Future<void> toggleTheme() async {
    _isDarkMode.value = !_isDarkMode.value;
    Get.changeThemeMode(themeMode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, _isDarkMode.value);
    } catch (e) {
      debugPrint('Erreur sauvegarde thème: $e');
    }

    update();
  }

  /// Définit explicitement le mode sombre
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode.value == isDark) return;

    _isDarkMode.value = isDark;
    Get.changeThemeMode(themeMode);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themeKey, isDark);
    } catch (e) {
      debugPrint('Erreur sauvegarde thème: $e');
    }

    update();
  }
}

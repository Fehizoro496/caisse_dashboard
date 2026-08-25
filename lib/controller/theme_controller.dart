import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contrôleur d'apparence : thème clair/sombre, persisté d'une session
/// à l'autre.
class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';

  bool _isDarkMode = false;

  /// Retourne true si le mode sombre est actif
  bool get isDarkMode => _isDarkMode;

  /// Retourne le ThemeMode actuel pour GetMaterialApp
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      Get.changeThemeMode(themeMode);
      update();
    } catch (e) {
      debugPrint('Erreur chargement thème: $e');
    }
  }

  /// Bascule entre le mode clair et sombre
  Future<void> toggleTheme() => setDarkMode(!_isDarkMode);

  /// Définit explicitement le mode sombre
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    Get.changeThemeMode(themeMode);
    update();
    await _save(_themeKey, (p) => p.setBool(_themeKey, isDark));
  }

  Future<void> _save(
    String what,
    Future<void> Function(SharedPreferences) write,
  ) async {
    try {
      await write(await SharedPreferences.getInstance());
    } catch (e) {
      debugPrint('Erreur sauvegarde $what: $e');
    }
  }
}

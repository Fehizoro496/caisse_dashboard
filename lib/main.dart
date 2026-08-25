import 'package:caisse_dashboard/controller/caisse_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/jiro_invoice_service.dart';
import 'package:caisse_dashboard/service/sync_service.dart';
import 'package:caisse_dashboard/view/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Initialize Services
  await Get.putAsync(() => DBService().init());
  await Get.putAsync(() => SyncService().init());
  await Get.putAsync(() => JiroInvoiceService().init());

  // Initialize Controllers
  Get.put(ThemeController());
  Get.put(CaisseController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (themeController) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Caisse Dashboard',

          // Un seul jeu de jetons pilote les deux thèmes.
          theme: buildAppTheme(brightness: Brightness.light),
          darkTheme: buildAppTheme(brightness: Brightness.dark),
          themeMode: themeController.themeMode,

          locale: const Locale('fr', 'FR'),
          fallbackLocale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', 'FR')],

          home: const HomePage(),
        );
      },
    );
  }
}

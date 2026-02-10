import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/theme/app_theme.dart';
import 'package:caisse_dashboard/core/routes/app_routes.dart';
import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/sync_service.dart';
import 'package:caisse_dashboard/view/components/my_appbar.dart';
import 'package:caisse_dashboard/view/main_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize locale for date formatting
  await initializeDateFormatting('fr_FR', null);

  // Initialize Services
  await Get.putAsync(() => DBService().init());
  await Get.putAsync(() => SyncService().init());

  // Initialize Controllers
  Get.put(ThemeController());
  Get.put(MainController());

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

          // Thèmes light/dark avec palette violet/indigo
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: themeController.themeMode,

          // Routes
          initialRoute: AppRoutes.home,
          getPages: AppRoutes.pages,

          // Home page with AppBar
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: MyAppBar(),
            body: MainPage(),
          ),
        );
      },
    );
  }
}

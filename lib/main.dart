import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/sync_service.dart';
import 'package:caisse_dashboard/view/components/my_appbar.dart';
// import 'package:caisse_dashboard/view/components/my_drawer.dart';
import 'package:caisse_dashboard/view/main_page.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

void main() async {
  // Ensure widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Services
  await Get.putAsync(() => DBService().init());
  await Get.putAsync(() => SyncService().init());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      // title: 'Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: MyAppBar(),
        // drawer: const MyDrawer(),
        extendBody: true,
        body: MainPage(),
      ),
    );
  }
}

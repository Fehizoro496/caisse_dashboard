import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  MyAppBar({super.key});
  final MainController mainController = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    return AppBar(
      foregroundColor: Colors.white,
      centerTitle: true,
      backgroundColor: Colors.blue,
      actions: [
        ElevatedButton(
          onPressed: () {
            mainController.syncDatabase();
          },
          child: const Text('Import'),
        ),
      ],
      title: const Text('Dashboard'),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

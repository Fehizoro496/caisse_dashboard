import 'dart:io';

import 'package:caisse_dashboard/persistance/database.dart';
import 'package:caisse_dashboard/service/db_service.dart';
import 'package:caisse_dashboard/service/sync_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  DateTime currentDate = DateTime.now();
  final DBService dbService = DBService();
  final SyncService syncService = SyncService();

  @override
  void onInit() async {
    currentDate = await dbService.getLastInsertDate();
    update();
    super.onInit();
  }

  void setDate(BuildContext context) async {
    currentDate = await showDatePicker(
            // locale: Locale('fr', 'CH'),
            context: context,
            initialDate: currentDate,
            firstDate: DateTime(2020, 1),
            lastDate: DateTime.now()) ??
        DateTime.now();
    update();
  }

  void previousDay() {
    currentDate = currentDate.subtract(const Duration(days: 1));
    update();
  }

  void nextDay() {
    currentDate = currentDate.add(const Duration(days: 1));
    update();
  }

  Future<double> getAmountOperations() async {
    double out = 0;
    List<Operation> temp = await getOperationsByDate(currentDate);
    for (var op in temp) {
      out += (op.prixOperation * op.quantiteOperation);
    }
    return out;
  }

  Future<double> getAmountExpenses() async {
    double out = 0;
    List<Depense> temp = await getDepensesByDate(currentDate);
    for (var dep in temp) {
      out += dep.montant;
    }
    return out;
  }

  Future<double> getAmountPrelevement() async {
    double out = 0;
    List<Prelevement> temp = await dbService.getPrelevementByDate(currentDate);
    for (var prel in temp) {
      out += prel.montant;
    }
    return out;
  }

  Future<List<Operation>> getOperations() {
    return dbService.getAllOperations();
  }

  Future<List<Operation>> getOperationsByDate(DateTime date) {
    return dbService.getOperationsByDate(date);
  }

  Future<List<Depense>> getDepensesByDate(DateTime date) {
    return dbService.getDepensesByDate(date);
  }

  Future<List<Depense>> getDepense() {
    return dbService.getAllDepenses();
  }

  void syncDatabase() async {
    FilePicker.platform.pickFiles().then((result) {
      if (result != null) {
        // print('file picked successfully');
        File file = File(result.files.single.path!);
        syncService.importAndMergeDatabase(file.path).then((value) {
          if (value) {
            // print('file imported succesfully');
            Get.snackbar(
              'Data importation success',
              'Data imported successfully!',
              snackPosition: SnackPosition.TOP,
              margin:
                  const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
              backgroundColor: const Color.fromARGB(175, 0, 225, 0),
              colorText: Colors.white,
            );
          }
          update();
        }).catchError((error) {
          Get.snackbar(
            "Erreur",
            "Une erreur est survenue lors de l'importation!",
            snackPosition: SnackPosition.TOP,
            margin:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
            backgroundColor: const Color.fromARGB(175, 255, 0, 0),
            colorText: Colors.white,
          );
        });
      }
    }).catchError((error) {
      Get.snackbar(
        "Erreur",
        error.toString(),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 70.0),
        backgroundColor: const Color.fromARGB(175, 255, 0, 0),
        colorText: Colors.white,
      );
    });
  }
}

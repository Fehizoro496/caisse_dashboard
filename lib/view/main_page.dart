import 'package:caisse_dashboard/controller/main_controller.dart';
import 'package:caisse_dashboard/utils/format_number.dart';
import 'package:caisse_dashboard/utils/which_day.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends StatelessWidget {
  MainPage({super.key});
  final MainController mainController = Get.put(MainController());

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(builder: (controller) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceTint.withOpacity(0.1),
        ),
        width: Get.width,
        height: Get.height,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              SizedBox(
                height: 75.0,
                width: Get.width,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      // flex: 3,
                      child: Card(
                        elevation: 0.0,
                        color: Colors.transparent,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                alignment: Alignment.centerRight,
                                onPressed: () => controller.previousDay(),
                                icon: Icon(Icons.arrow_back_ios_new,
                                    color: Theme.of(context).primaryColor)),
                            ElevatedButton(
                              style: ButtonStyle(
                                surfaceTintColor:
                                    MaterialStateProperty.all(Colors.white),
                              ),
                              onPressed: () {
                                controller.setDate(context);
                              },
                              child: Text(
                                  '${whichDay(controller.currentDate)} ${controller.currentDate.toString().split(' ')[0]}'),
                            ),
                            IconButton(
                                onPressed: () => controller.nextDay(),
                                icon: Icon(Icons.arrow_forward_ios,
                                    color: Theme.of(context).primaryColor)),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        elevation: 3.0,
                        shadowColor: Colors.blue,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.blue, Colors.lightBlue],
                            ),
                          ),
                          child: FutureBuilder(
                            builder: (context, snapshot) {
                              double amount = snapshot.data ?? 0;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Entrant',
                                      style: TextStyle(color: Colors.white)),
                                  Text('${formatNumber(amount.floor())} Ar',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              );
                            },
                            future: controller.getAmountOperations(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        elevation: 3.0,
                        shadowColor: Colors.blue,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.blue, Colors.lightBlue],
                            ),
                          ),
                          child: FutureBuilder(
                            builder: (context, snapshot) {
                              double amount = snapshot.data ?? 0;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Sortant',
                                      style: TextStyle(color: Colors.white)),
                                  Text('${formatNumber(amount.floor())} Ar',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              );
                            },
                            future: controller.getAmountExpenses(),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Card(
                        elevation: 3.0,
                        shadowColor: Colors.blue,
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.blue, Colors.lightBlue],
                            ),
                          ),
                          child: FutureBuilder(
                            builder: (context, snapshot) {
                              double amount = snapshot.data ?? 0;
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Prélèvement',
                                      style: TextStyle(color: Colors.white)),
                                  Text('${formatNumber(amount.floor())} Ar',
                                      style:
                                          const TextStyle(color: Colors.white)),
                                ],
                              );
                            },
                            future: controller.getAmountPrelevement(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5.0),
              Expanded(
                  child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Card(
                      elevation: 3.0,
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: FutureBuilder(
                          future: controller
                              .getOperationsByDate(controller.currentDate),
                          builder: ((context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data!.isNotEmpty) {
                              return ListView.builder(
                                  itemCount: snapshot.data?.length,
                                  itemBuilder: (context, index) {
                                    var operation = snapshot.data?[index];
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                              '${operation!.nomOperation} x${operation.quantiteOperation}'),
                                          subtitle: Text(
                                              '${formatNumber(operation.quantiteOperation * operation.prixOperation)} Ar'),
                                          trailing: Text(
                                              '${operation.dateOperation.hour / 10 < 1 ? '0' : ''}${operation.dateOperation.hour}:${operation.dateOperation.minute / 10 < 1 ? '0' : ''}${operation.dateOperation.minute}'),
                                        ),
                                        if (index !=
                                            (snapshot.data!.length - 1))
                                          const Divider(),
                                      ],
                                    );
                                  });
                            } else {
                              return const Center(
                                  child: Text('Aucune opération à afficher'));
                            }
                          })),
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Card(
                      elevation: 3.0,
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      child: FutureBuilder(
                          future: controller
                              .getDepensesByDate(controller.currentDate),
                          builder: ((context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasData &&
                                snapshot.data!.isNotEmpty) {
                              return ListView.builder(
                                  itemCount: snapshot.data?.length,
                                  itemBuilder: (context, index) {
                                    var depense = snapshot.data?[index];
                                    return Column(
                                      children: [
                                        ListTile(
                                          title: Text(depense!.libelle),
                                          subtitle: Text(
                                              '${formatNumber(depense.montant)} Ar'),
                                          trailing: Text(
                                              '${depense.dateDepense.hour}:${depense.dateDepense.minute}'),
                                        ),
                                        if (index !=
                                            (snapshot.data!.length - 1))
                                          const Divider(),
                                      ],
                                    );
                                  });
                            } else {
                              return const Center(
                                  child: Text('Aucune dépense à afficher'));
                            }
                          })),
                    ),
                  ),
                  const SizedBox(width: 5.0),
                  const Flexible(
                      flex: 1,
                      fit: FlexFit.tight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Card(
                              elevation: 3.0,
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              child: Text('4'),
                            ),
                          ),
                          SizedBox(
                            height: 5.0,
                          ),
                          Expanded(
                            child: Card(
                              elevation: 3.0,
                              color: Colors.white,
                              surfaceTintColor: Colors.white,
                              child: Text('5'),
                            ),
                          ),
                        ],
                      )),
                ],
              ))
            ],
          ),
        ),
      );
    });
  }
}

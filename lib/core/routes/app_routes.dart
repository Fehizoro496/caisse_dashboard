import 'package:get/get.dart';
import 'package:caisse_dashboard/view/main_page.dart';
import 'package:caisse_dashboard/view/pages/operations_page.dart';
import 'package:caisse_dashboard/view/pages/depenses_page.dart';
import 'package:caisse_dashboard/view/pages/prelevements_page.dart';
import 'package:caisse_dashboard/view/pages/releves_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String operations = '/operations';
  static const String depenses = '/depenses';
  static const String prelevements = '/prelevements';
  static const String releves = '/releves';

  static List<GetPage> get pages => [
        GetPage(
          name: home,
          page: () => MainPage(),
          transition: Transition.fadeIn,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: operations,
          page: () => const OperationsPage(),
          transition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: depenses,
          page: () => const DepensesPage(),
          transition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: prelevements,
          page: () => const PrelevementsPage(),
          transition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 300),
        ),
        GetPage(
          name: releves,
          page: () => const RelevesPage(),
          transition: Transition.rightToLeftWithFade,
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ];
}

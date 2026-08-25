import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart';
import 'package:caisse_dashboard/view/widgets/stat_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Le tableau de bord empile des bandes de hauteur contrainte. Il doit tenir
/// sur la plus petite fenêtre visée et quand le système agrandit le texte —
/// c'est ce dernier cas qui produisait des débordements de quelques pixels
/// chez l'utilisateur.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  final data = DashboardData(
    totals: const PeriodTotals(
      entrant: 760200,
      sortant: 185000,
      prelevement: 90000,
      nbOperations: 11,
      nbDepenses: 3,
      nbPrelevements: 1,
    ),
    previousTotals: const PeriodTotals(
      entrant: 900000,
      sortant: 100000,
      prelevement: 50000,
      nbOperations: 9,
      nbDepenses: 2,
      nbPrelevements: 1,
    ),
    operations: [
      for (var i = 0; i < 12; i++)
        const OperationRow(
          nom: 'Photocopie A4 N&B',
          prixUnitaire: 100,
          quantite: 9,
          total: 900,
          meta: '07h36',
        ),
    ],
    depenses: const [
      DepenseRow(libelle: 'Ramette A4', categorie: 'Papier', montant: 18500),
    ],
    trend: const [
      BarGroup(label: '15 août', primary: 125000, secondary: 40000),
      BarGroup(label: '16 août', primary: 39000, secondary: 0),
    ],
    repartition: const [('Papier', 18500)],
  );

  Widget harness(double textScale) => MaterialApp(
    theme: buildAppTheme(brightness: Brightness.light),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: Padding(
            padding: EdgeInsets.all(context.tokens.pad),
            child: DashboardScreen(
              data: data,
              date: DateTime(2026, 8, 21),
              period: Period.day,
              lastRecordDate: DateTime(2026, 8, 21),
              onPeriodChanged: (_) {},
              onDateChanged: (_) {},
              onOpenSection: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  const sizes = [
    // Sous 1180 px de large, la tête passe sur deux rangs : c'est ce mode,
    // atteint en redimensionnant la fenêtre, qui débordait.
    Size(900, 650),
    Size(1024, 700),
    Size(1280, 720),
    Size(1440, 900),
    Size(1920, 1080),
  ];
  // 1.0 = réglage par défaut ; 1.5 = « Agrandir le texte » de Windows au max.
  const textScales = [1.0, 1.15, 1.3, 1.5];

  for (final size in sizes) {
    for (final scale in textScales) {
      testWidgets(
        'dashboard ${size.width.toInt()}x${size.height.toInt()} · '
        'texte ×$scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(harness(scale));
          await tester.pump();

          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('sur deux rangs, la carte dépasse le plancher de la bande', (
    tester,
  ) async {
    // Le plancher esthétique vaut 104 px par rangée. La carte étant plus
    // haute que ça, une hauteur *imposée* de 104 la ferait déborder : c'est
    // bien IntrinsicHeight, et non le plancher, qui règle le problème.
    tester.view.physicalSize = const Size(1024, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(1.0));
    expect(tester.getSize(find.byType(SoldeNetCard)).height, greaterThan(104));
    expect(tester.takeException(), isNull);
  });

  testWidgets('la bande de tête grandit avec le texte au lieu de déborder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(1.0));
    final small = tester.getSize(find.byType(SoldeNetCard)).height;

    await tester.pumpWidget(harness(1.5));
    await tester.pump();
    final large = tester.getSize(find.byType(SoldeNetCard)).height;

    expect(tester.takeException(), isNull);
    expect(large, greaterThan(small));
  });
}

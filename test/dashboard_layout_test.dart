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

  /// Le cadrage Mois ajoute une quatrième carte de tête — celle des charges —
  /// et un bloc de plus dans le panneau des dépenses. C'est le cas le plus
  /// serré de la bande, donc celui qui déborde en premier.
  final dataMois = DashboardData(
    totals: const PeriodTotals(
      entrant: 760200,
      sortant: 185000,
      prelevement: 90000,
      nbOperations: 11,
      nbDepenses: 3,
      nbPrelevements: 1,
      charges: 480000,
      nbCharges: 3,
    ),
    previousTotals: data.previousTotals,
    operations: data.operations,
    depenses: data.depenses,
    chargesDuMois: const [
      DepenseRow(libelle: 'Loyer', categorie: 'Loyer', montant: 350000),
      DepenseRow(
        libelle: 'Facture JIRAMA',
        categorie: 'Électricité',
        montant: 95000,
      ),
      DepenseRow(
        libelle: 'Fournitures bureau',
        categorie: 'Fournitures',
        montant: 35000,
      ),
    ],
    trend: data.trend,
    repartition: const [('Loyer', 350000), ('Papier', 18500)],
  );

  Widget harness(
    double textScale, {
    Period period = Period.day,
    DashboardData? content,
  }) => MaterialApp(
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
              data: content ?? data,
              date: DateTime(2026, 8, 21),
              period: period,
              lastRecordDate: DateTime(2026, 8, 21),
              onPeriodChanged: (_) {},
              onDateChanged: (_) {},
              onOpenSection: (_) {},
              onToggleCharges: (_) {},
            ),
          ),
        ),
      ),
    ),
  );

  const sizes = [
    // La tête tient toujours sur deux rangs ; c'est en fenêtre étroite que
    // ses cartes sont le plus serrées, donc qu'elles débordaient.
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
      testWidgets('dashboard ${size.width.toInt()}x${size.height.toInt()} · '
          'texte ×$scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(harness(scale));
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('dashboard mois + charges ${size.width.toInt()}x'
          '${size.height.toInt()} · texte ×$scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          harness(scale, period: Period.month, content: dataMois),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('la carte Charges n\'existe qu\'au cadrage Mois', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(1.0));
    await tester.pump();
    expect(find.byType(TotalCard), findsNWidgets(3));
    expect(find.text('CHARGES'), findsNothing);

    await tester.pumpWidget(
      harness(1.0, period: Period.month, content: dataMois),
    );
    await tester.pump();
    expect(find.byType(TotalCard), findsNWidgets(4));
    expect(find.text('CHARGES'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('charges exclues : le montant reste, le solde remonte', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Ce que produit le contrôleur quand la bascule est sur « off » :
    // `totals.charges` retombe à 0, `chargesDuMois` reste peuplée.
    final exclues = DashboardData(
      totals: const PeriodTotals(
        entrant: 760200,
        sortant: 185000,
        prelevement: 90000,
        nbOperations: 11,
        nbDepenses: 3,
        nbPrelevements: 1,
      ),
      previousTotals: dataMois.previousTotals,
      operations: dataMois.operations,
      depenses: dataMois.depenses,
      chargesDuMois: dataMois.chargesDuMois,
      chargesIncluses: false,
      trend: dataMois.trend,
      repartition: dataMois.repartition,
    );

    await tester.pumpWidget(
      harness(1.0, period: Period.month, content: exclues),
    );
    await tester.pump();

    // La carte montre toujours les 480 000 Ar saisis…
    expect(exclues.totalCharges, 480000);
    // …mais le solde ne les retranche plus.
    expect(tester.widget<SoldeNetCard>(find.byType(SoldeNetCard)).solde, 90000);
    expect(find.text('hors solde net'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'le solde mensuel et sa comparaison utilisent le prélèvement réel',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        harness(1, period: Period.month, content: dataMois),
      );
      final card = tester.widget<SoldeNetCard>(find.byType(SoldeNetCard));
      expect(card.solde, -390000);
      expect(card.deltaPercent, -880);
      expect(card.formula, 'prélèvement saisi − charges');
    },
  );

  for (final saisi in [400, 500, 600]) {
    testWidgets('couleur du rapprochement pour un prélèvement de $saisi', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final content = DashboardData(
        totals: PeriodTotals(
          entrant: 800,
          sortant: 300,
          prelevement: saisi,
          nbOperations: 1,
          nbDepenses: 1,
          nbPrelevements: 1,
        ),
        previousTotals: PeriodTotals.empty,
        operations: const [],
        depenses: const [],
        trend: const [],
        repartition: const [],
      );
      await tester.pumpWidget(
        harness(1, period: Period.month, content: content),
      );
      final text = tester.widget<Text>(
        find.byKey(const ValueKey('ecart-prelevement')),
      );
      expect(
        text.style!.color,
        saisi >= 500 ? AppTokens.light.success : AppTokens.light.warning,
      );
      expect(content.totals.ecartPrelevement, saisi - 500);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('prelevement-calcule')))
            .data,
        Fmt.num(500),
      );
    });
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

import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/backup_screen.dart';
import 'package:caisse_dashboard/view/screens/jiro_screen.dart';
import 'package:caisse_dashboard/view/screens/ledger_screen.dart';
import 'package:caisse_dashboard/view/screens/releves_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Les écrans secondaires doivent tenir sur la plus petite fenêtre visée,
/// y compris avec un texte agrandi par le système.
void main() {
  setUpAll(() => initializeDateFormatting('fr_FR', null));

  final releves = [
    for (var i = 0; i < 6; i++)
      ReleveElectricite(
        id: '$i',
        date: DateTime(2026, 3, 1 + i * 10),
        compteur: 1000 + i * 90,
        sousCompteur: 400 + i * 55,
      ),
  ];

  final sharing = JiroSharing(
    id: 'x',
    periode: 'Janvier 2026',
    indexPrecedent: 1000,
    indexActuel: 1100,
    conso1: 60,
    conso2: 40,
    part1: 45000,
    part2: 35000,
    total: 80000,
    genereLe: DateTime(2026, 2, 3),
  );

  final screens = <String, Widget Function(BuildContext)>{
    'opérations': (context) => LedgerScreen(
      config: LedgerConfigs.operations(context),
      filter: SearchFilter(query: '', hint: 'Rechercher…', onChanged: (_) {}),
      sort: LedgerSort.date,
      onSortChanged: (_) {},
      items: [
        for (var i = 0; i < 20; i++)
          LedgerItem(
            date: DateTime(2026, 8, 21, 7, i),
            amount: 900,
            cells: const [
              LedgerCell('Photocopie A4 N&B'),
              LedgerCell('100', mono: true),
              LedgerCell('×9', mono: true),
              LedgerCell('900', mono: true),
              LedgerCell('07h36', mono: true),
            ],
          ),
      ],
    ),
    'prélèvements (filtre mensuel)': (context) => LedgerScreen(
      config: LedgerConfigs.prelevements(context),
      filter: MonthFilter(
        months: [DateTime(2026, 6), DateTime(2026, 7), DateTime(2026, 8)],
        selected: DateTime(2026, 8),
        onChanged: (_) {},
        blockedLabel: 'Septembre',
        note: 'Août 2026 est le mois courant.',
      ),
      sort: LedgerSort.date,
      onSortChanged: (_) {},
      items: const [],
    ),
    'relevés': (context) => RelevesScreen(releves: releves),
    'partage JIRO': (context) =>
        JiroScreen(history: [sharing], releves: releves, onGenerate: (_) {}),
    'sauvegarde': (context) => BackupScreen(
      recordCount: 848,
      lastRecordLabel: '21 août',
      imports: [
        ImportLog(
          fileName: 'backup_caisse_2026_08_21.enc',
          date: DateTime(2026, 8, 21),
          added: 42,
          skipped: 806,
        ),
      ],
    ),
  };

  Future<void> mount(
    WidgetTester tester,
    Widget Function(BuildContext) build,
    Size size,
    double textScale,
  ) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(brightness: Brightness.light),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: Scaffold(
              body: Padding(
                padding: EdgeInsets.all(context.tokens.pad),
                child: Builder(builder: build),
              ),
            ),
          ),
        ),
      ),
    );
  }

  const cases = [
    (Size(1440, 900), 1.0),
    (Size(1280, 720), 1.3),
    (Size(1024, 700), 1.15),
    (Size(900, 650), 1.5),
  ];

  for (final entry in screens.entries) {
    for (final (size, scale) in cases) {
      testWidgets(
        '${entry.key} · ${size.width.toInt()}x${size.height.toInt()} · '
        'texte ×$scale',
        (tester) async {
          await mount(tester, entry.value, size, scale);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('partage JIRO : le formulaire de saisie tient aussi', (
    tester,
  ) async {
    await mount(tester, screens['partage JIRO']!, const Size(1280, 720), 1.3);
    await tester.tap(find.text('Nouveau partage'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

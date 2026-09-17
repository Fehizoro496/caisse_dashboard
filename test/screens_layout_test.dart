import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/models.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/screens/backup_screen.dart';
import 'package:caisse_dashboard/view/screens/charges_screen.dart';
import 'package:caisse_dashboard/view/screens/jiro_screen.dart';
import 'package:caisse_dashboard/view/screens/ledger_screen.dart';
import 'package:caisse_dashboard/view/screens/releves_screen.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:caisse_dashboard/view/widgets/record_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    'charges mensuelles': (context) => ChargesScreen(
      charges: [
        for (final (l, pu, qte, jour) in const [
          ('Loyer du local', 350000, 1, 3),
          ('Facture JIRAMA', 95000, 1, 12),
          // Une quantité : la ligne la plus large, P.U. et total distincts.
          ('Ramettes A4', 18500, 12, 20),
          // Réglée en septembre, imputée à août : la ligne au décalage
          // signalé, celle qui porte le rendu le plus chargé.
          ('Internet fibre', 120000, 1, 34),
        ])
          ChargeMensuelle(
            id: l,
            libelle: l,
            prixUnitaire: pu,
            quantite: qte,
            mois: DateTime(2026, 8),
            dateEnregistrement: DateTime(2026, 8, jour),
          ),
      ],
      mois: DateTime(2026, 8),
      onMoisChanged: (_) {},
      onAdd: () {},
      onEdit: (_) {},
      onDelete: (_) {},
      reportables: const [],
      onReport: () {},
    ),
    // Mois vide : c'est l'état qui propose le report, avec son bloc de texte
    // le plus long — donc le plus exposé au débordement.
    'charges mensuelles (mois vide)': (context) => ChargesScreen(
      charges: const [],
      mois: DateTime(2026, 9),
      onMoisChanged: (_) {},
      onAdd: () {},
      onEdit: (_) {},
      onDelete: (_) {},
      reportables: [
        ChargeMensuelle(
          id: 'r',
          libelle: 'Loyer du local',
          prixUnitaire: 350000,
          mois: DateTime(2026, 8),
          dateEnregistrement: DateTime(2026, 8, 3),
        ),
      ],
      onReport: () {},
      incluses: false,
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

  testWidgets('chaque charge offre le crayon et la corbeille', (tester) async {
    // Sans crayon, la seule icône de la ligne serait la corbeille, et rien
    // ne dirait qu'une charge se corrige — le clic sur la ligne, lui, ne se
    // voit pas.
    var modifiee = 0;
    await mount(
      tester,
      (context) => ChargesScreen(
        charges: [
          ChargeMensuelle(
            id: 'c1',
            libelle: 'Loyer du local',
            prixUnitaire: 350000,
            mois: DateTime(2026, 8),
            dateEnregistrement: DateTime(2026, 8, 3),
          ),
        ],
        mois: DateTime(2026, 8),
        onMoisChanged: (_) {},
        onAdd: () {},
        onEdit: (_) => modifiee++,
        onDelete: (_) {},
        reportables: const [],
        onReport: () {},
      ),
      const Size(1440, 900),
      1.0,
    );

    expect(find.byType(RowEditButton), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.tap(find.byType(RowEditButton));
    await tester.pump();
    expect(modifiee, 1);

    // La ligne entière reste cliquable, comme dans les autres écrans.
    await tester.tap(find.text('Loyer du local'));
    await tester.pump();
    expect(modifiee, 2);
    expect(tester.takeException(), isNull);
  });

  /// Ouvre le formulaire de charge. Le bouton « Ajouter » de l'écran ne suffit
  /// pas : c'est le contrôleur qui appelle l'éditeur, et le fixture n'en a pas.
  Future<void> openChargeEditor(
    WidgetTester tester,
    Size size,
    double textScale, {
    List<ChargeSuggestion> suggestions = const [],
  }) async {
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () => showChargeEditor(
          context,
          mois: DateTime(2026, 8),
          suggestions: suggestions,
        ),
        child: const Text('ouvrir'),
      ),
      size,
      textScale,
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
  }

  // Le formulaire de charge est le dialogue le plus haut du produit, et sa
  // liste de catégories déployée le cas le plus exigeant en hauteur.
  for (final (size, scale) in cases) {
    testWidgets(
      'formulaire de charge · ${size.width.toInt()}x${size.height.toInt()} · '
      'texte ×$scale',
      (tester) async {
        await openChargeEditor(tester, size, scale);
        expect(tester.takeException(), isNull);

        // Liste déployée : les neuf catégories sont proposées, pas seulement
        // celle qui est déduite du libellé.
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        for (final c in CategoryRules.chargeCategories) {
          expect(find.text(c), findsWidgets, reason: '$c absente du choix');
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('une catégorie inconnue de CategoryRules garde son entrée', (
    tester,
  ) async {
    // Le cas d'une charge enregistrée sous une catégorie retirée depuis :
    // sans son entrée, DropdownButton casserait sur une assertion.
    await mount(
      tester,
      (context) => TextButton(
        onPressed: () => showChargeEditor(
          context,
          libelle: 'Ancienne ligne',
          prixUnitaire: 50000,
          mois: DateTime(2026, 8),
          dateEnregistrement: DateTime(2026, 8, 3),
          categorie: 'Catégorie disparue',
        ),
        child: const Text('ouvrir'),
      ),
      const Size(1440, 900),
      1.0,
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Catégorie disparue'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('autocomplétion du libellé', () {
    const connus = [
      ChargeSuggestion(libelle: 'Loyer du local', prixUnitaire: 350000),
      ChargeSuggestion(
        libelle: 'Facture JIRAMA',
        prixUnitaire: 95000,
        categorie: 'Facture',
      ),
      ChargeSuggestion(libelle: 'Facture internet', prixUnitaire: 120000),
      ChargeSuggestion(
        libelle: 'Ramettes A4',
        prixUnitaire: 18500,
        quantite: 12,
      ),
    ];

    /// Le contrôleur du champ de libellé, qui porte la complétion grisée.
    TextEditingController champLibelle(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField).first).controller!;

    /// Le texte réellement dessiné dans le champ, complétion grise comprise.
    String dessine(WidgetTester tester) => champLibelle(tester)
        .buildTextSpan(
          context: tester.element(find.byType(TextField).first),
          withComposing: false,
        )
        .toPlainText();

    testWidgets('la frappe prolonge un libellé déjà employé', (tester) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      await tester.enterText(find.byType(TextField).first, 'fact');
      await tester.pumpAndSettle();

      // Le premier des libellés qui commencent par « fact ».
      expect(dessine(tester), 'facture JIRAMA');
      // Rien n'est déroulé sous le champ : la proposition se lit sur place.
      expect(find.text('Facture internet'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets("la fin du libellé s'affiche en gris pendant la frappe", (
      tester,
    ) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      await tester.enterText(find.byType(TextField).first, 'ramet');
      await tester.pumpAndSettle();

      // La complétion n'entre pas dans la valeur : elle n'est que dessinée.
      // La complétion n'entre pas dans la valeur : elle n'est que dessinée.
      expect(champLibelle(tester).text, 'ramet');
      expect(dessine(tester), 'ramettes A4');
      expect(tester.takeException(), isNull);
    });

    testWidgets("Tab accepte la complétion, avec sa casse d'origine", (
      tester,
    ) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      await tester.enterText(find.byType(TextField).first, 'ramet');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // « ramet » devient « Ramettes A4 », et non « ramettes A4 ».
      expect(champLibelle(tester).text, 'Ramettes A4');
      expect(tester.takeException(), isNull);
    });

    testWidgets("effacer ne repropose pas ce qu'on vient de retirer", (
      tester,
    ) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      await tester.enterText(find.byType(TextField).first, 'ramett');
      await tester.pumpAndSettle();
      // Retour arrière : sans cette règle, la fin du mot repousserait chaque
      // caractère supprimé et le champ deviendrait impossible à corriger.
      await tester.enterText(find.byType(TextField).first, 'ramet');
      await tester.pumpAndSettle();

      expect(dessine(tester), 'ramet');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tab reprend aussi le prix, la quantité et la catégorie', (
      tester,
    ) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      await tester.enterText(find.byType(TextField).first, 'ramet');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final champs = find.byType(TextField);
      expect(tester.widget<TextField>(champs.at(1)).controller!.text, '18500');
      expect(tester.widget<TextField>(champs.at(2)).controller!.text, '12');
      // 18 500 × 12 : le total se recalcule sans qu'on ait rien tapé d'autre.
      expect(find.text(Fmt.ar(222000)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un prix déjà saisi cède à la proposition', (tester) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      // L'utilisateur commence par le prix, puis complète le libellé :
      // accepter la proposition, c'est demander la ligne précédente entière.
      await tester.enterText(find.byType(TextField).at(1), '20000');
      await tester.enterText(find.byType(TextField).first, 'ramet');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      final champs = find.byType(TextField);
      expect(tester.widget<TextField>(champs.first).controller!.text,
          'Ramettes A4');
      expect(tester.widget<TextField>(champs.at(1)).controller!.text, '18500');
      expect(tester.widget<TextField>(champs.at(2)).controller!.text, '12');
      expect(tester.takeException(), isNull);
    });

    testWidgets('champ vide ou saisie exacte : aucune complétion', (
      tester,
    ) async {
      await openChargeEditor(
        tester,
        const Size(1440, 900),
        1.0,
        suggestions: connus,
      );

      expect(dessine(tester), '');

      // Saisie déjà complète : rien à prolonger.
      await tester.enterText(find.byType(TextField).first, 'Facture JIRAMA');
      await tester.pumpAndSettle();
      expect(dessine(tester), 'Facture JIRAMA');
      expect(tester.takeException(), isNull);
    });

    testWidgets('sans historique, le champ reste un champ ordinaire', (
      tester,
    ) async {
      await openChargeEditor(tester, const Size(1440, 900), 1.0);
      await tester.enterText(find.byType(TextField).first, 'Loyer');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets("les erreurs ne se disent qu'au moment d'enregistrer", (
    tester,
  ) async {
    await openChargeEditor(tester, const Size(1440, 900), 1.0);

    // Formulaire vierge : rien à reprocher tant que rien n'a été tenté.
    expect(find.text('Le libellé ne peut pas être vide.'), findsNothing);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Le libellé ne peut pas être vide.'), findsOneWidget);

    // Une fois la tentative faite, le message suit la correction en direct.
    await tester.enterText(find.byType(TextField).first, 'Loyer');
    await tester.pump();
    expect(find.text('Le libellé ne peut pas être vide.'), findsNothing);
    expect(
      find.text('Le prix unitaire doit être supérieur à zéro.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('les champs numériques gardent la décoration du thème', (
    tester,
  ) async {
    // `decoration: null` sur un TextField ne veut pas dire « celle par
    // défaut » mais « aucune » : le champ perd alors bordure, fond et
    // padding, et détonne à côté de ses voisins.
    await openChargeEditor(tester, const Size(1440, 900), 1.0);
    final champs = tester.widgetList<TextField>(find.byType(TextField));
    expect(champs, isNotEmpty);
    for (final c in champs) {
      expect(c.decoration, isNotNull, reason: 'un champ sans décoration');
    }
  });

  testWidgets('une quantité laissée vide vaut une unité', (tester) async {
    await openChargeEditor(tester, const Size(1440, 900), 1.0);

    final champs = find.byType(TextField);
    await tester.enterText(champs.at(0), 'Loyer du local');
    await tester.enterText(champs.at(1), '350000');
    // Le champ quantité est vidé : le loyer ne se compte pas, et l'y forcer
    // à saisir « 1 » serait une friction pour rien.
    await tester.enterText(champs.at(2), '');
    await tester.pump();

    // Ni blocage, ni total à zéro : la ligne vaut son prix unitaire.
    expect(find.text('La quantité doit être au moins 1.'), findsNothing);
    expect(find.text(Fmt.ar(350000)), findsOneWidget);

    // Un zéro explicite, lui, reste une erreur — mais elle ne se dit qu'au
    // moment d'enregistrer, pas sous les doigts.
    await tester.enterText(champs.at(2), '0');
    await tester.pump();
    expect(find.text('La quantité doit être au moins 1.'), findsNothing);

    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('La quantité doit être au moins 1.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la catégorie proposée suit le libellé, puis se fige', (
    tester,
  ) async {
    await openChargeEditor(tester, const Size(1440, 900), 1.0);

    // L'intitulé du champ passe en capitales : on cherche le mot qui
    // distingue les deux états, pas la phrase entière.
    final proposee = find.textContaining('PROPOSÉE');
    final choisie = find.textContaining('CHOISIE');

    // Tant que rien n'est choisi, la frappe pilote la catégorie.
    await tester.enterText(find.byType(TextField).first, 'Loyer du local');
    await tester.pump();
    expect(proposee, findsOneWidget);
    expect(choisie, findsNothing);

    // Un choix dans la liste fige la catégorie…
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    // L'entrée sélectionnée apparaît deux fois quand le menu est ouvert :
    // dans le champ et dans la liste. C'est celle de la liste qu'on clique.
    await tester.tap(find.text('Maintenance').last);
    await tester.pumpAndSettle();
    expect(choisie, findsOneWidget);
    expect(proposee, findsNothing);

    // …que le libellé ne rattrape plus : « Ramette A4 » déduirait
    // « Fournitures ».
    await tester.enterText(find.byType(TextField).first, 'Ramette A4');
    await tester.pump();
    expect(choisie, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

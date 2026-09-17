import 'package:caisse_dashboard/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final releves = [
    ReleveElectricite(
      id: 'a',
      date: DateTime(2026, 1, 1),
      compteur: 1000,
      sousCompteur: 400,
    ),
    ReleveElectricite(
      id: 'b',
      date: DateTime(2026, 1, 11),
      compteur: 1100,
      sousCompteur: 460,
    ),
  ];

  group('resolveSubMeter', () {
    test('un index présent en base donne le relevé exact', () {
      final r = resolveSubMeter(1100, releves);
      expect(r.state, SubMeterState.exact);
      expect(r.value, 460);
      expect(r.date, DateTime(2026, 1, 11));
    });

    test('un index encadré est interpolé, date comprise', () {
      final r = resolveSubMeter(1050, releves);
      expect(r.state, SubMeterState.interpolated);
      expect(r.value, 430);
      expect(r.date, DateTime(2026, 1, 6));
    });

    test('hors plage, la résolution échoue plutôt que d\'extrapoler', () {
      expect(resolveSubMeter(1200, releves).ok, isFalse);
      expect(resolveSubMeter(900, releves).ok, isFalse);
      expect(resolveSubMeter(null, releves).ok, isFalse);
      expect(resolveSubMeter(1050, const []).ok, isFalse);
    });
  });

  group('JiroBill', () {
    const bill = JiroBill(
      indexPrecedent: 1000,
      indexActuel: 1100,
      prixKwh: 500,
      redevance: 3000,
      primeFixe: 12000,
      taxes: 4000,
      tva: 2000,
    );

    test('les deux parts reconstituent la facture', () {
      final p1 = bill.shareFor(60);
      final p2 = bill.shareFor(bill.consoTotale - 60);
      expect(p1.total + p2.total, closeTo(bill.totalFacture, 0.001));
    });

    test('chaque poste fixe est partagé par moitié', () {
      final part = bill.shareFor(60);
      expect(part.redevance, 1500);
      expect(part.primeFixe, 6000);
      expect(part.taxes, 2000);
      expect(part.tva, 1000);
      expect(part.variable, 30000);
    });
  });

  group('CategoryRules', () {
    test('la catégorie se déduit du libellé', () {
      expect(CategoryRules.of('Ramette A4'), 'Papier');
      expect(CategoryRules.of('Facture JIRAMA janvier'), 'Électricité');
      expect(CategoryRules.of('Achat divers'), CategoryRules.fallback);
    });

    test('les charges ont leur propre jeu, plus court', () {
      // « Facture » couvre à elle seule ce que les dépenses éclatent entre
      // Électricité et Internet.
      expect(CategoryRules.ofCharge('Facture JIRAMA janvier'), 'Facture');
      expect(CategoryRules.ofCharge('Abonnement fibre'), 'Facture');
      expect(CategoryRules.ofCharge('Loyer du local'), 'Loyer');
      expect(CategoryRules.ofCharge('Entretien climatiseur'), 'Maintenance');
      expect(CategoryRules.ofCharge('Ramette A4'), 'Fournitures');
      expect(CategoryRules.ofCharge('Cotisation'), CategoryRules.fallback);
    });

    test('« bureau » ne bascule pas en Facture par la sous-chaîne « eau »', () {
      // La recherche est une sous-chaîne : c'est le piège qui avait fait
      // classer « rideau » ou « nouveau » en Fournitures côté dépenses.
      expect(CategoryRules.ofCharge('Fournitures de bureau'), 'Fournitures');
    });

    test('toute déduction de charge tombe dans la liste proposée', () {
      // Sans quoi la liste déroulante ouvrirait sur une valeur absente de
      // ses entrées — l'assertion que `_CategoryDropdown` doit éviter.
      for (final libelle in [
        'Loyer',
        'Facture JIRAMA',
        'Entretien',
        'Ramette',
        'Libellé sans mot-clé',
      ]) {
        expect(
          CategoryRules.chargeCategories,
          contains(CategoryRules.ofCharge(libelle)),
          reason: '« $libelle » sort de la liste',
        );
      }
    });
  });

  group('ChargeMensuelle', () {
    ChargeMensuelle charge({required int pu, required int qte}) =>
        ChargeMensuelle(
          id: 'c',
          libelle: 'Ramette A4',
          prixUnitaire: pu,
          quantite: qte,
          mois: DateTime(2026, 8),
          dateEnregistrement: DateTime(2026, 8, 3),
        );

    test('le total multiplie le prix unitaire par la quantité', () {
      expect(charge(pu: 18500, qte: 12).montant, 222000);
    });

    test('une charge sans quantité vaut son prix unitaire', () {
      // Le cas du loyer, et celui de toutes les lignes migrées depuis la v12.
      expect(charge(pu: 350000, qte: 1).montant, 350000);
      expect(charge(pu: 350000, qte: 1).multiple, isFalse);
      expect(charge(pu: 18500, qte: 12).multiple, isTrue);
    });
  });

  group('PeriodTotals', () {
    test('le solde net retire dépenses et prélèvements', () {
      const t = PeriodTotals(
        entrant: 100000,
        sortant: 30000,
        prelevement: 20000,
        nbOperations: 4,
        nbDepenses: 2,
        nbPrelevements: 1,
      );
      expect(t.soldeNet, 50000);
    });
  });
}

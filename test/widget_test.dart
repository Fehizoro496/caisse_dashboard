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

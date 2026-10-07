import 'package:caisse_dashboard/controller/caisse_controller.dart';
import 'package:caisse_dashboard/persistance/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('regroupe casse et espaces périphériques sans perdre les montants', () {
    Operation operation(String name, int price, int quantity) => Operation(
      idOperation: name,
      nomOperation: name,
      prixOperation: price,
      quantiteOperation: quantity,
      dateOperation: DateTime(2026, 10, 7),
    );
    final rows = CaisseController.aggregateOperations([
      operation(' Photocopie ', 100, 2),
      operation('PHOTOCOPIE', 150, 3),
      operation('photocopie\t ', 100, 1),
      operation('Impression couleur', 1000, 1),
    ]);
    expect(rows, hasLength(2));
    expect(rows.first.nom, 'Impression couleur');
    final copies = rows.last;
    expect(copies.nom, 'Photocopie');
    expect(copies.quantite, 6);
    expect(copies.total, 750);
    expect(copies.meta, '3');
    expect(rows.fold<int>(0, (sum, r) => sum + r.total), 1750);
    expect(CaisseController.aggregateOperations([]), isEmpty);
  });
}

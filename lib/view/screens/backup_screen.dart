import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/core/theme/app_tokens.dart';
import 'package:caisse_dashboard/view/widgets/panel.dart';
import 'package:flutter/material.dart';

/// Trace d'un import : fusion par identifiant, jamais d'écrasement.
class ImportLog {
  const ImportLog({
    required this.fileName,
    required this.date,
    required this.added,
    required this.skipped,
  });

  final String fileName;
  final DateTime date;
  final int added;
  final int skipped;

  factory ImportLog.fromJson(Map<String, dynamic> j) => ImportLog(
    fileName: j['fileName'] as String,
    date: DateTime.parse(j['date'] as String),
    added: j['added'] as int,
    skipped: j['skipped'] as int,
  );

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'date': date.toIso8601String(),
    'added': added,
    'skipped': skipped,
  };
}

/// Sauvegarde : import .enc et — nouveauté — export, jusqu'ici codé
/// mais sans point d'entrée dans l'interface.
class BackupScreen extends StatelessWidget {
  const BackupScreen({
    super.key,
    required this.recordCount,
    required this.lastRecordLabel,
    required this.imports,
    this.onImport,
    this.onExport,
    this.busy = false,
  });

  final int recordCount;
  final String lastRecordLabel;
  final List<ImportLog> imports;
  final VoidCallback? onImport;
  final VoidCallback? onExport;

  /// Import ou export en cours : les deux boutons se désarment ensemble.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final x = context.texts;

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius: t.br,
                        border: Border.all(color: t.lineStrong),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          children: [
                            Text('Importer une sauvegarde', style: x.cardTitle),
                            const SizedBox(height: 6),
                            Text(
                              'Fichier .enc chiffré. Fusion par identifiant : les '
                              'enregistrements existants ne sont jamais écrasés.',
                              style: x.bodyMuted.copyWith(height: 1.55),
                              textAlign: TextAlign.center,
                            ),
                            const Spacer(),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: busy ? null : onImport,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: t.accent,
                                side: BorderSide(color: t.accent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: t.brSmall,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Choisir un fichier .enc'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Panel(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Text('Exporter la base', style: x.cardTitle),
                          const SizedBox(height: 6),
                          Text(
                            'Archive chiffrée de $recordCount enregistrements, '
                            'jusqu\'au $lastRecordLabel.',
                            style: x.bodyMuted.copyWith(height: 1.55),
                            textAlign: TextAlign.center,
                          ),
                          const Spacer(),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: busy ? null : onExport,
                            style: FilledButton.styleFrom(
                              backgroundColor: t.accent,
                              disabledBackgroundColor: t.surfaceAlt,
                              disabledForegroundColor: t.faint,
                              shape: RoundedRectangleBorder(
                                borderRadius: t.brSmall,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Exporter .enc'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PanelHeader(title: 'Derniers imports'),
                  if (imports.isEmpty)
                    const EmptyState(title: 'Aucun import enregistré.')
                  else
                    for (final i in imports)
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: t.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                i.fileName,
                                style: x.monoMuted,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                Fmt.numericDate(i.date),
                                style: x.bodyMuted,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '+${i.added} nouveaux',
                                style: x.monoMuted.copyWith(color: t.income),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${i.skipped} déjà présents',
                                style: x.monoFaint,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

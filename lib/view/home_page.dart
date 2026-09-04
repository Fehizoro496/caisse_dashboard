import 'package:caisse_dashboard/controller/caisse_controller.dart';
import 'package:caisse_dashboard/controller/theme_controller.dart';
import 'package:caisse_dashboard/core/format.dart';
import 'package:caisse_dashboard/view/screens/backup_screen.dart';
import 'package:caisse_dashboard/view/screens/charges_screen.dart';
import 'package:caisse_dashboard/view/screens/dashboard_screen.dart';
import 'package:caisse_dashboard/view/screens/jiro_screen.dart';
import 'package:caisse_dashboard/view/screens/ledger_screen.dart';
import 'package:caisse_dashboard/view/screens/releves_screen.dart';
import 'package:caisse_dashboard/view/widgets/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Assemble la coquille et les sept écrans. Toute la logique vit dans
/// [CaisseController] : cette page ne fait que du câblage.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ThemeController>(
      builder: (theme) => GetBuilder<CaisseController>(
        builder: (c) {
          final dashboard = DashboardScreen(
            data: c.loading || c.error != null
                ? DashboardData.empty
                : c.dashboard,
            date: c.date,
            period: c.period,
            lastRecordDate: c.lastRecordDate,
            loading: c.loading,
            error: c.error,
            onRetry: c.load,
            onPeriodChanged: c.setPeriod,
            onDateChanged: c.setDate,
            onPickDate: () => c.pickDate(context),
            onToggleCharges: c.setChargesIncluses,
            onOpenSection: c.openSection,
          );

          final (title, subtitle, body) = switch (c.section) {
            AppSection.dashboard => (
              'Tableau de bord',
              'Date courante initialisée sur le dernier enregistrement en base — '
                  '${Fmt.cap(Fmt.longDate(c.lastRecordDate))}',
              dashboard as Widget,
            ),
            AppSection.operations => (
              'Opérations',
              'Prestations encaissées · sous-totaux par jour · '
                  'cliquez une ligne pour la corriger',
              LedgerScreen(
                config: LedgerConfigs.operations(context),
                filter: SearchFilter(
                  query: c.qOperations,
                  hint: 'Rechercher une prestation…',
                  onChanged: (v) => c.setQuery(AppSection.operations, v),
                ),
                sort: c.sortOperations,
                onSortChanged: (s) => c.setSort(AppSection.operations, s),
                items: c.loading ? const [] : c.operationItems(context),
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
              ),
            ),
            AppSection.expenses => (
              'Dépenses',
              'Achats, charges et consommables · '
                  'cliquez une ligne pour la corriger',
              LedgerScreen(
                config: LedgerConfigs.depenses(context),
                filter: SearchFilter(
                  query: c.qDepenses,
                  hint: 'Rechercher un libellé de dépense…',
                  onChanged: (v) => c.setQuery(AppSection.expenses, v),
                ),
                sort: c.sortDepenses,
                onSortChanged: (s) => c.setSort(AppSection.expenses, s),
                items: c.loading ? const [] : c.depenseItems(context),
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
              ),
            ),
            AppSection.charges => (
              'Charges mensuelles',
              'Loyer, fournitures, factures · imputées au mois entier — '
                  'jamais au jour ni à la semaine',
              ChargesScreen(
                charges: c.loading ? const [] : c.chargesDuMois,
                mois: c.moisCharges,
                onMoisChanged: c.setMoisCharges,
                onAdd: () => c.addCharge(context),
                onEdit: (ch) => c.editCharge(context, ch),
                onDelete: c.deleteCharge,
                reportables: c.loading ? const [] : c.chargesReportables,
                onReport: c.reconduireCharges,
                incluses: c.chargesIncluses,
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
              ),
            ),
            AppSection.drawings => (
              'Prélèvements',
              'Filtre mensuel · cliquez une ligne pour la corriger',
              LedgerScreen(
                config: LedgerConfigs.prelevements(context),
                filter: MonthFilter(
                  months: c.availableMonths,
                  selected: c.mois,
                  onChanged: c.setMois,
                  blockedLabel: c.nextMonthLabel,
                  note:
                      '${Fmt.cap(Fmt.month(c.lastRecordDate))} est le mois '
                      'courant — au-delà, rien à afficher.',
                ),
                sort: LedgerSort.date,
                onSortChanged: (_) {},
                items: c.loading ? const [] : c.prelevementItems(context),
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
              ),
            ),
            AppSection.meterReadings => (
              'Relevés électricité',
              'Index général et sous-compteur · consommation par différence · '
                  'crayon pour corriger',
              RelevesScreen(
                releves: c.releves,
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
                onEdit: (r) => c.editReleve(context, r),
              ),
            ),
            AppSection.jiroSharing => (
              'Partage JIRO',
              'Historique des factures JIRAMA réparties entre les deux occupants',
              JiroScreen(
                history: c.jiroHistory,
                releves: c.releves,
                defaults: c.jiroDefaults,
                loading: c.loading,
                error: c.error,
                onRetry: c.load,
                onGenerate: c.saveJiroSharing,
                onOpenPdf: c.regenerateJiroPdf,
                onDelete: c.deleteJiroSharing,
              ),
            ),
            AppSection.backup => (
              'Sauvegarde',
              'Import .enc fusionné par identifiant · export chiffré',
              BackupScreen(
                recordCount: c.recordCount,
                lastRecordLabel: Fmt.shortDate(c.lastRecordDate),
                imports: c.imports,
                busy: c.busy,
                onImport: c.importBackup,
                onExport: c.exportBackup,
              ),
            ),
          };

          return AppShell(
            section: c.section,
            onSectionChanged: c.openSection,
            title: title,
            subtitle: subtitle,
            counts: c.counts,
            toolbar: c.section == AppSection.dashboard
                ? dashboard.buildToolbar()
                : null,
            isDark: theme.isDarkMode,
            onToggleTheme: theme.toggleTheme,
            dbCount: c.recordCount,
            lastRecordLabel: Fmt.shortDate(c.lastRecordDate),
            onImport: c.importBackup,
            child: body,
          );
        },
      ),
    );
  }
}

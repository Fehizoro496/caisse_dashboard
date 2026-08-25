import 'package:flutter/material.dart';

/// Jetons de design du Caisse Dashboard.
///
/// Un seul endroit décide couleurs, formes, densité et typographie.
/// Accès depuis n'importe quel widget : `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.line,
    required this.lineStrong,
    required this.text,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.accentSoft,
    required this.income,
    required this.expense,
    required this.drawing,
    required this.electric,
    required this.shadow,
    this.radius = 14,
    this.radiusSmall = 10,
    this.pad = 22,
    this.rowHeight = 38,
  });

  // Surfaces et texte
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color line;
  final Color lineStrong;
  final Color text;
  final Color muted;
  final Color faint;

  // Accent
  final Color accent;
  final Color accentSoft;

  /// Les quatre sémantiques métier — ne jamais les confondre.
  final Color income; // entrant / opérations
  final Color expense; // sortant / dépenses
  final Color drawing; // prélèvement
  final Color electric; // électricité / relevés

  final List<BoxShadow> shadow;

  final double radius;
  final double radiusSmall;
  final double pad;
  final double rowHeight;

  static const AppTokens light = AppTokens(
    bg: Color(0xFFF3F5F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF6F8FC),
    line: Color(0xFFECF0F6),
    lineStrong: Color(0xFFDBE1EC),
    text: Color(0xFF1A1E28),
    muted: Color(0xFF69707F),
    faint: Color(0xFF9AA2B2),
    accent: Color(0xFF5570E6),
    accentSoft: Color(0xFFEEF1FE),
    income: Color(0xFF2F9E83),
    expense: Color(0xFFC8785C),
    drawing: Color(0xFF8570C9),
    electric: Color(0xFFBF9A3D),
    shadow: [
      BoxShadow(color: Color(0x0A161C2D), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x14161C2D),
        blurRadius: 30,
        spreadRadius: -18,
        offset: Offset(0, 10),
      ),
    ],
  );

  static const AppTokens dark = AppTokens(
    bg: Color(0xFF0F1116),
    surface: Color(0xFF181B22),
    surfaceAlt: Color(0xFF1F232C),
    line: Color(0xFF242935),
    lineStrong: Color(0xFF333A48),
    text: Color(0xFFE8EAF0),
    muted: Color(0xFF9AA2B2),
    faint: Color(0xFF727A8A),
    accent: Color(0xFF8B9DF0),
    accentSoft: Color(0xFF1F2540),
    income: Color(0xFF59B39A),
    expense: Color(0xFFD6957A),
    drawing: Color(0xFFA898E0),
    electric: Color(0xFFD0B064),
    shadow: [
      BoxShadow(color: Color(0x4D000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(
        color: Color(0x99000000),
        blurRadius: 34,
        spreadRadius: -20,
        offset: Offset(0, 12),
      ),
    ],
  );

  BorderRadius get br => BorderRadius.circular(radius);
  BorderRadius get brSmall => BorderRadius.circular(radiusSmall);
  Border get border => Border.all(color: line);

  @override
  AppTokens copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? line,
    Color? lineStrong,
    Color? text,
    Color? muted,
    Color? faint,
    Color? accent,
    Color? accentSoft,
    Color? income,
    Color? expense,
    Color? drawing,
    Color? electric,
    List<BoxShadow>? shadow,
    double? radius,
    double? radiusSmall,
    double? pad,
    double? rowHeight,
  }) {
    return AppTokens(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      drawing: drawing ?? this.drawing,
      electric: electric ?? this.electric,
      shadow: shadow ?? this.shadow,
      radius: radius ?? this.radius,
      radiusSmall: radiusSmall ?? this.radiusSmall,
      pad: pad ?? this.pad,
      rowHeight: rowHeight ?? this.rowHeight,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      bg: c(bg, other.bg),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      text: c(text, other.text),
      muted: c(muted, other.muted),
      faint: c(faint, other.faint),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      income: c(income, other.income),
      expense: c(expense, other.expense),
      drawing: c(drawing, other.drawing),
      electric: c(electric, other.electric),
      shadow: t < .5 ? shadow : other.shadow,
      radius: lerpDouble(radius, other.radius, t),
      radiusSmall: lerpDouble(radiusSmall, other.radiusSmall, t),
      pad: lerpDouble(pad, other.pad, t),
      rowHeight: lerpDouble(rowHeight, other.rowHeight, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  AppTextStyles get texts => AppTextStyles(tokens);
}

/// L'app n'embarque pas de police : on reste sur celle du système (Segoe UI
/// sous Windows). Le contrat typographique tient aux chiffres tabulaires des
/// styles `mono*` ; pour passer à Manrope / IBM Plex Mono, il suffit de
/// déclarer les familles ici et les assets dans `pubspec.yaml`.
class AppFonts {
  static const String? sans = null;
  static const String? mono = null;
}

/// Échelle typographique. Tout montant passe par [monoBody] & consorts :
/// chiffres tabulaires, sinon les colonnes de nombres dansent d'une ligne
/// à l'autre.
class AppTextStyles {
  AppTextStyles(this.t);
  final AppTokens t;

  static const _tabular = [FontFeature.tabularFigures()];

  TextStyle get pageTitle => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: t.text,
  );

  TextStyle get pageSubtitle =>
      TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: t.faint);

  TextStyle get cardTitle => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: t.text,
  );

  /// Étiquette de section : petites capitales espacées.
  TextStyle get overline => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 10.5,
    letterSpacing: .9,
    fontWeight: FontWeight.w500,
    color: t.muted,
  );

  TextStyle get columnHeader => TextStyle(
    fontFamily: AppFonts.sans,
    fontSize: 10,
    letterSpacing: .8,
    color: t.faint,
  );

  TextStyle get body =>
      TextStyle(fontFamily: AppFonts.sans, fontSize: 12.5, color: t.text);

  TextStyle get bodyMuted =>
      TextStyle(fontFamily: AppFonts.sans, fontSize: 12, color: t.muted);

  TextStyle get caption =>
      TextStyle(fontFamily: AppFonts.sans, fontSize: 11, color: t.faint);

  /// Le grand chiffre du solde net.
  TextStyle get heroAmount => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -.6,
    fontFeatures: _tabular,
    color: t.text,
  );

  TextStyle get statAmount => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    fontFeatures: _tabular,
    color: t.text,
  );

  TextStyle get monoBody => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 12.5,
    fontFeatures: _tabular,
    color: t.text,
  );

  TextStyle get monoMuted => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11.5,
    fontFeatures: _tabular,
    color: t.muted,
  );

  TextStyle get monoFaint => TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontFeatures: _tabular,
    color: t.faint,
  );
}

/// Construit le ThemeData à partir des jetons. Material reste actif
/// (focus, scrollbars, tooltips) mais toutes les surfaces sont pilotées ici.
ThemeData buildAppTheme({
  required Brightness brightness,
  Color? accentOverride,
}) {
  var t = brightness == Brightness.dark ? AppTokens.dark : AppTokens.light;
  if (accentOverride != null) t = t.copyWith(accent: accentOverride);
  final texts = AppTextStyles(t);

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    scaffoldBackgroundColor: t.bg,
    canvasColor: t.bg,
    fontFamily: AppFonts.sans,
    extensions: [t],
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: t.accent,
          brightness: brightness,
        ).copyWith(
          surface: t.surface,
          primary: t.accent,
          onSurface: t.text,
          outlineVariant: t.line,
        ),
    dividerTheme: DividerThemeData(color: t.line, space: 1, thickness: 1),
    textTheme: TextTheme(
      titleMedium: texts.pageTitle,
      titleSmall: texts.cardTitle,
      bodyMedium: texts.body,
      bodySmall: texts.caption,
      labelSmall: texts.columnHeader,
    ),
    iconTheme: IconThemeData(color: t.muted, size: 18),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: t.text,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: TextStyle(
        fontFamily: AppFonts.sans,
        fontSize: 11.5,
        color: t.surface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: t.surface,
      hintStyle: texts.caption,
      contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: t.brSmall,
        borderSide: BorderSide(color: t.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: t.brSmall,
        borderSide: BorderSide(color: t.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: t.brSmall,
        borderSide: BorderSide(color: t.accent, width: 1.4),
      ),
    ),
    scrollbarTheme: ScrollbarThemeData(
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(10),
      thumbColor: WidgetStatePropertyAll(t.lineStrong),
    ),
  );
}

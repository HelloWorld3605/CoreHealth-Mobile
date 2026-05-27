import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppPalette {
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFF9FAFB);
  static const text = Color(0xFF111827);
  static const mutedText = Color(0xFF6B7280);
  static const subtleText = Color(0xFF9CA3AF);
  static const emerald = Color(0xFFA6D727);
  static const emeraldDeep = Color(0xFF8BC34A);
  static const emeraldSoft = Color(0xFFEAF5C8);
  static const mint = Color(0xFFF5F9EA);
  static const accentSoft = Color(0xFFDCF58C);
  static const accentMuted = Color(0xFFC8E673);
  static const blue = Color(0xFF60A5FA);
  static const blueSoft = Color(0xFFEFF6FF);
  static const orange = Color(0xFFF59E0B);
  static const orangeSoft = Color(0xFFFFF4E5);
  static const violet = Color(0xFFA78BFA);
  static const violetSoft = Color(0xFFF3EEFF);
  static const gold = Color(0xFFF4B740);
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF1F5F9);
  static const shadow = Color(0x12111827);
  static const shadowHeavy = Color(0x26111827);
}

class AppSpacing {
  static const xs = 6.0;
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
}

class AppRadius {
  static const button = 18.0;
  static const card = 24.0;
  static const compactCard = 14.0;
  static const sheet = 28.0;
  static const pill = 999.0;
}

ThemeData buildCoreHealthTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppPalette.emerald,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppPalette.surface,
      onSurface: AppPalette.text,
      primary: AppPalette.emerald,
      onPrimary: AppPalette.text,
      secondary: AppPalette.blue,
      outline: AppPalette.border,
    ),
  );

  final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 46,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
      height: 1.02,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
      height: 1.04,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
      height: 1.08,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
      height: 1.1,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
      height: 1.12,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppPalette.text,
      height: 1.45,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppPalette.mutedText,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppPalette.subtleText,
      height: 1.4,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppPalette.text,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppPalette.text,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppPalette.mutedText,
    ),
  );

  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppPalette.background,
    textTheme: textTheme,
    cardTheme: CardThemeData(
      color: AppPalette.surface,
      elevation: 0,
      shadowColor: AppPalette.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: AppPalette.text,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        foregroundColor: AppPalette.text,
        backgroundColor: AppPalette.emerald,
        minimumSize: const Size.fromHeight(56),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        foregroundColor: AppPalette.text,
        backgroundColor: AppPalette.emerald,
        disabledBackgroundColor: const Color(0xFFB9C6D2),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppPalette.text,
        backgroundColor: AppPalette.surface,
        side: const BorderSide(color: AppPalette.border),
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppPalette.text,
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppPalette.surfaceElevated,
      labelStyle: textTheme.bodyMedium,
      hintStyle: textTheme.bodyMedium,
      floatingLabelStyle:
          textTheme.bodyMedium?.copyWith(color: AppPalette.emeraldDeep),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: AppPalette.emerald, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFF87171)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: Color(0xFFF87171), width: 1.4),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppPalette.surfaceElevated,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      labelStyle: textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppPalette.text,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppPalette.border,
      thickness: 1,
      space: 1,
    ),
    dividerColor: AppPalette.border,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppPalette.emeraldDeep,
      selectionColor: AppPalette.emerald.withValues(alpha: 0.25),
      selectionHandleColor: AppPalette.emerald,
    ),
    splashColor: AppPalette.emerald.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
  );
}

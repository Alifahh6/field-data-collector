import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.teal,
      onPrimary: Colors.white,
      primaryContainer: AppColors.lightBlue,
      onPrimaryContainer: const Color(0xFF0B4F5A),
      secondary: AppColors.info,
      error: AppColors.error,
      surface: Colors.white,
      onSurface: const Color(0xFF14202E),
    );
    return _build(scheme, AppColors.background);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF4DD9E8),
      onPrimary: const Color(0xFF031B2E),
      primaryContainer: const Color(0xFF1B3F6B),
      onPrimaryContainer: AppColors.lightBlue,
      secondary: const Color(0xFF7FB8EA),
      error: const Color(0xFFFF8A80),
      surface: const Color(0xFF14275F),
      outlineVariant: const Color(0xFF2B4080),
      onSurface: const Color(0xFFE6EAF2),
    );
    return _build(scheme, const Color(0xFF08143F));
  }

  static TextTheme _text(ColorScheme cs) {
    final base = ThemeData(brightness: cs.brightness).textTheme;
    final inter = GoogleFonts.interTextTheme(base)
        .apply(bodyColor: cs.onSurface, displayColor: cs.onSurface);
    TextStyle poppins(TextStyle? s, double size, FontWeight w) =>
        GoogleFonts.poppins(textStyle: s, fontSize: size, fontWeight: w, color: cs.onSurface);
    return inter.copyWith(
      headlineMedium: poppins(inter.headlineMedium, 28, FontWeight.w700),
      headlineSmall: poppins(inter.headlineSmall, 24, FontWeight.w700),
      titleLarge: poppins(inter.titleLarge, 20, FontWeight.w600),
      titleMedium: poppins(inter.titleMedium, 16, FontWeight.w600),
      titleSmall: poppins(inter.titleSmall, 15, FontWeight.w600),
      bodyLarge: inter.bodyLarge?.copyWith(fontSize: 16),
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 15),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 14),
      labelLarge: inter.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData _build(ColorScheme cs, Color scaffold) {
    final text = _text(cs);
    final radius = BorderRadius.circular(14);
    final gelap = cs.brightness == Brightness.dark;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: scaffold,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: gelap ? const Color(0xFF16296A) : AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        toolbarHeight: 64,
        titleTextStyle: text.titleLarge?.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(26))),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 48),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        extendedTextStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gelap ? const Color(0xFF0F1F54) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(fontSize: 15, color: cs.onSurface.withValues(alpha: 0.7)),
        border: border(cs.outlineVariant.withValues(alpha: 0.8)),
        enabledBorder: border(cs.outlineVariant.withValues(alpha: 0.8)),
        focusedBorder: border(cs.primary, 2),
        errorBorder: border(cs.error, 1.5),
        focusedErrorBorder: border(cs.error, 2),
        errorStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        elevation: 8,
        shadowColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        backgroundColor: cs.surface,
        indicatorColor: cs.primary,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 24,
              color: states.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface.withValues(alpha: 0.6),
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? cs.primary : cs.onSurface.withValues(alpha: 0.6),
            )),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicatorColor: gelap ? cs.primary : Colors.white,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.7)),
        backgroundColor: cs.surface,
        labelStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs.onSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium,
        iconColor: cs.primary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? cs.primary : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface),
          iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.selected) ? cs.onPrimary : cs.onSurface),
          side: WidgetStatePropertyAll(BorderSide(color: cs.outlineVariant)),
          minimumSize: const WidgetStatePropertyAll(Size(0, 46)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: cs.outlineVariant,
    );
  }
}

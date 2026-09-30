import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium, Modern Theme for ResQNav - Demanding Design
/// Color Palette: Deep Purple → Electric Blue → Vibrant Cyan
class PremiumTheme {
  PremiumTheme._();

  // ─── Primary Palette (Deep Purple → Electric Blue) ──────
  static const Color primaryDark = Color(0xFF5B21B6);      // Deep Purple
  static const Color primary = Color(0xFF7C3AED);          // Vibrant Purple
  static const Color primaryLight = Color(0xFFA78BFA);     // Light Purple
  static const Color primarySuper = Color(0xFFE9D5FF);     // Very Light Purple

  // ─── Secondary Palette (Electric Blue) ──────────────────
  static const Color secondary = Color(0xFF0EA5E9);        // Sky Blue
  static const Color secondaryLight = Color(0xFF38BDF8);   // Light Blue
  static const Color secondarySuper = Color(0xFFE0F2FE);   // Very Light Blue

  // ─── Accent Palette (Vibrant Cyan) ──────────────────────
  static const Color accent = Color(0xFF06B6D4);           // Vibrant Cyan
  static const Color accentLight = Color(0xFF22D3EE);      // Light Cyan
  static const Color accentSuper = Color(0xFFCFFAFE);      // Very Light Cyan

  // ─── Status Colors ──────────────────────────────────────
  static const Color success = Color(0xFF10B981);          // Emerald
  static const Color warning = Color(0xFFF59E0B);          // Amber
  static const Color danger = Color(0xFFEF4444);           // Red
  static const Color info = Color(0xFF06B6D4);             // Cyan
  static const Color dangerLight = Color(0xFFFEE2E2);      // Light Red

  // ─── Neutral Palette ────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);      // Almost Black
  static const Color textSecondary = Color(0xFF475569);    // Slate
  static const Color textTertiary = Color(0xFF94A3B8);     // Light Slate
  static const Color textHint = Color(0xFFCBD5E1);         // Very Light Slate

  static const Color background = Color(0xFFF8FAFC);       // Very Light Slate
  static const Color surface = Color(0xFFFFFFFF);          // White
  static const Color surfaceAlt = Color(0xFFF1F5F9);       // Light Surface
  static const Color surfaceAlt2 = Color(0xFFE2E8F0);      // Darker Surface Alt

  static const Color border = Color(0xFFE2E8F0);           // Light Border
  static const Color divider = Color(0xFFCBD5E1);          // Divider

  // ─── Gradients ──────────────────────────────────────────
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [
      Color(0xFF7C3AED), // Purple
      Color(0xFF0EA5E9), // Blue
      Color(0xFF06B6D4), // Cyan
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [
      Color(0xFFDC2626), // Red
      Color(0xFFEF4444), // Light Red
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [
      Color(0xFF059669), // Dark Green
      Color(0xFF10B981), // Emerald
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient nightGradient = LinearGradient(
    colors: [
      Color(0xFF1E293B), // Slate
      Color(0xFF0F172A), // Very Dark
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Shadows ──────────────────────────────────────────────
  static List<BoxShadow> get elevationShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: textPrimary.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get primaryGlow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  static List<BoxShadow> get dangerGlow => [
        BoxShadow(
          color: danger.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
      ];

  // ─── Border Radius ──────────────────────────────────────
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusXXXL = 32.0;

  // ─── Animations ──────────────────────────────────────────
  static const Duration animVeryFast = Duration(milliseconds: 100);
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);
  static const Duration animVerySlow = Duration(milliseconds: 500);

  // ─── Text Themes ────────────────────────────────────────
  static TextTheme _buildTextTheme(TextTheme base) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      // Display - Large prominent headings
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: textPrimary,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: textPrimary,
      ),

      // Headline - Section headers
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: textPrimary,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: textPrimary,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: textPrimary,
      ),

      // Title - Component headers
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: textPrimary,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: textPrimary,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        color: textPrimary,
      ),

      // Body - Regular content
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textPrimary,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: textSecondary,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
        color: textTertiary,
      ),

      // Label - Small UI text
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textPrimary,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: textSecondary,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: textTertiary,
      ),
    );
  }

  /// Modern Material 3 Light Theme with Premium Colors
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
    );

    return base.copyWith(
      // ─── Color Scheme ──────────────────────────────────────
      colorScheme: ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primarySuper,
        onPrimaryContainer: primaryDark,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondarySuper,
        onSecondaryContainer: const Color(0xFF0C4A6E),
        tertiary: accent,
        onTertiary: Colors.white,
        tertiaryContainer: accentSuper,
        onTertiaryContainer: const Color(0xFF044E54),
        error: danger,
        onError: Colors.white,
        errorContainer: dangerLight,
        onErrorContainer: const Color(0xFF5F121B),
        surface: surface,
        onSurface: textPrimary,
        outline: border,
        outlineVariant: divider,
        scrim: textPrimary.withValues(alpha: 0.2),
      ),

      scaffoldBackgroundColor: background,
      textTheme: _buildTextTheme(base.textTheme),

      // ─── App Bar ────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textPrimary, size: 24),
        actionsIconTheme: const IconThemeData(color: textPrimary, size: 24),
      ),

      // ─── Cards ──────────────────────────────────────────
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ─── Buttons - Elevated ──────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textTertiary,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
      ),

      // ─── Buttons - Filled ───────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: textTertiary,
          disabledForegroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ─── Buttons - Outlined ─────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: textTertiary,
          side: const BorderSide(color: primary, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMD),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ─── Buttons - Text ─────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          disabledForegroundColor: textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      // ─── Input Fields ────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: primary, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: danger, width: 2.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMD),
          borderSide: const BorderSide(color: divider),
        ),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        helperStyle: const TextStyle(
          color: textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        errorStyle: const TextStyle(
          color: danger,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        counterStyle: const TextStyle(
          color: textTertiary,
          fontSize: 12,
        ),
      ),

      // ─── FAB (Floating Action Button) ────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: danger,
        foregroundColor: Colors.white,
        elevation: 8,
        highlightElevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
        ),
      ),

      // ─── Dialogs ────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXL),
        ),
        elevation: 16,
        backgroundColor: surface,
        surfaceTintColor: primary,
      ),

      // ─── Bottom Sheet ───────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: primary,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusXXL),
          ),
        ),
      ),

      // ─── Snack Bar ──────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 8,
      ),

      // ─── Icons ──────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: textPrimary,
        size: 24,
      ),

      // ─── Dividers ───────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 16,
      ),

      // ─── Chip ───────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
          side: const BorderSide(color: border),
        ),
        selectedColor: primary,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
        ),
        brightness: Brightness.light,
      ),

      // ─── Bottom Navigation Bar ──────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        elevation: 8,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ─── Switch ─────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary;
          }
          return const Color(0xFFBDBDBD);
        }),
      ),

      // ─── Navigation Bar (Top) ───────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        elevation: 8,
        indicatorColor: primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),

      // ─── Progress Indicator ─────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearMinHeight: 4,
      ),

      // ─── List Tile ──────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        textColor: textPrimary,
        iconColor: textPrimary,
        selectedColor: primary,
        selectedTileColor: primarySuper,
      ),

      // ─── Tooltip ────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: textPrimary,
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showDuration: const Duration(milliseconds: 2000),
        waitDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}

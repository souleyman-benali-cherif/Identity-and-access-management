import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme — deep navy dark mode with indigo accents and Inter typography.
class AppTheme {
  AppTheme._();

  // ─── Color Tokens ──────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF0D1117);
  static const Color surface        = Color(0xFF161B22);
  static const Color surfaceVariant = Color(0xFF21262D);
  static const Color border         = Color(0xFF30363D);
  static const Color accent         = Color(0xFF6E40C9);
  static const Color accentLight    = Color(0xFF8B6CE7);
  static const Color accentSurface  = Color(0xFF1C1435);
  static const Color textPrimary    = Color(0xFFE6EDF3);
  static const Color textSecondary  = Color(0xFF7D8590);
  static const Color textMuted      = Color(0xFF484F58);
  static const Color success        = Color(0xFF2EA043);
  static const Color warning        = Color(0xFFD29922);
  static const Color danger         = Color(0xFFDA3633);
  static const Color info           = Color(0xFF1F6FEB);

  // Status badge colors
  static const Color statusPending   = Color(0xFF7D8590);
  static const Color statusActive    = Color(0xFF2EA043);
  static const Color statusSuspended = Color(0xFFD29922);
  static const Color statusInactive  = Color(0xFF484F58);
  static const Color statusArchived  = Color(0xFFDA3633);

  // Auth level badge colors
  static const Color levelL1 = Color(0xFF1F6FEB);
  static const Color levelL2 = Color(0xFF2EA043);
  static const Color levelL3 = Color(0xFFD29922);
  static const Color levelL4 = Color(0xFFDA3633);

  /// Returns the color for a given status string.
  static Color statusColor(String status) {
    switch (status) {
      case 'Pending':   return statusPending;
      case 'Active':    return statusActive;
      case 'Suspended': return statusSuspended;
      case 'Inactive':  return statusInactive;
      case 'Archived':  return statusArchived;
      default:          return textMuted;
    }
  }

  /// Returns the color for a given auth level string.
  static Color authLevelColor(String level) {
    switch (level) {
      case 'L1': return levelL1;
      case 'L2': return levelL2;
      case 'L3': return levelL3;
      case 'L4': return levelL4;
      default:   return textMuted;
    }
  }

  // ─── Theme Data ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor:    textPrimary,
      displayColor: textPrimary,
    );

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        brightness:   Brightness.dark,
        primary:      accent,
        onPrimary:    Colors.white,
        secondary:    accentLight,
        surface:      surface,
        onSurface:    textPrimary,
        error:        danger,
      ),
      scaffoldBackgroundColor: background,
      textTheme: textTheme,

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textSecondary),
        surfaceTintColor: Colors.transparent,
        shape: const Border(bottom: BorderSide(color: border, width: 1)),
      ),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
        errorStyle: const TextStyle(color: danger, fontSize: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: const BorderSide(color: accent),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentLight,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      dividerTheme: const DividerThemeData(color: border, thickness: 1, space: 1),

      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        iconColor: textSecondary,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceVariant,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: border),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700, color: textPrimary,
        ),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: textSecondary),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accentSurface : surfaceVariant,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : Colors.transparent,
        ),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        dividerColor: border,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 14),
      ),
    );
  }
}

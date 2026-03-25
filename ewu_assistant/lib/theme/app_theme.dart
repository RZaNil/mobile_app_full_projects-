import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  static const Color primaryDark = Color(0xFF0A1F44);
  static const Color primaryMid = Color(0xFF132D5E);
  static const Color primaryLight = Color(0xFF1C3F7A);
  static const Color accent = Color(0xFF0A1F44);
  static const Color accentGlow = Color(0xFF1C3F7A);
  static const Color surfaceDark = Color(0xFFF5F7FA);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0A1F44);
  static const Color textSecondary = Color(0xFF5A6A85);
  static const Color userBubble = Color(0xFF0A1F44);
  static const Color botBubble = Color(0xFFE8EDF4);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFD32F2F);
  static const Color scaffoldBg = Color(0xFFFFFFFF);
  static const Color navBarBg = Color(0xFF0A1F44);
  static const Color navInactive = Color(0xFF8A98B4);
  static const Color pageTint = Color(0xFFF4F6FB);
  static const Color divider = Color(0xFFE0E4EB);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF0F3F8)],
  );

  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFF081834), Color(0xFF102B58), Color(0xFF1C3F7A)],
  );

  static BoxDecoration get glassCard => BoxDecoration(
    color: Colors.white.withValues(alpha: 0.88),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: primaryDark.withValues(alpha: 0.08)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x100A1F44), blurRadius: 14, offset: Offset(0, 6)),
    ],
  );

  static BoxDecoration get premiumCard => BoxDecoration(
    color: surfaceCard,
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: primaryDark.withValues(alpha: 0.06)),
    boxShadow: const <BoxShadow>[
      BoxShadow(color: Color(0x100A1F44), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );

  static BoxDecoration get floatingNavDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(34),
    border: Border.all(color: primaryDark.withValues(alpha: 0.06)),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x120A1F44),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration get navyCardDecoration => BoxDecoration(
    gradient: navyGradient,
    borderRadius: BorderRadius.circular(30),
    boxShadow: const <BoxShadow>[
      BoxShadow(
        color: Color(0x220A1F44),
        blurRadius: 18,
        offset: Offset(0, 10),
      ),
    ],
  );

  static ThemeData get darkTheme {
    final ColorScheme baseScheme = ColorScheme.fromSeed(
      seedColor: primaryDark,
      brightness: Brightness.light,
    );
    final ColorScheme colorScheme = baseScheme.copyWith(
      primary: primaryDark,
      onPrimary: Colors.white,
      secondary: primaryLight,
      onSecondary: Colors.white,
      surface: surfaceCard,
      onSurface: textPrimary,
      error: error,
      onError: Colors.white,
    );
    final TextTheme baseTextTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );
    final TextTheme textTheme = baseTextTheme.copyWith(
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.45),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.45,
      ),
      bodySmall: baseTextTheme.bodySmall?.copyWith(fontSize: 12.5, height: 1.4),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryDark.withValues(alpha: 0.06)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F3F8),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: GoogleFonts.inter(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: primaryDark, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: botBubble,
        selectedColor: primaryDark,
        secondarySelectedColor: primaryDark,
        labelStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBg,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            color: selected ? Colors.white : const Color(0xFF8899B5),
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((
          Set<WidgetState> states,
        ) {
          final bool selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? Colors.white : const Color(0xFF8899B5),
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryDark,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDark,
        contentTextStyle: GoogleFonts.inter(color: Colors.white),
      ),
    );
  }
}

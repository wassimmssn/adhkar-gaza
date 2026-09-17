import 'package:flutter/material.dart';

class AppTheme {
  // ══════════════════════════════════════════════════
  //  COLOR TOKENS — Premium Spiritual Palette
  // ══════════════════════════════════════════════════

  // ── Light Mode ──
  static const Color _primaryLight = Color(0xFF115E54);   // Deep emerald
  static const Color _secondaryLight = Color(0xFFD4AF37); // Noble gold
  static const Color _surfaceLight = Color(0xFFFAF8F5);   // Warm cream
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _textLight = Color(0xFF1A2A2A);
  static const Color _subtextLight = Color(0xFF5A6B6B);

  // ── Dark Mode ──
  static const Color _primaryDark = Color(0xFF2DD4BF);    // Luminescent teal
  static const Color _secondaryDark = Color(0xFFF59E0B);  // Warm amber-gold
  static const Color _surfaceDark = Color(0xFF090D16);     // Obsidian
  static const Color _cardDark = Color(0xFF131B2E);        // Deep navy card
  static const Color _textDark = Color(0xFFF1F5F9);        // Slate 100
  static const Color _subtextDark = Color(0xFF94A3B8);     // Slate 400

  // ── Shared ──
  static const Color _footerBg = Color(0xFF0A3D3E);
  static const String _fontFamily = 'Cairo';

  static Color get footerBackground => _footerBg;

  // ══════════════════════════════════════════════════
  //  LIGHT THEME
  // ══════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.light(
        primary: _primaryLight,
        secondary: _secondaryLight,
        surface: _surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _textLight,
        onSurfaceVariant: _subtextLight,
        surfaceContainerHighest: const Color(0xFFF0EBE4),
        outline: _primaryLight.withValues(alpha: 0.12),
        error: const Color(0xFFDC2626),
      ),
      scaffoldBackgroundColor: _surfaceLight,
      cardColor: _cardLight,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryLight,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardLight,
        elevation: 0,
        shadowColor: _primaryLight.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryLight;
          return const Color(0xFFCBD5D5);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryLight.withValues(alpha: 0.25);
          }
          return const Color(0xFFE8EDED);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: _primaryLight.withValues(alpha: 0.08),
        thickness: 1,
        space: 32,
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  DARK THEME
  // ══════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.dark(
        primary: _primaryDark,
        secondary: _secondaryDark,
        surface: _surfaceDark,
        onPrimary: const Color(0xFF003330),
        onSecondary: Colors.black,
        onSurface: _textDark,
        onSurfaceVariant: _subtextDark,
        surfaceContainerHighest: const Color(0xFF1E293B),
        outline: _primaryDark.withValues(alpha: 0.12),
        error: const Color(0xFFF87171),
      ),
      scaffoldBackgroundColor: _surfaceDark,
      cardColor: _cardDark,
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: _cardDark,
        foregroundColor: _textDark,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: _textDark,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryDark,
          foregroundColor: const Color(0xFF003330),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _primaryDark;
          return const Color(0xFF475569);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primaryDark.withValues(alpha: 0.25);
          }
          return const Color(0xFF1E293B);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: _primaryDark.withValues(alpha: 0.08),
        thickness: 1,
        space: 32,
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  TEXT THEME
  // ══════════════════════════════════════════════════
  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? _textLight : _textDark;
    final subColor =
        brightness == Brightness.light ? _subtextLight : _subtextDark;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 36,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.7,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: subColor,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      labelSmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subColor,
        letterSpacing: 0.3,
      ),
    );
  }
}

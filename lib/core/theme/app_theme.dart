import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Builds Hydrio's light and dark ThemeData from the AppColors tokens.
///
/// Design guideline highlights baked in here:
/// - Minimum body text 16pt; large numeric displays (progress %, target)
///   use 28–34pt via textTheme.displaySmall/headlineLarge.
/// - Minimum touch target 48x48dp; primary buttons full-width, >=52dp tall.
/// - Rounded corners 12–16dp for an approachable feel.
/// - Text scales with system font-scale / Dynamic Type (no hardcoded caps
///   on textScaleFactor).
class AppTheme {
  AppTheme._();

  static const double _radius = 16;
  static const double _buttonHeight = 52;

  static ThemeData get light => _build(Brightness.light, AppPalette.light);
  static ThemeData get dark => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: null, // uses system font stack (SF Pro / Roboto)
      scaffoldBackgroundColor: palette.surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: brightness == Brightness.dark
            ? AppColors.inkDark
            : Colors.white,
        secondary: palette.success,
        onSecondary: Colors.white,
        error: palette.danger,
        onError: Colors.white,
        surface: palette.surface,
        onSurface: palette.ink,
      ),
      dividerColor: palette.divider,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(
            bodyColor: palette.ink,
            displayColor: palette.ink,
          )
          .copyWith(
            // Key numbers: progress %, daily target — 28-34pt per spec.
            displaySmall: base.textTheme.displaySmall?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.ink,
            ),
            // Minimum body size 16pt.
            bodyMedium: base.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: palette.ink,
            ),
            bodySmall: base.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: palette.muted,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: palette.surface,
        foregroundColor: palette.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.panel,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: palette.divider),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(_buttonHeight),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          side: BorderSide(color: palette.primary),
          minimumSize: const Size.fromHeight(_buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.panel,
        selectedColor: palette.primaryTint,
        labelStyle: TextStyle(color: palette.ink, fontSize: 16),
        secondaryLabelStyle: TextStyle(color: palette.primary, fontSize: 16),
        side: BorderSide(color: palette.divider),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.panel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: palette.muted, fontSize: 16),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: palette.surface,
        selectedItemColor: palette.primary,
        unselectedItemColor: palette.muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primary
              : palette.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? palette.primaryTint
              : palette.divider,
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.divider, thickness: 1),
    );
  }
}

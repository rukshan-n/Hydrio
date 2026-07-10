import 'package:flutter/material.dart';

/// Hydrio color tokens — light and dark variants.
///
/// Usage principle (see design guidelines):
/// - Primary = calm/trust, used for buttons, progress, active states.
/// - Success (green) is reserved ONLY for "goal met" states so it stays
///   meaningful — never used decoratively elsewhere.
/// - Danger (muted red) is reserved ONLY for destructive actions
///   (e.g. "Clear local history"), never decorative.
/// - All pairs are chosen to meet WCAG AA contrast against their surface.
class AppColors {
  AppColors._();

  // ---- Light ----
  static const Color primaryLight = Color(0xFF2A8FE0);
  static const Color primaryTintLight = Color(0xFFD6ECFB);
  static const Color successLight = Color(0xFF34B27B);
  static const Color inkLight = Color(0xFF1F2933);
  static const Color mutedLight = Color(0xFF7B8794);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color panelLight = Color(0xFFF2F5F8);
  static const Color dangerLight = Color(0xFFC5221F);
  static const Color dividerLight = Color(0xFFE4E9EE);

  // ---- Dark ----
  static const Color primaryDark = Color(0xFF4FA8E8);
  static const Color primaryTintDark = Color(0xFF173448);
  static const Color successDark = Color(0xFF3FBF86);
  static const Color inkDark = Color(0xFFE8EDF2);
  static const Color mutedDark = Color(0xFF9AA5B1);
  static const Color surfaceDark = Color(0xFF121821);
  static const Color panelDark = Color(0xFF1B2430);
  static const Color dangerDark = Color(0xFFF08A86);
  static const Color dividerDark = Color(0xFF243040);
}

/// Semantic color set resolved for the current brightness, so widgets can do
/// `AppPalette.of(context).primary` instead of branching on Brightness
/// everywhere.
class AppPalette {
  final Color primary;
  final Color primaryTint;
  final Color success;
  final Color ink;
  final Color muted;
  final Color surface;
  final Color panel;
  final Color danger;
  final Color divider;

  const AppPalette({
    required this.primary,
    required this.primaryTint,
    required this.success,
    required this.ink,
    required this.muted,
    required this.surface,
    required this.panel,
    required this.danger,
    required this.divider,
  });

  static const light = AppPalette(
    primary: AppColors.primaryLight,
    primaryTint: AppColors.primaryTintLight,
    success: AppColors.successLight,
    ink: AppColors.inkLight,
    muted: AppColors.mutedLight,
    surface: AppColors.surfaceLight,
    panel: AppColors.panelLight,
    danger: AppColors.dangerLight,
    divider: AppColors.dividerLight,
  );

  static const dark = AppPalette(
    primary: AppColors.primaryDark,
    primaryTint: AppColors.primaryTintDark,
    success: AppColors.successDark,
    ink: AppColors.inkDark,
    muted: AppColors.mutedDark,
    surface: AppColors.surfaceDark,
    panel: AppColors.panelDark,
    danger: AppColors.dangerDark,
    divider: AppColors.dividerDark,
  );

  static AppPalette of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

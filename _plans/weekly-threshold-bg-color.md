# Implementation Plan - Weekly Threshold Background Color

Implement dynamic app-wide background theme changes based on a user's rolling 7-day hydration level. This includes calculating the rolling weekly hydration compliance score in `HydrioProvider`, defining dynamic color palettes for both light/dark modes (brown for low hydration, slate/neutral for mid range, sky blue for high hydration), updating the app theme builder, setting up global smooth transition animations in the main app gateway, and resolving hardcoded UI color references.

## User Review Required

> [!NOTE]
> - The theme transition is app-wide and handled automatically by Flutter's `AnimatedTheme` under the hood when `theme` or `darkTheme` changes in `MaterialApp`.
> - To support premium animations, the transition duration will be set to `600ms` with `Curves.easeInOut`.
> - If the user has system-level reduced motion enabled, animations will be bypassed, and the color change will be instantaneous.
> - For new installs with less than 7 days of history, only tracked days will be averaged (with a fallback to today's target) to prevent punishing the user.

---

## Proposed Changes

### State & Calculations Layer

#### [MODIFY] [hydrio_provider.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/providers/hydrio_provider.dart)
- Define `WeeklyHydrationLevel` enum with three states: `low`, `mid`, `high`.
- Add a getter `WeeklyHydrationLevel get weeklyHydrationLevel` that:
  1. Computes the rolling 7-day window (today + prior 6 calendar days).
  2. Iterates over each day in the window.
  3. Sums `totalMl` and `targetMl` from existing `DailySummary` database models.
  4. Includes today's `_todaySummary` total and calculated target.
  5. Implements the edge-case check: If a day in the past has no database entry (e.g., app was not installed or no onboarding completed), omit that day's target/totals from calculations to prevent penalizing the user. Ensure at least today's target is used to prevent division-by-zero.
  6. Determines the level: `< 50%` target is `WeeklyHydrationLevel.low`, `50%` to `< 80%` is `WeeklyHydrationLevel.mid`, and `>= 80%` is `WeeklyHydrationLevel.high`.
  7. Returns the computed `WeeklyHydrationLevel`.

---

### Theme & Colors Layer

#### [MODIFY] [app_colors.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/theme/app_colors.dart)
- Define colors for LOW, MID, and HIGH states for both Light and Dark themes.
- Update `AppPalette` class constructor and instances to map colors dynamically based on `WeeklyHydrationLevel` and brightness.
- Add helper method `AppPalette.resolve(Brightness brightness, WeeklyHydrationLevel level)` to construct or retrieve the palette matching the current hydration state.

#### [MODIFY] [app_theme.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/theme/app_theme.dart)
- Update `light` and `dark` getters (or define `build(Brightness brightness, WeeklyHydrationLevel level)`) to accept `WeeklyHydrationLevel`.
- Pass the resolved palette from `AppPalette.resolve(brightness, level)` into `_build`.
- Ensure `primaryContainer` color is explicitly set to `palette.primaryTint` in the `ColorScheme` constructor so that components like the `WaterBowl` progress track update dynamically.

---

### App Setup & Core Integration

#### [MODIFY] [main.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/main.dart)
- Read the active hydration level reactively from `HydrioProvider` in `HydrioApp.build`:
  ```dart
  final hydrationLevel = context.select<HydrioProvider, WeeklyHydrationLevel>((p) => p.weeklyHydrationLevel);
  ```
- Pass `hydrationLevel` to `AppTheme.build(Brightness.light, hydrationLevel)` and `AppTheme.build(Brightness.dark, hydrationLevel)`.
- Configure `themeAnimationDuration: const Duration(milliseconds: 600)` and `themeAnimationCurve: Curves.easeInOut` on `MaterialApp` to enable smooth global color fades.

---

### Screens & Widgets Refactoring

#### [MODIFY] [today_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/today_screen.dart)
- Modify `_QuickAddChip` background color property from hardcoded `const Color(0xff1B2430)` and `const Color(0xffF2F5F8)` to read dynamically from `theme.cardTheme.color`.

#### [MODIFY] [settings_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/settings_screen.dart)
- Refactor the helper methods in `_SettingsScreenState` to fetch color configurations from `theme` rather than hardcoding static color values:
  - `_getPanelColor(ThemeData theme)`: Return `theme.cardTheme.color`.
  - `_getInkColor(ThemeData theme)`: Return `theme.textTheme.bodyMedium?.color`.
  - `_getMutedColor(ThemeData theme)`: Return `theme.textTheme.bodySmall?.color`.
  - `_getDangerColor(ThemeData theme)`: Return `theme.colorScheme.error`.

#### [MODIFY] [history_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/history_screen.dart)
- Modify the Export Button background container decoration to use `theme.colorScheme.surface` or `theme.cardTheme.color` instead of hardcoded `Colors.white` and `const Color(0xff1B2430)`.

---

## Verification Plan

### Automated Tests
- Run all unit and widget tests using `flutter test`.
- Add test cases verifying:
  - `weeklyHydrationLevel` calculation under normal circumstances (7 days of logs).
  - `weeklyHydrationLevel` calculation with missing past summaries (fewer than 7 days, verification of no-penalty logic).
  - Dynamic palette resolution correctly matches low (brown), mid (slate), and high (sky blue) states.

### Manual Verification
- Run the app locally on an iOS simulator or Android emulator.
- View Today, History, and Settings screens in Light and Dark mode.
- Log drinks to raise the level and observe the smooth transition from Earthy Brown (if below 50% weekly average) to Slate (mid range) to Sky Blue (above 80% average).
- Modify age/gender/daily targets in settings and verify background updates seamlessly.
- Test system reduced motion setting to verify transition transitions instantly without animation.

# Implementation Plan - Welcome Screen Onboarding

Implement the Welcome Screen onboarding flow for Hydrio. This includes introducing the `onboarding_complete` setting, designing the high-fidelity Welcome Screen matching the design guidelines, and adding placeholder Setup screens.

## User Review Required

> [!NOTE]
> The Welcome Screen will become the initial screen on first-time app launches. Returning users with `onboarding_complete = true` will continue to boot directly into the Home screen.
> Since subsequent onboarding step screens (1 of 5) are not yet fully specified in this task, a clean placeholder `SetupScreen` with Step 1 of 5 will be created to verify navigation and onboarding completion.

## Proposed Changes

### Settings & Provider

#### [MODIFY] [settings_model.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/models/settings_model.dart)
- Add `onboardingComplete` boolean field.
- Update `defaultSettings()` factory to default `onboardingComplete` to `false`.
- Update `copyWith()`, `toMap()`, and `fromMap()` serialization to include `onboarding_complete`.

#### [MODIFY] [hydrio_provider.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/providers/hydrio_provider.dart)
- Load `onboarding_complete` flag from `SharedPreferences` in `_loadSettingsFromPrefs()`.
- Persist `onboarding_complete` flag in `updateSettings()`.
- Implement a helper method `completeOnboarding()` to quickly flag onboarding as complete (e.g. for transitioning from setup to main home dashboard).

### User Interface Screens

#### [NEW] [welcome_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/welcome_screen.dart)
- Build a stateless `WelcomeScreen` widget.
- Center a vertical column featuring:
  - Circular avatar/container matching `primaryContainer` color containing a `primaryColor` themed water droplet icon (`Icons.water_drop`).
  - Bold "Hydrio" typography.
  - Tagline text: "Stay hydrated, every day."
  - Secondary line text: "Private · Offline · Simple"
- Pin a CTA layout at the bottom:
  - "Get Started" ElevatedButton with height `>= 52dp` and border radius `12–16dp`.
  - Tap handler: Navigates to `SetupScreen(step: 1)`.
  - Small muted privacy caption: "Your data stays on your phone."

#### [NEW] [setup_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/setup_screen.dart)
- Create a placeholder `SetupScreen` taking a `step` argument (1 to 5).
- Include simple text indicating "Step X of 5".
- Add a temporary "Complete Onboarding" button that calls `provider.completeOnboarding()` and clears the navigation stack to route to the home dashboard.

### Core Routing Configuration

#### [MODIFY] [main.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/main.dart)
- Read `onboardingComplete` setting reactively via `context.select<HydrioProvider, bool(...)`.
- Dynamically set the `home` property of `MaterialApp`:
  - `onboardingComplete ? const HydrioPlaceholderHome() : const WelcomeScreen()`

---

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure serialization logic and unit tests still compile and succeed.
- Update or create a widget test in `test/widget_test.dart` to verify that `WelcomeScreen` is loaded when `onboarding_complete` is false, and that clicking "Get Started" navigates properly.

### Manual Verification
- We can inspect the layout, padding, font sizes, and color contrast using screenshots/visual outputs if running on a simulator or device.

# Implementation Plan - Today Screen Dashboard

Implement the high-fidelity Today Screen dashboard for Hydrio. This includes creating the primary navigation wrapper (`HomeScreen`), implementing the circular progress ring with custom animation support, integrating reactive intake metrics and motivational messages, providing quick-add capabilities, and handling date rollover and accessibility requirements.

## User Review Required

> [!NOTE]
> - The new `HomeScreen` will replace `HydrioPlaceholderHome` as the primary screen loaded once onboarding is complete.
> - The tab bar will navigate between Today (active), History (placeholder), and Settings (placeholder/existing screen).
> - Since a dedicated Add Water screen and History/Settings screens are not yet fully implemented, placeholders will be designed to allow seamless navigation validation.

## Proposed Changes

### Core Integration & Navigation

#### [MODIFY] [main.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/main.dart)
- Replace the `HydrioPlaceholderHome` widget with the new `HomeScreen` in `HydrioGateway`'s routing condition.
- Delete the local `HydrioPlaceholderHome` class definition from `main.dart` to keep the entrypoint file clean.

#### [NEW] [home_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/home_screen.dart)
- Build a stateful `HomeScreen` widget managing a bottom navigation bar.
- Define a list of three child views:
  1. `TodayScreen` (active tab by default).
  2. `HistoryScreen` (temporary placeholder display).
  3. `SettingsScreen` (temporary placeholder display).
- Implement state transitions using `BottomNavigationBar` and standard active routing indicators.

### Today Screen Componentry

#### [NEW] [today_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/today_screen.dart)
- Build a stateful `TodayScreen` widget matching the high-fidelity mockup.
- **Widgets**:
  - **App Bar**: Left-aligned "Today" title with a settings icon shortcut on the top-right (switching navigation index to Settings).
  - **Animated Circular Progress Ring**:
    - Build a custom widget (either using a `CustomPainter` or a composition of custom layered radial components).
    - Animate progress changes using an `AnimationController` that animates progress value changes.
    - Check system accessibility configurations via `MediaQuery.of(context).disableAnimations`. If `true`, disable the progress animation and render the progress statically.
    - Wrap the progress percentage at 1.0 (100%) visually but display the exact consumed value (e.g. 2,500 mL / 2,000 mL) to represent overflow distinctly.
  - **Motivational Message & Remaining Text**:
    - Display the provider's dynamic encouraging message below the progress ring.
    - Color the text dynamically: `Success` color (`#34B27B` / `#3FBF86`) when the daily goal is achieved, and standard muted/ink text beforehand.
  - **Quick-Add Chips**:
    - Display a scrollable row of chips (presets: 100 mL, 200 mL, 250 mL, 500 mL, plus the default `cupSizeMl` from provider settings).
    - Bind a tap listener to each chip to immediately trigger `provider.logDrink(amount)` without asking for confirmation.
    - Display values in `ml` or `fl oz` depending on `provider.settings.unit` utilizing formatting helpers (`provider.formatVolume`).
  - **Add Water CTA**:
    - A full-width `ElevatedButton` labeled "+ Add Water" that navigates to `AddWaterScreen`.
- **Date Rollover Management**:
  - Implement a `WidgetsBindingObserver` to watch for app resume cycles.
  - On app resume or via a periodic background timer, compare `DateTime.now()` date key format ("YYYY-MM-DD") against the provider's current date.
  - If the date has rolled over to midnight:
    - Save/commit the prior day's summary into `daily_summary` via `provider.loadTodayData()` (or a specific rollover trigger in provider).
    - Clear active logs in view and reset progress tracking to `0`.

#### [NEW] [add_water_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/add_water_screen.dart)
- Create a simple placeholder screen for `AddWaterScreen` to facilitate navigation.
- Include a back arrow in the App Bar and placeholder message.

## Verification Plan

### Automated Tests
- Run tests via `flutter test`.
- **New Tests to Implement** in [widget_test.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/test/widget_test.dart):
  - Verify that the `HomeScreen` loads the `TodayScreen` as the default active tab.
  - Verify that tapping the quick-add chips immediately logs water and triggers state updates in the UI (percent changes).
  - Verify that tapping the "+ Add Water" button successfully pushes the `AddWaterScreen` route.
  - Verify that switching tabs via the bottom bar displays the correct views.

### Manual Verification
- Launch the application on a simulator/device.
- Verify color contrast (Light/Dark themes) and visual appeal of the circular progress ring against the mockup image.
- Test both metric/imperial setting toggles and verify the Quick-Add chip displays change labels correctly.

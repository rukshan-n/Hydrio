# Implementation Plan - Settings Screen

Implement the settings screen for Hydrio based on the feature specification. This includes building the settings UI with modal picker sheets, integrating it into the main navigation flow, implementing safety validations, and providing the capability to clear history while preserving settings.

## User Review Required

> [!IMPORTANT]
> - **Liters Format Support (`"l"`)**: The underlying settings model (`HydrioSettings`) currently specifies `unit` as a string (`"ml"` or `"fl oz"`). To support the requested mL vs. L toggle, we will add Liters (`"l"`) as a valid unit option in `HydrioSettings.unit`, where volumes are formatted dynamically to Liters (e.g., `2,200 mL` -> `2.2 L`) for presentation, while preserving standard mL storage in the SQLite database.
> - **Confirmation Prompts**: The confirmation prompt for clearing local history will use a native or styled modal alert with a warning description, as it is a destructive action. Wiping data resets the local databases immediately, updating the Today screen's progress ring to 0 mid-day.

## Proposed Changes

### Core State & Provider

#### [MODIFY] [hydrio_provider.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/providers/hydrio_provider.dart)
- Implement `clearHistoryOnly()`:
  - Deletes all data from `drink_log` and `daily_summary` tables in SQLite using `_db.clearAllData()`.
  - Reloads today's data (`loadTodayData()`) and history (`loadHistoryData()`) which triggers UI rebuilds (resetting today's volume consumed to 0 and progress to 0% immediately).
  - Preserves settings stored in SharedPreferences.
- Update `formatVolume(int amountMl)` and `unitSuffix` helper properties:
  - Add support for `'l'` (Liters).
  - If `settings.unit == 'l'`, format as `(amountMl / 1000.0).toStringAsFixed(1)` with unit suffix `L`.
  - If `settings.unit == 'ml'`, format as `$amountMl` with unit suffix `ml`.
  - If `settings.unit == 'oz'`, format as `toOz(amountMl)` with unit suffix `fl oz`.

### User Interface Screen

#### [NEW] [settings_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/settings_screen.dart)
- Build a stateful widget `SettingsScreen` containing a scrollable `ListView`.
- Display preference rows:
  - **Gender**: displays current gender, taps to open a modal sheet containing a segmented control or chip selector with options: Female, Male, Other.
  - **Age**: displays current age, taps to open a modal with scrollable numbers or text field. Validates range `13–100`.
  - **Daily target**: displays target. Tapping opens a modal text input with validation floor/ceiling (`500–6000 mL`). Saving sets `manual_override = true` and updates target.
  - **Reminder time (range)**: displays wake and sleep time range. Taps to open a modal with consecutive time pickers. Validates wake < sleep with a sane window (awake `4–20 hours`).
  - **Cup/bottle size**: displays default size. Tapping opens a modal input. Validates positive integer.
  - **Unit (mL/L)**: displays current active unit format (`mL` or `L`). Tapping opens a segmented control or action sheet to switch format units.
  - **Notifications (on/off)**: toggles reminder scheduling. If toggled off, calls `cancelAllReminders()`. If toggled on, runs `scheduleWindowReminders()`.
  - **Export email**: displays default email, taps to open a modal text field. Validates email format.
- Add a destructive "Clear local history" button inside a panel styled container with **Danger** red color (`#C5221F` / `#F08A86`).
  - Triggers confirmation dialog showing warning text.
  - Wipes database tables via `provider.clearHistoryOnly()`.
- Add **Privacy Note** pinned at the bottom: "Your data stays on your phone."
- Implement target reset prompt logic:
  - If `settings.manualOverride` is active, changing Gender or Age prompts the user: *"Would you like to reset your daily target to the recommended automatic target based on your updated settings?"*
  - If accepted, overrides manual setting and re-calculates target; if rejected, preserves manual target.

### Main Navigation Integration

#### [MODIFY] [home_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/home_screen.dart)
- Import `settings_screen.dart`.
- Replace `PlaceholderScreen(title: 'Settings')` with `const SettingsScreen()`.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to verify no regressions in existing flows.
- Add test cases in `test/widget_test.dart` or a new `test/settings_test.dart`:
  - Verify that changing Gender or Age with manual override prompts the reset question.
  - Verify that toggling display units correctly formats text (e.g. mL vs L).
  - Verify that clearing local history keeps settings unchanged but empties daily summary / drink log.
  - Verify input bounds validations (age bounds, daily target bounds, time range sanity).

### Manual Verification
- Launch application on simulator/device.
- Complete onboarding and log water logs.
- Go to Settings, change Gender/Age, verify manual override prompt triggers.
- Change Unit from mL to L, verify Today ring consumption formatting updates instantly.
- Toggle notifications off, check that all reminders are cancelled, and check that toggling back on reschedules them.
- Tap "Clear local history", confirm, and verify Today screen progress resets to 0% immediately.

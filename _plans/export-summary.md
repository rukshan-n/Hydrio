# Implementation Plan - Export Summary Screen

Implement the Export Summary Screen for Hydrio. This includes adding the `url_launcher` dependency for pre-filling email drafts, extending `ExportHelper` with template generation, updating `HydrioProvider` with helper getters, building the high-fidelity `ExportSummaryScreen`, and routing navigation from the History screen.

## User Review Required

> [!NOTE]
> - **Dependency Additions**: We will add `url_launcher` to `pubspec.yaml` to trigger `mailto:` intent logic directly for pre-filling emails when a valid email address is provided.
> - **Email Persistence**: When a user inputs an email address and successfully triggers a share/email action, that email address is persisted locally to `settings.export_email` so it is automatically pre-filled next time.

## Proposed Changes

### Dependencies

#### [MODIFY] [pubspec.yaml](file:///Users/rukshanmac/Project/SCIT/Hydrio/pubspec.yaml)
- Add `url_launcher: ^6.3.1` (or suitable version) under `dependencies`.

---

### Data Models & State Providers

#### [MODIFY] [hydrio_provider.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/providers/hydrio_provider.dart)
- Expose a getter for all historical logs:
  `List<DrinkLog> get allHistoryLogs => _allHistoryLogs;`
- Expose a helper to extract daily summaries and logs for a given period key (`Daily`, `Weekly`, `Monthly`):
  - Refactor the filtering logic in `exportPeriodData(String period)` to a reusable helper `getPeriodData(String period)` returning summaries and logs.
- Add a helper `updateExportEmail(String email)` to update settings.exportEmail and persist it via `SharedPreferences`.

#### [MODIFY] [export_helper.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/utils/export_helper.dart)
- Extract CSV formatting into a static `generateCsvContent` method.
- Add a static `generateEmailContent` method that outputs:
  - Subject and summary lines (daily target, total intake, completion percentage, success/missed counts).
  - Day-by-day table/rows representing the daily history within the period.
  - Ordered logs listing the timestamps and volumes.
- Add a static `launchMailto({required String email, required String subject, required String body})` method to compile and launch a `mailto` URL intent using `url_launcher`.

---

### User Interface Screens

#### [NEW] [export_summary_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/export_summary_screen.dart)
- Build `ExportSummaryScreen` (StatefulWidget) with the following structure:
  - **AppBar**: Navigation back button, Title "Export Summary".
  - **Email TextField**:
    - "Send summary to" label and input text field (keyboard set to email).
    - Prefilled from `provider.settings.exportEmail`.
    - Local state for email validation.
  - **Period Selector**: Segmented toggle buttons (Daily, Weekly, Monthly) default-selected to the passed parameter `initialPeriod`.
  - **Format Selector**: Segmented toggle buttons (Email text, CSV file) defaulting to "Email text".
  - **Preview Panel**:
    - A styled container using the `Panel` color (`#F2F5F8` / `#1B2430`) and monospaced font.
    - Internally scrollable to handle large content lists.
    - Updates dynamically in real-time on any input, format, or period changes.
  - **Open Share Sheet Button**:
    - Full-width CTA button (height `>= 52dp`, border radius `12–16dp`).
    - Disabled if the selected period has zero data (displays a warning note instead: *"No hydration records found for this period."*).
    - Triggers `mailto` launch if email is valid and filled, else falls back to launching the native share sheet with the CSV file attachment or email text.
    - Cleans up any generated temp CSV files from cache on completion or widget dispose.
  - **Privacy Caption**: Small caption below button reminding that nothing is uploaded to external servers.

#### [MODIFY] [history_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/history_screen.dart)
- Modify the Export Button `onTap` handler:
  - Replace the direct `provider.exportPeriodData(_selectedPeriod)` trigger with a navigation route pushing `ExportSummaryScreen(initialPeriod: _selectedPeriod)` onto the stack.

---

## Verification Plan

### Automated Tests
- Run `flutter test` to ensure existing functionality remains unbroken.
- Add unit tests in `test/export_test.dart` to assert:
  - Dynamic generation of correct CSV and Email text formats for empty, single-day, and multi-day drink log inputs.
  - Email format validation functions correctly identify valid and invalid strings.
- Add widget tests verifying:
  - Toggle changes properly trigger updates in the preview panel.
  - Email pre-fill is present when a value exists in mock settings.

### Manual Verification
- Launch the application and click the "Export / Email summary" button from the History tab.
- Enter both valid and invalid email addresses, verifying that validation updates UI colors and intent paths correctly.
- Select different periods (Daily, Weekly, Monthly) and formats (Email text, CSV) and verify the preview updates live.
- Trigger the share sheet and verify standard OS sheet is displayed.
- Test with an empty log period to verify the CTA is disabled and a warning note appears.

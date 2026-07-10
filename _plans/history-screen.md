# Implementation Plan - History Screen

Implement the high-fidelity History Screen for Hydrio. This includes extending the state manager (`HydrioProvider`) with date range aggregation and backfilling logic, building the history screen layout, integrating a bar chart with a dashed target line, displaying summary statistics cards, and linking the export button to the CSV share utility.

## User Review Required

> [!IMPORTANT]
> - **Backfilling Logic**: If a user does not open the app on a given day, there will be no database row for that date in `daily_summary`. The aggregation logic will dynamically generate virtual "missed" summaries (0 mL intake, status = 'missed') for any missing days between the start of the selected period and today. This ensures that missed days are factored into average intake calculations and missed day counts correctly.
> - **Chart Libraries**: We will utilize the existing dependency `fl_chart` to render the bar chart, Y-axis dashed line, and tooltips.

## Proposed Changes

### State & Aggregation Logic

#### [MODIFY] [hydrio_provider.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/core/providers/hydrio_provider.dart)
- Implement a helper method to compute historical stats and daily summaries for a selected period (`"Daily"`, `"Weekly"`, `"Monthly"`):
  - **Date Ranges**:
    - `Daily`: Current day (today) only.
    - `Weekly`: Monday of the current week to the current day.
    - `Monthly`: 1st of the current month to the current day.
  - **Querying**:
    - Read saved daily summaries from the database for the given range.
    - Append today's live/running total summary (since today's summary is not yet finalized/synced in the database).
  - **Backfilling**:
    - Identify any dates in the range that have already occurred but have no database entry in `daily_summary`.
    - Generate a virtual `DailySummary` for these days with `totalMl = 0`, `status = 'missed'`, and `targetMl = settings.dailyTargetMl`.
  - **Sorting**:
    - Sort the list chronologically by day key.
  - **Stats Aggregation**:
    - Calculate the total number of "Success" days (where status is `"success"`).
    - Calculate the total number of "Missed" days (where status is `"missed"`).
    - Calculate the average intake per day (average of `total_ml` across all days in the period).

### User Interface Screens

#### [NEW] [history_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/history_screen.dart)
- Build a stateful `HistoryScreen` widget:
  - **Segmented Control**:
    - Implement a `SegmentedButton` or tab bar at the top to select the range (`Daily`, `Weekly`, `Monthly`).
  - **Target Line & Bar Chart**:
    - Integrate `fl_chart.BarChart`.
    - Configure `ExtraLinesData` with a `HorizontalLine` representing the user's daily target. Draw this line dashed using `dashArray`.
    - Render vertical rods for each daily summary in the selected range.
      - Color bars in `Success` green (`#34B27B` / `#3FBF86`) if target met.
      - Color bars in `Primary` blue (`#2A8FE0` / `#4FA8E8`) if target missed.
    - Set up bottom titles indicating day of week (e.g. M, T, W...) for Weekly, day of month for Monthly, or hourly bins for Daily.
    - Set up touch responses (`BarTouchData`) to show tooltips displaying date, exact volume (mL or fl oz), and completion percentage.
  - **Stat Cards Row**:
    - Build three cards in a row: "Success", "Missed", and "Avg/day".
    - Use the `Panel` color (`#F2F5F8` / `#1B2430`) with rounded corners (`12–16dp`).
    - Convert values dynamically to `fl oz` if the setting demands it.
    - Format average values >= 1000 mL to Liters (L) (e.g., `2.4 L`) for clean UI scaling.
  - **Export Affordance**:
    - Add the "Export / Email summary" button at the bottom.
    - On tap, call `ExportHelper.shareCsvExport(...)` passing the summaries and logs filtered for the selected period.

### Core Routing

#### [MODIFY] [home_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/home_screen.dart)
- Replace `PlaceholderScreen(title: 'History')` with `const HistoryScreen()` inside the `pages` list.
- Import `history_screen.dart`.

---

## Verification Plan

### Automated Tests
- Run `flutter test`.
- Add test assertions to verify:
  - Correct date-range calculations and backfilling of missing days in the provider logic.
  - Unit formatting logic converts values correctly to `oz` or L.
  - Widget test verifying history screen loads with initial SegmentedButton, BarChart, and StatCards.

### Manual Verification
- Deploy to simulator or physical device.
- Toggle between Daily, Weekly, and Monthly tabs and observe the chart and stat card updates.
- Test in both light and dark themes to verify the chart bars, target lines, and cards conform to the aesthetic guidelines.
- Click the Export button to verify the share sheet launches with pre-filled CSV data.

# History Screen Spec

The History Screen provides users with a comprehensive view of their historical hydration logs and performance metrics across daily, weekly, and monthly time ranges. It features an interactive bar chart, key statistics, and an export mechanism to review or share hydration performance.

## Screen Overview

A read-only insights page displaying hydration metrics. The layout includes a segmented control for time periods, a bar chart detailing daily volumes with a dashed target line, three stat cards summarizing success, missed days, and average intake, and a full-width CTA button to export the data.

```
+-----------------------------------+
|               History             |
|                                   |
|       +-------------------+       |
|       | Daily |Weekly|Monthly|    |
|       +-------------------+       |
|                                   |
|                Target: 2,200 mL   |
|      | | | | - - - - - - - - - -  |
|      | | | |   |   |   |   |   |  |
|      | | | |   |   |   |   |   |  |
|      +-+-+-+---+---+---+---+---+  |
|      M  T  W   T   F   S   S      |
|                                   |
|  +---------+ +---------+ +-----+  |
|  |    5    | |    2    | |2.4 L|  |
|  | Success | | Missed  | |Avg/d|  |
|  +---------+ +---------+ +-----+  |
|                                   |
|  +-----------------------------+  |
|  |    Export / Email summary   |  |
|  +-----------------------------+  |
|                                   |
|  [Today]   [History]   [Settings] |
+-----------------------------------+
```

## Widgets & Layout

The screen layout is structured as a scrollable vertical column (to prevent layout overflows) with the following components:

- **App Bar**:
  - Title: "History" in a large, prominent, bold font aligned to the left.
- **Time Range Segmented Control (Center)**:
  - Layout: A centered horizontal segmented button control (e.g., `SegmentedButton` in Flutter or a custom tab indicator).
  - Segments: **Daily**, **Weekly**, and **Monthly**.
  - Styling: High-fidelity toggle with subtle background fill, using `Panel` background and active state highlighting using `Primary` / `Primary Tint`.
- **Target Indicator & Bar Chart (Center)**:
  - **Target Label**: Positioned above the chart on the right, displaying the current target (e.g., "Target 2,200 mL" or "Target 74.4 fl oz" depending on unit settings).
  - **Bar Chart**: A custom bar chart showing the hydration volume for each interval in the selected range.
    - **Y-Axis Overlay**: A horizontal dashed line representing the daily target value.
    - **Bars**: Vertical bars representing intake.
      - If a bar meets or exceeds the target, it is colored in **Success** green.
      - If a bar is below the target, it is colored in the **Primary** blue or a muted tint.
    - **X-Axis Labels**: Underneath each bar, displaying short date tags (e.g., "M, T, W..." for Weekly, "1, 2, 3..." for Monthly, or hourly/time tags for Daily).
- **Stat Cards Row (Below Chart)**:
  - A horizontal row containing three cards of equal width:
    - **Success Card**: Displays the count of days in the selected period that met or exceeded the daily water target (e.g., "5" with subtitle "Success").
    - **Missed Card**: Displays the count of days in the selected period that did not meet the daily water target (e.g., "2" with subtitle "Missed").
    - **Average Card**: Displays the average daily intake for active days in the selected period (e.g., "2.4 L" or "81.2 oz", formatted dynamically with appropriate unit and suffix).
  - Styling: Cards use the `Panel` background with rounded corners (`12–16dp`) and clear typographic hierarchy (value in Accent scale `28–34pt`, labels in `16pt` body font).
- **Export Affordance (Bottom)**:
  - A full-width panel button labeled "Export / Email summary".
  - Height: `>= 52dp`, border radius: `12–16dp`.
  - Styling: White surface background with subtle shadow or outline, displaying high-contrast text.
- **Bottom Tab Bar**:
  - Pinned to the bottom.
  - Active Tab: **History** (highlighted in active `Primary` color).

## State & Data

The History Screen is read-only but reactive, reading data dynamically from `HydrioProvider`:

- **Active Tab Selection**:
  - A local state tracks the active segmented control option (`Daily`, `Weekly`, or `Monthly`).
  - Switching the selection triggers a re-query and animation refresh.
- **Data Querying & Aggregation Logic**:
  - **Daily View**:
    - Displays today's intake progress.
    - Bar chart shows today's individual logs or hourly bins (e.g., aggregated every 2 hours from wake time to sleep time) fetched live from the `drink_log` table.
    - Stat cards: Success = 1 if today's total >= target else 0; Missed = 1 if today's total < target else 0; Average = today's running total.
  - **Weekly View**:
    - Displays the daily totals of the current calendar week (Monday to Sunday).
    - Queries the `daily_summary` table for previous days of the current week.
    - Integrates the live running total of today from `drink_log` (or `todaySummary` from the provider).
    - Stat cards: Aggregates the 7 days of the week.
  - **Monthly View**:
    - Displays the daily totals of the current calendar month (1st to last day of month).
    - Queries the `daily_summary` table for previous days of the current month.
    - Integrates the live running total of today.
    - Stat cards: Aggregates the days of the current month up to the current day.
- **Measurement Unit Formatting**:
  - Volumes on target labels, tooltips, and stat cards must dynamically convert from ML to fluid ounces (fl oz) based on the user's unit settings (`settings.unit == 'oz'`), converting via `0.033814` conversion factor.
  - Large values (e.g., thousands of mL) in the average stat card can be formatted into liters (L) or left as mL/oz depending on screen density and length rules (e.g., `2.4 L` for `2400 mL`). If mL, convert to L for average card if >= 1000 mL (e.g. `2.4 L` instead of `2400 mL`), but if oz, keep it as `oz` (e.g., `81.2 oz`).

## Interactions & Navigation

- **Segmented Control Tap**:
  - Tapping "Daily", "Weekly", or "Monthly" switches the state, runs the appropriate query/filtering, and animates the bar heights to their new values.
- **Chart Bar Interactivity (Optional Nice-to-Have)**:
  - Tapping a bar can display a floating tooltip/detail overlay showing:
    - The date or time range.
    - The specific intake volume.
    - The percentage of target met.
- **Export Button Tap**:
  - Navigates to the **Export Summary** flow. It pre-populates or filters the exported logs and summaries based on the currently selected period (Daily = Today's logs, Weekly = Current week's logs, Monthly = Current month's logs).
  - Triggers the system sharing sheet using the `ExportHelper.shareCsvExport` utility.

## Design & Aesthetics Compliance

This screen must comply with the design rules specified in [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (Standard Bars / Active Indicator)** | `#2A8FE0` | `#4FA8E8` |
| **Success Color (Goal Met Bars)** | `#34B27B` | `#3FBF86` |
| **Primary Tint (Segmented Control Background)** | `#D6ECFB` | `#173448` |
| **Text Ink** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Axis / Card Subtitles)** | `#7B8794` | `#9AA5B1` |
| **Surface Background** | `#FFFFFF` | `#121821` |
| **Panel (Stat Cards / Segmented Control Track)** | `#F2F5F8` | `#1B2430` |

### Typography & Touch Targets
- **Stat Card Value**: Highlighted in Accent scale `28–34pt` with dynamic scale support.
- **Minimum Body / Subtitles**: `16pt`
- **Interactive Targets (Buttons, Segments)**: Minimum dimensions `>= 48×48dp`.
- **CTA Button**: Height `>= 52dp`, border radius `12–16dp`.

## Edge Cases & Accessibility

- **No History Yet (First Day of Use)**:
  - If the database is empty or has no previous daily summaries, show a clean, friendly empty state or placeholder graph indicating that tracking has just started, rather than an empty/broken chart structure.
- **Partial Month/Week View**:
  - When viewing in the middle of a week or month (e.g., viewing a monthly graph on the 3rd of the month), the chart and average statistics must only show/aggregate days that have actually occurred.
  - Future days in the week/month must not be charted or included in averages.
- **Backfilling Missed Days**:
  - If a user did not open the app on a specific day, there will be no row in the `daily_summary` table for that `day_key`.
  - During weekly/monthly aggregation, the application must virtualize these missing days as "missed" (with `total_ml` = 0, status = "missed") and include them in the statistics calculations (increasing the "Missed" count and reducing the "Avg/day" average accordingly) rather than silently skipping them.
- **Reduced Motion Support**:
  - Respects system accessibility preferences (`MediaQuery.of(context).disableAnimations`). If enabled, layout changes, bar size updates, and segmented transitions occur immediately with no animation.

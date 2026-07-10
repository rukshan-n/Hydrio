# Export Summary Spec

The Export Summary Screen allows users to preview and share their hydration data (summaries and individual drink logs) for a selected period (Daily, Weekly, or Monthly) in either raw CSV format or as structured email text. The data is exported locally using the phone's native sharing capabilities without sending any data to a remote server.

## Screen Overview

A clean, structured screen with a navigation back arrow, input for the recipient's email address, period and format selectors, an in-app interactive preview panel of the generated output, and a prominent call-to-action to launch the system sharing sheet.

```
+-----------------------------------+
| <- Export Summary                 |
|                                   |
|  Send summary to                  |
|  [ Enter email address          ] |
|                                   |
|  Period                           |
|  [ Daily ] [ Weekly ] [ Monthly ] |
|                                   |
|  Format                           |
|  [ Email text ] [ CSV file ]      |
|                                   |
|  Preview                          |
|  +-----------------------------+  |
|  | Subject: Hydrio Summary     |  |
|  | ...                         |  |
|  |                             |  |
|  +-----------------------------+  |
|                                   |
|        [ Open Share Sheet ]       |
|  Uses your phone's mail/share app.|
|  Nothing is sent to any server.   |
+-----------------------------------+
```

## Widgets & Layout

The screen is structured as a vertical, scrollable layout with the following components:

- **App Bar**:
  - A back navigation arrow button on the left (directing the user to the previous screen, typically the History screen).
  - Title: "Export Summary" in standard header typography.
- **Recipient Email Field**:
  - Label: "Send summary to" (minimum body font size `16pt`).
  - Text Input: A text field for entering a destination email address.
    - Placeholder: "Enter email address (optional)".
    - Keyboard Type: Email address keyboard.
    - Border radius: `12–16dp`.
    - Height: `>= 48dp` (minimum touch target).
    - Prefill behavior: If `settings.export_email` is configured in local storage, this field must be pre-populated with that value.
- **Period Selector**:
  - Label: "Period" (`16pt` body font).
  - Toggle / Segmented Control: An interactive selector with options: **Daily**, **Weekly**, **Monthly**.
    - Height: `>= 48dp` for touch target.
    - Border radius: `12–16dp` or standard pill shape.
    - Active background color: `Primary` (`#2A8FE0` / `#4FA8E8`).
    - Defaults to the period selection that was active on the History screen prior to entering this screen.
- **Format Selector**:
  - Label: "Format" (`16pt` body font).
  - Toggle / Segmented Control: An interactive selector with options: **Email text** and **CSV file**.
    - Height: `>= 48dp` for touch target.
    - Border radius: `12–16dp`.
    - Active background color: `Primary`.
    - Default selection: **Email text**.
- **Preview Panel**:
  - Label: "Preview" (`16pt` body font).
  - Panel Container:
    - Background: `Panel` color (`#F2F5F8` / `#1B2430`).
    - Border radius: `12–16dp`.
    - Content: Renders the actual formatted plain text or CSV representation of the data.
    - Font: Styled in a monospaced font (e.g., Courier/Roboto Mono) for alignment clarity.
    - Scrolling: The panel content is independently vertically scrollable so that long data listings do not disrupt the overall page layout.
- **Primary CTA Button ("Open share sheet")**:
  - A full-width call-to-action button pinned below the preview panel.
  - Height: `>= 52dp`.
  - Border radius: `12–16dp`.
  - Typography: Accent font style.
  - Background color: `Primary`.
  - Disabled state: Becomes disabled and grayed out if and only if there is no water intake data (0 logs and 0 summaries) in the selected period (an inline warning note should be shown instead of the preview).
- **Privacy Caption**:
  - Small caption centered directly below the CTA button: "Uses your phone's mail / share app. Nothing is sent to any server."
  - Typography: Small, muted font size (under `14pt`).
  - Color: `Muted` (`#7B8794` / `#9AA5B1`).

## State & Data

The screen retrieves its data reactively and builds the export strings in-memory.

### In-Memory Aggregation

1. **Daily Period**:
   - Queries `drink_log` where `day_key = today` and gets today's `daily_summary` data.
2. **Weekly Period**:
   - Queries `daily_summary` and `drink_log` for the current calendar week (Monday to Sunday).
3. **Monthly Period**:
   - Queries `daily_summary` and `drink_log` for the current calendar month (1st day to last day).

*Note: In all cases, unit conversions must be applied dynamically to the raw ML values if the user's settings demand fluid ounces (fl oz) (1 ml = 0.033814 fl oz).*

### Output Templates

#### 1. Email Text Template

**Daily Period:**
```text
Subject: Hydrio Daily Summary - [Date (YYYY-MM-DD)]

=== HYDRATION SUMMARY ===
Date: [Date]
Daily Target: [Target] [unit]
Total Consumed: [Total] [unit]
Completion: [Percentage]%
Status: [Success/Missed]

=== INDIVIDUAL LOGS ===
Time | Amount
[Time (HH:MM)] | [Amount] [unit]

Sent from Hydrio - Stay hydrated, every day.
```

**Weekly / Monthly Period:**
```text
Subject: Hydrio [Period Type] Summary - [Start Date] to [End Date]

=== HYDRATION SUMMARY ===
Period: [Start Date] to [End Date]
Daily Target: [Target] [unit]
Total Consumed: [Total] [unit]
Daily Average: [Average] [unit]
Days Met/Total Days: [Success Days] / [Total Days]

=== DAILY BREAKDOWN ===
Date | Target | Consumed | Progress | Status
[Date] | [Target] [unit] | [Consumed] [unit] | [Percentage]% | [Status]

=== INDIVIDUAL LOGS ===
Date | Time | Amount
[Date] | [Time (HH:MM)] | [Amount] [unit]

Sent from Hydrio - Stay hydrated, every day.
```

#### 2. CSV Template

The CSV template aligns exactly with `ExportHelper.shareCsvExport`:

```csv
=== DAILY SUMMARIES ===
Date,Target ([unit]),Total Intake ([unit]),Completion,Status
[Date],[Target],[Consumed],[Percentage]%,[Status]

=== INDIVIDUAL INTAKE LOGS ===
Date,Time,Amount ([unit])
[Date],[Time (HH:MM:SS)],[Amount]
```

## Interactions & Navigation

- **Live Preview Refresh**:
  - Tapping/changing the **Period Selector** or the **Format Selector** instantly re-generates the preview string and updates the Preview Panel in real time.
- **Email Validation**:
  - If the email field is not empty, basic email format validation (regex matching standard `username@domain.extension`) must run.
  - If validation passes, a direct mail pre-fill behavior is unlocked:
    - Tapping "Open share sheet" attempts to trigger a native mail composer via a `mailto:` URL intent scheme, pre-populating the `to` field with the entered email, setting the appropriate `Subject`, and setting the email text template in the `body`.
  - If the email field is empty or format validation fails:
    - Tapping "Open share sheet" falls back to launching the standard OS share sheet.
    - If format is **CSV file**, it exports the CSV attachment to the share sheet.
    - If format is **Email text**, it exports the plain text block to the share sheet.
- **Successful Share / Settings Update**:
  - Upon initiating the share (or if a mailto intent succeeds), if the user entered a valid email address, the application must persist this email address back to local storage in `settings.export_email`. This updates the provider state to ensure it is pre-filled on the next visit.
- **Clean Back Navigation**:
  - Tapping the back arrow navigates the user back to the previous screen without any state leaks or warnings.

## Design & Aesthetics Compliance

This screen must comply with the design rules specified in [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (CTA / Selectors)** | `#2A8FE0` | `#4FA8E8` |
| **Primary Tint (Inactive state or backgrounds)** | `#D6ECFB` | `#173448` |
| **Success Color (Email validation check / Success status)** | `#34B27B` | `#3FBF86` |
| **Danger Color (Invalid email notice)** | `#C5221F` | `#F08A86` |
| **Text Ink** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Caption / Input placeholder)** | `#7B8794` | `#9AA5B1` |
| **Surface Background** | `#FFFFFF` | `#121821` |
| **Panel (Preview card background)** | `#F2F5F8` | `#1B2430` |

### Typography & Targets

- **Screen Header**: bold scale.
- **Minimum Body & Labels**: `16pt`.
- **Interactive Targets (Buttons / Fields / Selectors)**: Minimum height `>= 48×48dp`.
- **CTA Button**: Height `>= 52dp`, border radius `12–16dp`.

## Edge Cases & Accessibility

- **Zero Logged Days**:
  - If a period has zero logs and zero summaries recorded, the system must not crash. It should still generate a valid, mostly-empty CSV/text block containing header rows/lines but empty datasets.
  - The CTA button must remain clickable to export this empty/placeholder template, unless the provider determines that the dataset is completely absent, in which case it shows an inline notice: *"No hydration records found for this period."* and disables the share action.
- **Very Long Logs**:
  - If there are many drink logs in the selected period (e.g. 50+ logs), the preview panel must enable smooth vertical scrolling with a scroll indicator. Under no circumstances should the outer screen layout overflow or render vertical clipping/red-lines.
- **Mid-Share Backout & File Cleanup**:
  - When exporting a **CSV file**, the app writes the CSV string to a temporary file via `path_provider` (e.g. in the app's cache directory).
  - To prevent storage clutter, any created temporary file must be cleared or scheduled for deletion immediately after the share sheet task returns or when the widget is disposed/unmounted.
- **Screen Rotation & Keyboard Adjustments**:
  - Since the application is strictly locked to portrait mode, no layout adjustments are needed for landscape orientation.
  - However, when the keyboard is focused on the email text input, the layout must resize gracefully (using a `SingleChildScrollView` or dynamic padding) so that the preview panel and CTA buttons do not get obscured or trigger an layout overflow error.

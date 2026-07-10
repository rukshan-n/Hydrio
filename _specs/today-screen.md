# Today Screen Spec

The Today Screen serves as the primary dashboard of the Hydrio application. It provides users with a reactive visual summary of their daily hydration progress, quick access to log standard water amounts, and navigation to other application features.

## Screen Overview

A clean, high-fidelity daily summary screen featuring a large circular progress ring, dynamic motivational messaging, a quick-add chip row, and bottom tab navigation.

```
+-----------------------------------+
|               Today             o |
|                                   |
|             /-------\             |
|            /         \            |
|           |    16%    |           |
|            \         /            |
|             \-------/             |
|           350 / 2,200 mL          |
|                                   |
| Let's get started - 1,850 mL to go|
|                                   |
|  Quick add                        |
|  [ 100 ] [ 200 ] [ 250 ] [ 500 ]  |
|                                   |
|          + Add Water              |
|                                   |
|  [Today]   [History]   [Settings] |
+-----------------------------------+
```

## Widgets & Layout

The screen layout is structured as a vertical column with the following components:

- **App Bar**:
  - Title: "Today" in prominent, bold font aligned to the left.
  - Action Button (Top Right): A settings gear icon navigating to the Settings screen directly (in addition to the bottom tab navigation, as a shortcut).
- **Circular Progress Ring (Center)**:
  - A centered custom progress widget with a dual-color track.
  - **Outer Ring Track**: Indicates the percentage of progress. Uses the `Primary` color (`#2A8FE0` / `#4FA8E8`) for the progress and `Primary Tint` (`#D6ECFB` / `#173448`) or `Panel` (`#F2F5F8` / `#1B2430`) for the background track.
  - **Center Label**:
    - Large percentage text (e.g., "16%") centered in the ring. Uses the Accent typography target (`28–34pt`).
    - Consumed vs. Target fraction text (e.g., "350 / 2,200 mL") positioned below the percentage in standard body font.
- **Remaining-Amount & Motivational Message**:
  - A single encouraging subtitle line below the circular progress ring (e.g. "Let's get started — 1,850 mL to go").
  - The message changes dynamically based on the hydration threshold (detailed in *State & Data*).
  - Uses the `Success` color (`#34B27B` / `#3FBF86`) or `Ink` text color based on the current state.
- **Horizontal Quick-Add Chip Row**:
  - Label: "Quick add" in small, muted font.
  - Layout: A horizontal, scrollable row of selectable chips.
  - Chip Options: Displays fixed presets (e.g., 100 mL, 200 mL, 250 mL, 500 mL) and the user's default `cup_size_ml` configuration.
  - Dynamically formats the volume into ounces (fl oz) if the user's unit settings demand it (e.g., displaying "8.5 fl oz" instead of "250 ml").
- **Primary "+ Add Water" Button**:
  - Pinned or positioned full-width button (with default padding).
  - Height: `>= 52dp`.
  - Border radius: `12–16dp`.
  - Background color: `Primary`.
- **Bottom Tab Bar**:
  - Items:
    - **Today**: Labeled "Today", using a water droplet icon (e.g., `Icons.water_drop`).
    - **History**: Labeled "History", using an insights or calendar history icon (e.g., `Icons.bar_chart` or `Icons.history`).
    - **Settings**: Labeled "Settings", using a settings gear icon (e.g., `Icons.settings`).
  - Active Tab: "Today" (highlighted with active `Primary` color).

## State & Data

The screen is reactive and binds directly to `HydrioProvider` for updates:

- **Reactive Intake Tracking**:
  - Reads `drink_log` rows filtered by `day_key = today` (from `HydrioProvider.todayLogs`).
  - Reads the target and unit from settings (`HydrioProvider.settings`).
  - Derives:
    - **Total Consumed**: Calculated as `sum(amount_ml)` of all logs for today.
    - **Percentage**: Calculated as `(Total Consumed / Target) * 100`.
    - **Remaining Amount**: Calculated as `max(0, Target - Total Consumed)`.
- **Dynamic Motivational Messages**:
  - Under 50%: `"Keep going — X to go"`
  - 50% to 99%: `"Good progress! X to go"`
  - 100% or above: `"Goal reached! 🎉"`
  - *Note: Display volumes (X) must dynamically convert to `fl oz` and format appropriately if settings request it using the provider's helper methods.*
- **Midnight Rollover Logic**:
  - Listens to app lifecycle changes (resume/active) and uses a periodic timer check.
  - If a rollover to a new day occurs:
    - The provider must save/commit the prior day's summary into `daily_summary` (if not already done).
    - Clears the active view, resetting total consumed to `0` and progress to `0%` for the new day's key.

## Interactions & Navigation

- **Tapping a Quick-Add Chip**:
  - Immediately logs a drink of that preset volume via `HydrioProvider.logDrink(amount)`.
  - Triggers a subtle fill animation in the progress ring and updates the message text without showing any confirmation dialogs.
- **Tapping "+ Add Water"**:
  - Navigates the user to the **Add Water screen** (which contains custom volume input and validation).
- **Tapping Bottom Tabs**:
  - Switches navigation tabs to **History** or **Settings** views.

## Design & Aesthetics Compliance

The Today screen must follow the design rules from [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (Ring Progress / CTA)** | `#2A8FE0` | `#4FA8E8` |
| **Primary Tint (Background track)** | `#D6ECFB` | `#173448` |
| **Success Color (Goal met / progress message)** | `#34B27B` | `#3FBF86` |
| **Text Ink** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Labels)** | `#7B8794` | `#9AA5B1` |
| **Surface Background** | `#FFFFFF` | `#121821` |
| **Panel / Chips Background** | `#F2F5F8` | `#1B2430` |

### Typography & Targets
- **Ring Center Value (Percentage)**: `28–34pt`
- **Minimum Body & Labels**: `16pt`
- **Interactive Targets (Chips / Buttons)**: Minimum size `>= 48×48dp`.
- **CTA Button**: Height `>= 52dp`, border radius `12–16dp`.

## Edge Cases & Accessibility

- **Goal Overflow (>100%)**:
  - When consumed water exceeds the daily target, the ring must visually cap at 100% or highlight the overflow state distinctly (e.g. displaying a complete ring with a subtle visual pulse or overlay badge).
  - The motivational text must show celebratory feedback instead of "X to go".
- **Midnight Transition**:
  - If the user leaves the app open overnight and wakes the device, the app must detect the date change, save the previous day's summary, and start a clean slate for the current day.
- **Reduced Motion Accessibility**:
  - Listens to the system accessibility setting `MediaQuery.of(context).disableAnimations` or similar dynamic check.
  - If reduced-motion is requested, the progress ring must immediately jump to the updated percentage, disabling all smooth progress transitions and scale animations.

# Add Water Screen Spec

The Add Water Screen allows users to record water intake. It offers quick-tap presets for standard container sizes and a custom input field for precise logging with built-in validation, debouncing, and local timezone alignment.

## Screen Overview

A clean, focused intake screen featuring a large live amount indicator, a grid of preset logging chips with container icons, a conditional input field for custom volumes, and a primary action button at the bottom.

```
+-----------------------------------+
|  <-  Add Water                    |
|                                   |
|        How much did you drink?    |
|             +-----------+         |
|             |  250 mL   |         |
|             +-----------+         |
|                                   |
|  Choose a size                    |
|  [Cup 100]  [Cup 200]  [Cup 250]  |
|  [Bot 500]  [Bot 750]  [Custom]   |
|                                   |
|  Custom amount (mL)               |
|  [ Enter mL                     ] |
|                                   |
|                Add                |
+-----------------------------------+
```

## Widgets & Layout

The screen layout is structured as a vertical column with the following components:

- **App Bar**:
  - Back Navigation Arrow: Returns the user to the previous screen without saving.
  - Title: "Add Water" in bold title typography.
- **Header Description**:
  - "How much did you drink?" small centered subtitle in muted text.
- **Large Live Amount Display**:
  - A centered, large, read-only display box showing the current selected volume (e.g. "250 mL" or "8.5 fl oz" depending on settings).
  - Uses the Accent/Key typography size (`28–34pt`).
  - Background styled with a clean container (`Panel` or `Primary Tint`) and rounded borders (`12–16dp`).
- **"Choose a size" Grid/Preset Row**:
  - Section Header: "Choose a size" in small, muted font.
  - Layout: A grid or wrap row of selectable chips:
    - **100 mL**: Container icon (e.g. `Icons.local_cafe` or a cup icon) labeled "100 mL" / converted equivalent.
    - **200 mL**: Container icon labeled "200 mL".
    - **250 mL**: Container icon labeled "250 mL". *(Defaults as selected if the user's settings.cupSizeMl is 250)*.
    - **500 mL**: Bottle icon (e.g. `Icons.wine_bar` or custom bottle icon) labeled "500 mL".
    - **750 mL (Bottle)**: Bottle icon labeled "750 mL" or "Bottle".
    - **Custom**: Edit icon (e.g. `Icons.edit` or `Icons.keyboard`) labeled "Custom".
- **Conditional Custom Input Field**:
  - Visible only when the **Custom** chip is selected.
  - Label: "Custom amount (mL)" or "Custom amount (fl oz)".
  - Input field with standard border radius (`12–16dp`).
  - Shows placeholder hint: "Enter mL" (or "Enter fl oz").
  - Inputs restricted to:
    - Numeric keyboard only (`TextInputType.number`).
    - Input formatting allowing only digits (and a single decimal point if unit is fl oz).
- **Primary "Add" Button**:
  - Positioned or pinned full-width button at the bottom of the screen.
  - Height: `>= 52dp`.
  - Border radius: `12–16dp`.
  - Background color: `Primary` color (disabled if custom input is invalid).
  - Visible/active only for Custom logging (since preset taps log immediately).

## State & Data

- **Local Selected Amount State**:
  - Keeps track of the current selected amount in mL (`selectedAmountMl`).
  - Default value matches `settings.cupSizeMl` (from `HydrioProvider`).
- **Database Integration**:
  - On confirmation:
    - Logs a new water entry via `provider.logDrink(amountMl)`.
    - The entry's timestamp must reflect the device's local Unix epoch time.
    - The date group key (`day_key`) must map to today's local date (`YYYY-MM-DD`).
- **Notification & Reminder Rescheduling**:
  - Logging a drink must trigger the notification service's rescheduling pipeline (`NotificationService.instance.scheduleWindowReminders(settings)`), which is handled automatically by the provider's `logDrink` method.

## Interactions & Navigation

- **Tapping a Preset Chip (non-custom)**:
  - Immediately logs that amount to the database.
  - Animates the selection state briefly.
  - Pops the navigation stack to return to the Home dashboard immediately.
- **Tapping the "Custom" Chip**:
  - Reveals the Custom Input Field.
  - Does not log or navigate immediately; keeps the user on-screen to input and confirm.
- **Tapping the "Add" Button (for Custom Input)**:
  - Commits the validated custom entry to the database via the provider.
  - Pops the navigation stack to return to the Home dashboard.

## Validation

- **Custom Input Validation Rules**:
  - Input amount must be a positive integer/number.
  - Valid range (in mL): **1 to 2000 mL** (inclusive). If settings are in fl oz, the range must map to equivalent limits (~0.1 to ~68 fl oz).
  - The "Add" button must be disabled (visually grayed out with touch disabled) if:
    - The input field is empty.
    - The parsed amount is outside the valid range.
    - The input parses to zero or negative.

## Design & Aesthetics Compliance

Matches design guidelines in [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (CTA)** | `#2A8FE0` | `#4FA8E8` |
| **Primary Tint (Live Display Box)** | `#D6ECFB` | `#173448` |
| **Success Color (Active selection)** | `#34B27B` | `#3FBF86` |
| **Text Ink** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Labels/Hints)** | `#7B8794` | `#9AA5B1` |
| **Surface Background** | `#FFFFFF` | `#121821` |
| **Panel / Preset Chips** | `#F2F5F8` | `#1B2430` |

### Typography & Touch Targets
- **Live Display Text**: Accent font size `28–34pt`.
- **Presets & Custom Inputs**: Touch target height `>= 48dp`.
- **CTA Button**: Height `>= 52dp`, border radius `12–16dp`.

## Edge Cases & Accessibility

- **Double-Tap Debouncing**:
  - Tapping a preset chip must be debounced by locking input for `500ms` or ignoring subsequent taps on the same preset chip while navigation transitions are in progress to prevent duplicate database logs.
- **Daily Target Overflow**:
  - Intake amounts that push total consumption over 100% are fully allowed and valid. No prompt or warning dialog should appear; they flow back to Home and render in the overflow visual state.
- **Local Time Accuracy**:
  - Epoch timestamps must be retrieved in milliseconds since epoch representing local device clock times to ensure proper `YYYY-MM-DD` grouping (preventing UTC rollover bugs).

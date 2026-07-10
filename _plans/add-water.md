# Implementation Plan - Add Water Screen

Implement the high-fidelity Add Water screen. This includes managing selected presets, debouncing taps to prevent double logging, implementing a custom input field with unit validation, integrating volume conversions, and writing widget tests to verify all interactions.

## User Review Required

> [!NOTE]
> - Custom amounts will be validated locally on-screen.
> - Presets are logged immediately upon tapping (with a 500ms debounce guard).
> - Values are stored in `ml` in the database, but displayed in either `ml` or `fl oz` based on the user's unit settings.
> - When using ounces (`oz`), custom inputs are parsed as ounces and dynamically converted to mL before database persistence.

## Proposed Changes

### User Interface & Logic

#### [MODIFY] [add_water_screen.dart](file:///Users/rukshanmac/Project/SCIT/Hydrio/lib/ui/screens/add_water_screen.dart)
- Convert `AddWaterScreen` to a `StatefulWidget`.
- **Local State**:
  - `_selectedAmountMl` (int): The current intake amount in mL (defaults to `settings.cupSizeMl`).
  - `_isCustomSelected` (bool): Flag indicating if the "Custom" preset chip is selected.
  - `_textController` (TextEditingController): Controller for the custom input TextField.
  - `_debounceLock` (bool): Mutex flag to prevent duplicate logging during rapid double-tapping on presets.
- **Widgets**:
  - **Large Live Display Box**: Displays the current `_selectedAmountMl` formatted dynamically using `provider.formatVolume(...)`.
  - **Presets Grid**:
    - Build a grid or wrapped row displaying chips for `100 ml`, `200 ml`, `250 ml`, `500 ml`, `750 ml` (Bottle), and `Custom`.
    - Apply active/inactive styles (colors and border weights) depending on which chip is selected.
    - Presets must render formatted strings (e.g. "8.5 fl oz" instead of "250 ml") if settings specify `oz`.
  - **Custom Amount Field (Conditional)**:
    - Displayed only when the `Custom` chip is active.
    - Set keyboard type to `TextInputType.numberWithOptions(decimal: true)`.
    - Validate inputs in real time: must parse to a valid number and lie within the range `[1, 2000] ml` (or its equivalent in `fl oz`).
  - **Primary Add Button**:
    - Enabled only when the `Custom` chip is selected and a valid quantity has been entered.
    - Commits the custom amount via `provider.logDrink(...)` and pops back to the dashboard.

### Validation & Debouncing Detail
- **Debounce Guard**:
  ```dart
  if (_debounceLock) return;
  _debounceLock = true;
  await provider.logDrink(amount);
  if (mounted) Navigator.pop(context);
  ```
- **Custom Numeric Validation Range**:
  - Minimum: `1 ml` (~`0.03 fl oz`)
  - Maximum: `2000 ml` (~`67.6 fl oz`)

---

## Verification Plan

### Automated Tests
- Run tests via `flutter test`.
- Add test coverage in `test/widget_test.dart`:
  - Verify preset taps immediately log to provider and pop the screen back to dashboard.
  - Verify double-tapping presets does not trigger multiple database insertions (testing debounce).
  - Verify the custom input field appears when "Custom" is tapped, and validation limits disable the Add button correctly for zero, negative, empty, or overflow values.
  - Verify unit formatting updates the live amount display and chip labels dynamically.

### Manual Verification
- Open the Add Water screen on a simulator/device.
- Toggle units between mL and fl oz in settings and confirm all chip presets and input placeholders update their labels.
- Verify custom inputs block values above 2000 mL and below 1 mL.

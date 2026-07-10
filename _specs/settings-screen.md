# Settings Screen Spec

The Settings Screen provides users with full configuration control over their hydration targets, reminders, notification options, display formatting, and data options. All user options are persisted locally, ensuring offline-first operation.

## Screen Overview

A clean, high-fidelity settings dashboard featuring a vertical list of tappable preference rows. The layout ends with a visually separated destructive action to wipe history, a pinned privacy notice, and bottom tab navigation.

```
+-----------------------------------+
|              Settings             |
|                                   |
|  Gender                 Female >  |
|  Age                        28 >  |
|  Daily target         2,200 mL >  |
|  Reminder window   07:00-23:00 >  |
|  Cup / bottle size      250 mL >  |
|  Unit (mL/L)                mL >  |
|  Notifications              On >  |
|  Export email      me@mail.com >  |
|                                   |
|      +---------------------+      |
|      | Clear local history |      |
|      +---------------------+      |
|                                   |
|  Privacy                          |
|  Your data stays on your phone.   |
|                                   |
|  [Today]   [History]   [Settings] |
+-----------------------------------+
```

## Widgets & Layout

The screen layout is structured as a scrollable vertical column to prevent layout overflows, with the following components:

- **App Bar**:
  - Title: "Settings" in a large, prominent, bold font aligned to the left.
- **Preference List Rows**:
  - A series of full-width tappable components. Each row contains:
    - **Label**: Left-aligned preference name (e.g. "Gender", "Age") in standard body font.
    - **Current Value**: Right-aligned current setting formatted for display (e.g. "Female", "2,200 mL") in a muted font color.
    - **Chevron**: Right-aligned disclosure chevron (`>`) to indicate interactive pickers.
  - Rows in the vertical list:
    1. **Gender**: Displays the current selected gender (e.g., "Male", "Female", "Other").
    2. **Age**: Displays the current age (e.g., "28").
    3. **Daily target**: Displays the current daily goal volume, formatted dynamically according to the active Unit setting (e.g. "2,200 mL" or "2.2 L").
    4. **Reminder time (range)**: Displays the active wake and sleep window (e.g. "07:00 – 23:00").
    5. **Cup/bottle size**: Displays the default logged drink volume (e.g., "250 mL" or "0.25 L").
    6. **Unit (mL/L)**: Displays the active display unit. Tapping toggles or picker changes the display formatting (mL vs L) without modifying underlying stored values.
    7. **Notifications (on/off)**: Displays the notifications enabled state. Can also be styled as a Switch widget inline, or a tappable row.
    8. **Export email**: Displays the default destination email address for logs (e.g., "user@example.com" or "Not Set").
- **Destructive Action Row (Danger Row)**:
  - A visually separated button or row labeled "Clear local history".
  - Styling: Set in a distinct Panel or low-opacity red background container with **Danger** red text (`#C5221F` / `#F08A86`) to signal risk.
- **Privacy Note**:
  - Caption text: "Your data stays on your phone."
  - Position: Pinned to the bottom of the scrollable column or above the tab bar. Uses smaller, muted typography.
- **Bottom Tab Bar**:
  - Labeled Today, History, Settings.
  - Active Tab: **Settings** (highlighted in active `Primary` color).

## State & Data

All rows directly read from and write to the state management layer (`SettingsProvider` / `HydrioProvider`):

- **Reactive Preferences Sync**:
  - Modifying any value in settings writes directly to the local settings store (backed by SharedPreferences) and updates the local state in the provider.
- **Dynamic Target Calculations**:
  - Changing **Gender** or **Age** recomputes `daily_target_ml` using the standard algorithm, *unless* the user has set a manual override (`settings.manual_override == true`).
  - Changing the **Daily target** directly sets `settings.manual_override = true` and saves the user's manual target value.
- **Unit Display Format Mapping**:
  - The database records intake volumes in **mL** only.
  - Changing the **Unit** preference toggles between `"ml"` and `"l"` display formatting (Liters vs Milliliters).
    - If set to `"ml"`, values are formatted as integers (e.g. `2200 mL`, `250 mL`).
    - If set to `"l"`, values are divided by 1000 and formatted to one or two decimal places (e.g. `2.2 L`, `0.25 L`).
    - The underlying stored settings and database logs remain unchanged in mL.
- **Notifications Scheduling State**:
  - Toggling **Notifications** off cancels all pending scheduled reminders immediately via the notifications engine (`cancelAllReminders`).
  - Toggling **Notifications** back on immediately reschedules reminders starting from the current time up to the end of the 3-day rolling window (`scheduleWindowReminders`).
- **Reminder Time Modifications**:
  - Altering the wake/sleep range immediately updates the scheduling engine's targets and triggers reminder re-spacing without delay.

## Interactions & Navigation

Tapping a row displays an inline picker, modal sheets, or confirmation dialogs:

- **Gender Selection Modal**:
  - Opens a modal sheet containing a segmented control or chip selector: `[ Male ] [ Female ] [ Other ]`. Selecting an option saves it and closes the modal.
- **Age Input Modal**:
  - Opens a modal selector with a scrollable list or a validated text input field.
- **Daily Target Input Modal**:
  - Opens a modal containing a numeric input field. If the user overrides, it stores the custom value and turns on manual override.
- **Reminder Time Range Picker**:
  - Opens a custom time window selector or consecutive dialogs for "Wake Time" and "Sleep Time" using native time pickers.
- **Cup/Bottle Size Modal**:
  - Opens a modal text field or number selector allowing the user to set a positive integer value.
- **Unit Selector**:
  - Toggles between mL and L immediately upon tap, or displays a small action sheet.
- **Export Email Modal**:
  - Opens a text editing dialog prompting the user for an email address.
- **"Clear local history" Dialog**:
  - Tapping this triggers a destructive-themed confirmation dialog showing warning copy ("Are you sure you want to delete all historical logs? This cannot be undone.").
  - Upon user confirmation, it wipes the `drink_log` and `daily_summary` tables in the database, preserving the settings configuration.

## Validation & Constraints

Inputs must respect specific bounds to prevent invalid database states:

- **Age**: Must be an integer between `13` and `100`.
- **Cup/Bottle Size**: Must be a positive integer (greater than zero, typically minimum `50 mL`).
- **Reminder Time Range**:
  - Wake time must be strictly before sleep time (`wakeTime < sleepTime`).
  - Sane window check: Awake duration must be at least `4 hours` and at most `20 hours` to prevent overlaps or constant notifications.
- **Export Email**: Must conform to a valid email format string (e.g., matching a standard regex test `^[^@]+@[^@]+\.[^@]+$`) before saving.
- **Daily Target**: Must have a minimum floor of `500 mL` and a maximum ceiling of `6000 mL` (or equivalents in Liters) to protect against accidental inputs of absurd volumes.

## Design & Aesthetics Compliance

The Settings screen complies with the theme requirements defined in [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (Active Icons/Selected Tabs)** | `#2A8FE0` | `#4FA8E8` |
| **Text Ink (Labels & Values)** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Chevrons / Values / Subtitles)** | `#7B8794` | `#9AA5B1` |
| **Danger Color (Destructive Actions)** | `#C5221F` | `#F08A86` |
| **Surface Background** | `#FFFFFF` | `#121821` |
| **Panel / Row Backgrounds** | `#F2F5F8` | `#1B2430` |

### Touch Targets & Typography

- **Tappable Rows & Touch Targets**: Height `>= 48dp` (preferably `>= 52dp` for primary action elements).
- **Typography Sizing**: Minimum body text `16pt` for preference labels.
- **Row Spacing**: Standard screen padding (`16dp` left/right) and balanced vertical separation.

## Edge Cases & Accessibility

- **Manual Target Override Safeguard**:
  - If a user previously configured a manual target (`settings.manual_override == true`), changing **Gender** or **Age** should **not** silently overwrite the manual value.
  - The application must display a prompt: *"Would you like to reset your daily target to the recommended automatic target based on your updated settings?"*
    - **Reset**: Sets `settings.manual_override = false`, recalculates, and saves.
    - **Keep**: Preserves the existing manual target and keeps `manual_override = true`.
- **Mid-Day History Clearing**:
  - If the user clears history during the day, the screen must immediately trigger state reload.
  - This resets today's total consumed intake to `0` and updates the Today screen's circular progress ring to `0%` instantly, without requiring an application restart.
- **Immediate Notification Rescheduling**:
  - Modifying the reminder interval or sleep/wake times triggers an immediate call to update notification scheduling, preventing the user from receiving notifications scheduled under old time bounds.
- **Reduced Motion Accessibility**:
  - Modals and pickers open instantly without transit or fade animations if system settings prefer reduced motion (`MediaQuery.of(context).disableAnimations`).

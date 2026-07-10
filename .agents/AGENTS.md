# Hydrio - Workspace Customization & Context

This file is automatically loaded by the AI coding agent to maintain project context, code patterns, and constraints.

## Project Structure Overview

The project follows a clean architectural layout:

```
lib/
├── main.dart                      # App entry point, locks orientation, runs initializations
└── core/
    ├── models/
    │   ├── settings_model.dart    # User profile, theme, and notification configs
    │   ├── drink_log_model.dart   # Raw database record for an individual drink event
    │   └── daily_summary_model.dart # Aggregated total intake tracker for individual dates
    ├── database/
    │   └── db_helper.dart         # SQLite databases management (in-memory during testing)
    ├── providers/
    │   └── hydrio_provider.dart   # Main application state and business logic manager
    ├── notifications/
    │   └── notification_service.dart # Local notification windows scheduling (3-day rolling window)
    ├── utils/
    │   └── export_helper.dart     # CSV generation and sharing utilities
    └── theme/
        └── theme.dart             # Project theme and colors configuration
```

---

## Technical Stack & Constraints

- **SDK Targets**: iOS 14+ / Android 8+ (minSdk 23).
- **Orientation**: Locked strictly to portrait.
- **Offline-Only**: Zero cloud sync or authentication. Local persistence only.
- **State Management**: `Provider` wrapper.
- **Persistence**: `sqflite` (relational summaries/logs) and `shared_preferences` (settings config).
- **Testing**: Tests must configure FFI sqflite context to prevent MethodChannel hangs. The database helper (`DbHelper`) automatically boots an in-memory database when standard unit/widget tests are executed.

---

## Data Schema Reference

### `drink_log` Table
- `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
- `amount_ml` (INTEGER NOT NULL)
- `timestamp` (INTEGER NOT NULL)
- `day_key` (TEXT NOT NULL) - format: `YYYY-MM-DD`

### `daily_summary` Table
- `day_key` (TEXT PRIMARY KEY) - format: `YYYY-MM-DD`
- `target_ml` (INTEGER NOT NULL)
- `total_ml` (INTEGER NOT NULL)
- `completion_pct` (REAL NOT NULL)
- `status` (TEXT NOT NULL) - `"success"` or `"missed"`

---

## Design System Reference

### Hex Color Palettes (Light / Dark)
- **Primary**: `#2A8FE0` / `#4FA8E8`
- **Primary Tint**: `#D6ECFB` / `#173448`
- **Success**: `#34B27B` / `#3FBF86`
- **Ink (Text)**: `#1F2933` / `#E8EDF2`
- **Muted**: `#7B8794` / `#9AA5B1`
- **Surface**: `#FFFFFF` / `#121821`
- **Panel**: `#F2F5F8` / `#1B2430`
- **Danger**: `#C5221F` / `#F08A86`

### Typography & Targets
- Minimum body: `16pt`
- Accent / key numbers: `28–34pt` (dynamic scale support)
- Minimum touch target: `48×48dp`
- Primary full-width CTA buttons height: `>=52dp`
- Component border radius: `12–16dp`

---

## Rule of Engagement for Updates

1. **Always Verify FFI in Tests**: Any widget/unit tests must wrap async initializations inside `tester.runAsync(...)` so that sqlite FFI loops can execute.
2. **Encouraging Tone**: All copywriting, SNACKBAR texts, and placeholder updates must use encouraging, positive reinforcements rather than guilt-tripping text.
3. **Unit Formatting**: ML is the core standard for backend storage. Display updates must convert ML values dynamically to fl oz if user settings demand it (1 ml = 0.033814 fl oz).

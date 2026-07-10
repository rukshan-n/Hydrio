# Weekly Threshold Background Color Spec

The Weekly Threshold Background Color feature introduces dynamic visual styling to the Hydrio application. By calculating a user's weekly hydration compliance rate over a rolling 7-day window, the application's background color dynamically adapts. This provides immediate, non-intrusive feedback about their overall hydration health: transition from warning earthy brown tones (low intake) to healthy slate colors (mid range) to vibrant sky blues (fully hydrated).

## Feature Overview

Hydration is a continuous physiological need. Daily tracking is critical, but weekly consistency is the true indicator of long-term health. This feature monitors the user's cumulative water intake over a rolling 7-day window (the last 6 days plus today) against their weekly target. 

The application's theme/scaffold background changes dynamically to reflect their weekly hydration score:
- **Low Hydration (< 50% target met)**: Earthy Brown tones.
- **Moderate Hydration (50% – 79% target met)**: Neutral / Muted slate tones.
- **Optimal Hydration (>= 80% target met)**: Hydrating Blue tones.

All transitions between colors must be styled with smooth micro-animations to enhance premium aesthetics.

---

## Research: Weekly Water Intake Guidelines

Medical and health authorities (such as the National Academy of Medicine and Mayo Clinic) recommend water intake standards based on age, gender, and lifecycle phase. Hydrio utilizes these guidelines to determine the base daily target (if manual target override is disabled).

### Daily and Weekly Baseline Recommendations by Age & Gender

| Age Group | Gender | Recommended Daily Intake | Recommended Weekly Intake (Rolling 7-day) |
| :--- | :--- | :--- | :--- |
| **Toddler (1–3 years)** | All | 950 mL (~32 fl oz) | 6,650 mL (~225 fl oz) |
| **Child (4–8 years)** | All | 1,200 mL (~40 fl oz) | 8,400 mL (~280 fl oz) |
| **Youth (9–13 years)** | All | 1,800 mL (~60 fl oz) | 12,600 mL (~420 fl oz) |
| **Teenager (14–18 years)**| Female | 1,900 mL (~64 fl oz) | 13,300 mL (~448 fl oz) |
| | Male | 2,600 mL (~88 fl oz) | 18,200 mL (~616 fl oz) |
| **Adult (19–55 years)** | Female | 2,000 mL (~68 fl oz) | 14,000 mL (~476 fl oz) |
| | Male | 3,000 mL (~100 fl oz) | 21,000 mL (~700 fl oz) |
| | Other / Default | 2,500 mL (~84 fl oz) | 17,500 mL (~588 fl oz) |
| **Senior Adult (> 55 years)**| Female | 1,900 mL (~64 fl oz) | 13,300 mL (~448 fl oz) |
| | Male | 2,900 mL (~98 fl oz) | 20,300 mL (~686 fl oz) |
| | Other / Default | 2,400 mL (~80 fl oz) | 16,800 mL (~560 fl oz) |

### Dynamic Baseline Calculations
If the user completes onboarding and keeps `manualOverride` disabled:
1. The system reads the user's `age` and `gender`.
2. The daily baseline is set (e.g., 2000 mL for Female, 3000 mL for Male, 2500 mL for Other/Default).
3. The system adds **100 mL** to the daily target if the user is under 30 years old (higher metabolic baseline).
4. The system subtracts **100 mL** from the daily target if the user is over 55 years old (decreased thirst mechanism and lower body mass baseline).
5. The daily target is multiplied by 7 to determine the rolling weekly goal.

---

## State & Data

The dynamic color logic is driven by the weekly hydration score calculated in `HydrioProvider`:

- **Rolling 7-Day Window Definition**:
  - The window includes **today** and the **previous 6 calendar days** (totaling 7 days).
  - Using a rolling window ensures the background does not reset abruptly on a Monday morning, avoiding a jarring user experience.
- **Weekly Intake Calculation**:
  - `Weekly Intake (mL) = Sum of total_ml from all DailySummary entries in the 7-day window + current todayLogs total_ml`.
- **Weekly Target Calculation**:
  - `Weekly Target (mL) = Sum of target_ml from all DailySummary entries in the 7-day window + today's target_ml`.
- **Weekly Hydration Score**:
  - `Weekly Hydration Score (%) = (Weekly Intake / Weekly Target) * 100`.
- **Dynamic Hydration Level State**:
  - `LOW`: Score `< 50%`
  - `MID`: Score `50% <= Score < 80%`
  - `HIGH`: Score `>= 80%`

---

## Widgets & Layout

The dynamic background color changes must propagate seamlessly across all main user-facing screens (Today Screen, History Screen, Settings Screen):

- **Dynamic Theme Wrapper**:
  - The application's core styling is adjusted so that the `Scaffold` background, `AppBar` color, and primary surface panel color scale with the current hydration state.
- **Transitional Animations**:
  - Whenever the dynamic hydration state changes, the background color must transition smoothly using an animated widget (e.g., `AnimatedContainer` or `AnimatedTheme`) with a duration of `600ms` and `Curves.easeInOut`.
- **Visual Color Representation**:
  - **Low Level (< 50%)**: Muted earthy Brown background.
  - **Mid Level (50% – 79%)**: Standard default/neutral background (warm slate or obsidian).
  - **High/Optimal Level (>= 80%)**: Cool Sky/Hydrating Blue background.

---

## Design & Aesthetics Compliance

The dynamic colors are designed to harmonize with both **Light** and **Dark** themes, avoiding harsh saturation and adhering to the project's accessibility requirements:

### Light Theme Dynamic Color Palette

| Dynamic State | Weekly Score | Scaffold Background | Primary Text (Ink) | Muted Text / Labels | Card / Panel Surface |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LOW (Brown)** | `< 50%` | `#D7C9BA` (Muddy Clay) | `#2A1B0E` (Deep Brown) | `#756455` (Muted Bronze) | `#C5B4A4` (Warm Clay) |
| **MID (Neutral)** | `50% – 79%` | `#FFFFFF` (Surface White) | `#1F2933` (Ink) | `#7B8794` (Muted) | `#F2F5F8` (Panel Grey) |
| **HIGH (Blue)** | `>= 80%` | `#D9ECFA` (Sky Blue) | `#0C2B40` (Navy Ink) | `#4F738A` (Muted Blue) | `#C1DFFA` (Sky Blue Panel) |

### Dark Theme Dynamic Color Palette

| Dynamic State | Weekly Score | Scaffold Background | Primary Text (Ink) | Muted Text / Labels | Card / Panel Surface |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **LOW (Brown)** | `< 50%` | `#221711` (Deep Muddy Clay) | `#F2E9E1` (Warm Cream) | `#A18E81` (Muted Clay) | `#33231B` (Deep Clay Panel) |
| **MID (Neutral)** | `50% – 79%` | `#121821` (Surface Dark) | `#E8EDF2` (Ink Dark) | `#9AA5B1` (Muted Dark) | `#1B2430` (Panel Dark) |
| **HIGH (Blue)** | `>= 80%` | `#0C1824` (Midnight Sky Blue) | `#E1F0FC` (Ice Blue Text) | `#92B1C9` (Muted Ocean) | `#182E44` (Deep Blue Panel) |

---

## Interactions & Navigation

- **Automatic Recalculation**:
  - The weekly score must recalculate in real-time whenever a user adds or deletes a drink log.
  - The background color must update immediately (with transition animation) on the active screen.
- **Onboarding and Settings Updates**:
  - When a user changes their `age`, `gender`, or `dailyTargetMl` in the Settings screen, the new targets apply immediately to today and recalculate the rolling weekly target.
  - The background color must adapt instantly to prevent visual mismatch.

---

## Edge Cases & Accessibility

- **New App Install (Insufficient History)**:
  - If a user has been tracking for fewer than 7 days (e.g. just installed yesterday), the weekly calculation must only average the days that actually have history.
  - Future dates or unrecorded past days must not count as `0` in a way that artificially penalizes the user.
  - *Formula Adjustment*: The calculation divides the total intake by the sum of targets of the **available tracked days** (minimum 1 day).
- **Reduced Motion Support**:
  - If the system has reduced motion enabled (`MediaQuery.of(context).disableAnimations` is `true`), the transition between background states must be instantaneous, disabling the `600ms` fade duration to prevent physical discomfort.
- **Onboarding Guard**:
  - The dynamic background color system must NOT apply to onboarding/setup screens (Welcome Screen and Setup Screen).
  - During onboarding, the app background must remain locked to the standard neutral background theme (WeeklyHydrationLevel.mid) to ensure a clean, distraction-free first-time user experience.
  - The dynamic color system is enabled only after `onboardingComplete` is set to `true`.
- **Color Contrast Ratios**:
  - Contrast between background states (Brown, Slate, Blue) and overlay text must adhere strictly to WCAG AA guidelines (minimum contrast ratio of `4.5:1` for body text, `3:1` for large text).

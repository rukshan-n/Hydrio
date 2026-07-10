# Welcome Screen Spec

The Welcome Screen serves as the entry point of the Hydrio application for first-time users. It introduces the application, highlights key value propositions (privacy, offline, simplicity), and initiates the onboarding process.

## Screen Overview

A clean, distraction-free introductory screen with centered branding and a clear call-to-action (CTA) to guide the user into onboarding.

## Widgets & Layout

The layout is structured as a centered vertical column with the following components:

- **App Logo / Icon**: A centered, styled water droplet inside a light circle.
- **"Hydrio" Wordmark**: The app title displayed in a large, prominent, bold font.
- **Tagline**: "Stay hydrated, every day."
- **Secondary Line**: "Private · Offline · Simple"
- **Primary CTA Button**: "Get Started"
  - Full-width layout.
  - Pinned near the bottom of the screen.
  - Height must be at least `52dp`.
  - Border radius `12–16dp`.
- **Privacy Caption**: "Your data stays on your phone."
  - Positioned directly underneath the "Get Started" button in a smaller font size.

## State & Data

- **Stateless Screen**: The screen itself does not read, write, or manage any persistent application state directly.
- **Onboarding Check (Guard Logic)**:
  - On app start, before displaying this screen, the app must check if `settings.onboarding_complete` exists and is `true` in local storage (`shared_preferences`).
  - If `settings.onboarding_complete` is `true`, the app must skip the Welcome screen and navigate directly to the **Home** dashboard.
  - If the key is missing or `false`, the Welcome screen is displayed.

## Interactions & Navigation

- **"Get Started" Button Tap**:
  - Navigates the user to **Setup Screen (Step 1 of 5)**.
- **Navigation Constraints**:
  - No back navigation is required or allowed from this screen, as it is the first screen in the application lifecycle.

## Design & Aesthetics Compliance

To ensure high-fidelity UI implementation, the Welcome Screen must adhere to the design specifications defined in [AGENTS.md](file:///Users/rukshanmac/Project/SCIT/Hydrio/.agents/AGENTS.md):

### Color Palette

| Element | Light Theme | Dark Theme |
| :--- | :--- | :--- |
| **Primary Color (CTA)** | `#2A8FE0` | `#4FA8E8` |
| **Primary Tint (Droplet Circle Background)** | `#D6ECFB` | `#173448` |
| **Text Ink** | `#1F2933` | `#E8EDF2` |
| **Muted Text (Caption)** | `#7B8794` | `#9AA5B1` |
| **Surface Background** | `#FFFFFF` | `#121821` |

### Typography & Touch Targets

- **Minimum Body Font Size**: `16pt`
- **CTA Button Touch Target**: Height `>= 52dp`, width full-width (with standard screen padding).
- **Droplet/Branding spacing**: Centered vertically with balanced top/bottom margins.

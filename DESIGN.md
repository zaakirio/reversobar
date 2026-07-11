# Design

Transit-signage identity ("wayfinding between languages"), shared across the app icon, the macOS popover, and the marketing site in `site/`.

## Color

| Token | Value | Role |
|---|---|---|
| `--field` / `Theme.Brand.panel` | `oklch(0.46 0.2 264)` ≈ `rgb(0.115, 0.30, 0.85)` | Signal blue. Drenched site background; solid panels (primary card, toast, language pills) in the app. |
| `--field-deep` | `oklch(0.38 0.17 264)` | Darker blue: ticker band, phonetic demo panel. |
| `--field-line` | `oklch(0.56 0.19 264)` | Lighter blue: WebGL dot matrix, outlines on deep blue. |
| `--ink` | `oklch(0.2 0.04 264)` | Near-black blue: closing section, footer, board rules, text on white. |
| `--panel` | `#ffffff` | White sign panels (board section). |
| `--signal` / `Theme.Brand.safety` | `oklch(0.84 0.16 88)` ≈ `rgb(0.97, 0.78, 0.20)` | Safety yellow: download CTA, swap control, bookmark stars, arrow accents. Never large surfaces. |

App tint (`Theme.Brand.signal`) is dynamic: the signal blue in light mode, brightened to `rgb(0.32, 0.48, 0.98)` in dark mode.

## Typography

Site: Golos Text Variable (self-hosted via @fontsource-variable, has native Cyrillic), single family.
Weights: 900 uppercase display headings (letter-spacing ≥ -0.03em), 800 row titles and buttons, 500 body.
App: system SF, per macOS convention; bold for the primary translation.

## Grammar

Arrows are the brand gesture: route pills (`EN → RU`), swap `⇄`, download `↓`, ticker separators.
Sign-panel structure: flat color fields, 2-3px ink rules, hairline row dividers, chunky radii (9-16px).
No gradients, no glassmorphism, no glows, no gradient text.

## Motion

Site: Motion (`motion/react`) springs, `whileInView` reveals (`once: true`), CSS marquee ticker, hand-rolled WebGL LED dot-matrix in the hero (`DotField.tsx`).
Everything honors `prefers-reduced-motion` (static frame / no marquee / no magnetic pull).
App: 150-250ms state transitions only (`Theme.Anim`).

## Components (site)

`DownloadButton` (yellow, magnetic hover, hard shadow), `route-pill`, `board-row` (title | description | tag), `PhoneticDemo` (looping Latin→Cyrillic type-along), `Ticker`, `DotField`.

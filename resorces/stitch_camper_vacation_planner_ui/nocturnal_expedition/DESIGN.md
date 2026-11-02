---
name: Nocturnal Expedition
colors:
  surface: '#0d1511'
  surface-dim: '#0d1511'
  surface-bright: '#333b37'
  surface-container-lowest: '#08100c'
  surface-container-low: '#151d19'
  surface-container: '#19211d'
  surface-container-high: '#242c28'
  surface-container-highest: '#2e3732'
  on-surface: '#dce5de'
  on-surface-variant: '#bec9c0'
  inverse-surface: '#dce5de'
  inverse-on-surface: '#2a322e'
  outline: '#89938b'
  outline-variant: '#3f4942'
  surface-tint: '#85d7a9'
  primary: '#85d7a9'
  on-primary: '#003821'
  primary-container: '#52a378'
  on-primary-container: '#00341e'
  inverse-primary: '#116c46'
  secondary: '#ffb876'
  on-secondary: '#4b2800'
  secondary-container: '#6e3d00'
  on-secondary-container: '#f1a966'
  tertiary: '#9ecedf'
  on-tertiary: '#003542'
  tertiary-container: '#6b9aab'
  on-tertiary-container: '#00313d'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#a1f4c3'
  primary-fixed-dim: '#85d7a9'
  on-primary-fixed: '#002112'
  on-primary-fixed-variant: '#005232'
  secondary-fixed: '#ffdcc0'
  secondary-fixed-dim: '#ffb876'
  on-secondary-fixed: '#2d1600'
  on-secondary-fixed-variant: '#6b3b00'
  tertiary-fixed: '#baeafc'
  tertiary-fixed-dim: '#9ecedf'
  on-tertiary-fixed: '#001f28'
  on-tertiary-fixed-variant: '#1a4d5b'
  background: '#0d1511'
  on-background: '#dce5de'
  surface-variant: '#2e3732'
typography:
  display-lg:
    fontFamily: Epilogue
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Epilogue
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Epilogue
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-lg-mobile:
    fontFamily: Epilogue
    fontSize: 26px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Epilogue
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Epilogue
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.01em
  body-md:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.01em
  body-sm:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.03em
  label-md:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 10px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  gutter-desktop: 2rem
  margin: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system captures the quiet thrill of nightfall in backcountry terrain. Inspired by the European *bande dessinée* tradition—clear architectural drafting, expressive organic contours, and evocative atmospheric color—the interface bridges tactile field-notebook romanticism with high-performance digital utility. 

The aesthetic is grounded, nocturnal, and tactile. It replaces sterile neo-grotesque interfaces with an exploratory, story-driven dark mode: charcoal slate bedrock, twilight evergreen surfaces, illuminated by lantern embers and luminescent field-guide greens.

Key visual principles:
- **Atmospheric Depth:** Visual layers behave like natural topographies under moonlight rather than standard elevation shadows.
- **Editorial Utility:** Precise typographic hierarchies paired with distinct cartographic clarity.
- **Comfortable Low-Light Legibility:** High compliance with WCAG AAA contrast without harsh pure-white glares that cause night blindness during outdoor use.

## Colors

The palette establishes an immersive alpine night environment using dense, mineral-rich undertones. Pure blacks and pure whites are deliberately avoided to maintain natural night adaptation.

### Palette Architecture
- **Primary (`#52a378` - Fresh Sage Emerald):** Applied to active navigation trails, primary action controls, path completion indicators, and key operational confirmations.
- **Secondary (`#e6a05e` - Lantern Amber):** Evokes campfire glow and navigational beacons. Reserved for waypoints, highlights, bookmarks, critical warnings, and situational callouts.
- **Tertiary (`#82b1c2` - Glacial Slate):** Cool atmospheric mid-tone for auxiliary metadata, topological water features, and passive progress bars.
- **Base Surfaces:**
  - `surface-dim`: `#0d1210` (Recessed bedrock, canvas bottom)
  - `surface`: `#121815` (Deep forest root, baseline app backdrop)
  - `surface-container-low`: `#18201c` (Primary content tiles, field list items)
  - `surface-container`: `#1f2924` (Elevated interactive cards, floating panels)
  - `surface-container-high`: `#24302a` (Modals, bottom sheets, navigation bars)
  - `surface-container-highest`: `#2d3b34` (Pill toggles, hover/focus rings, active chips)
- **Typography & Iconography:**
  - High Emphasis (`#f0f4f1` - Crisp Alpine Mist): Primary text, headings, actionable vector glyphs (14.2:1 contrast ratio against baseline).
  - Medium Emphasis (`#b0bec5` - Lichen Slate): Secondary descriptions, topographic contours, timestamps, metadata labels.
  - Disabled / Outline (`#455a50` - Weathered Pine): Dividers, inactive border tracks, de-emphasized markers.

## Typography

The typographic pairing channels the print legacy of adventurous European graphic novels and field journals while retaining technical, instrument-grade precision.

- **Headlines (Epilogue):** An expressive, structured geometric sans with sculpted ink-traps and substantial character. Delivers editorial presence to trail titles, waypoint destinations, and vista descriptions.
- **Body & Labels (Space Grotesk):** A calibrated, tech-forward monospace-adjacent grotesque. Its open counters and distinct glyphs guarantee effortless legibility for coordinate reading, elevation stats, distance tracking, and offline journal entries.
- **Micro-Copy Rules:** All coordinates, compass headings, and telemetry data must be set in `label-sm` or `label-md` with uppercase transformation and explicit tracking (`letterSpacing: 0.06em`).

## Layout & Spacing

Layout adheres to an 8pt base spatial unit with 4pt sub-divisions for tight UI chrome, navigation status, and sensor readouts.

- **Mobile Viewports (<600dp):** Single-column fluid canvas with `16px` outer margins. Bottom-anchored control hubs prioritize one-thumb operation during movement.
- **Foldables & Tablets (600dp - 1024dp):** 8-column layout with `24px` gutters and `32px` outer margins. Screen splits horizontally into an interactive topo map canvas (5 columns) and waypoint narrative logs (3 columns).
- **Expanded/Desktop (>1024dp):** 12-column grid anchored to a maximum width of `1360px`, framed by deep `48px` margins. Side panels float over cartography with semi-translucent backdrops.

## Elevation & Depth

To protect dark adaptation and maintain the rich *bande dessinée* tone, pure drop shadows are replaced by a hybrid system of tonal surface steps, warm ambient occlusion, and fine vector borders:

1. **Topographical Surface Shifts:** Elevation is primarily achieved by stepping up through surface tokens: `#121815` (Canvas) → `#1f2924` (Card) → `#24302a` (Floating Panel).
2. **Alpine Mist Stroke:** Floating surfaces feature an ultra-fine `1px` outline tinted with `#f0f4f1` at `7%` opacity (`rgba(240, 244, 241, 0.07)`), separating surfaces without relying on heavy contrast borders.
3. **Campfire Glow (Dynamic Accent Elevation):** Key interactive items (e.g., Active Route FAB, Waypoint Beacon) emit an ambient colored shadow:
   - *Primary FAB:* `0 8px 24px -4px rgba(82, 163, 120, 0.28)`
   - *Active Beacon:* `0 8px 20px -2px rgba(230, 160, 94, 0.35)`

## Shapes

The design system employs moderate corner rounding (`roundedness: 2`), reflecting the smooth weathering of stones and expedition hardware:

- **Standard Containers & Cards (`rounded` - 8px):** Applied to content lists, waypoint overviews, search fields, and metric dashboards.
- **Large Sheets & Hero Modules (`rounded-lg` - 16px):** Bottom sheets, route previews, terrain elevation profiles, and image preview dialogs.
- **Pills (`rounded-full`):** Filter chips, directional tags, quick-action navigation badges, and telemetry pills.

## Components

### Buttons
- **Primary Expedition Action:** Filled with `#52a378`, label in `#121815` (`Space Grotesk Bold`). Minimum touch target 48dp. Subtle lantern amber accent dot for live actions.
- **Secondary Beacon Button:** Surface `#1f2924` with a 1px border of `#e6a05e` at 40% opacity; text set in `#e6a05e`.
- **Ghost/Tertiary:** No fill, text in `#b0bec5`, active press state reveals `#1f2924` fill.

### Cards
- **Trail / Journal Cards:** Base fill `#18201c`, 1px boundary stroke of `rgba(240, 244, 241, 0.06)`. Rounded to `16px`. Header features `Epilogue` headline with status indicator badges in `Lantern Amber` or `Sage Emerald`.

### Chips & Filter Tags
- **Terrain Chips:** Pill-shaped, base fill `#1f2924`. Selected state transitions to `#24302a` with a 1px solid `#52a378` stroke and `#f0f4f1` typography. 

### Input Fields
- **Search & Coordinate Inputs:** Filled with `#18201c`, 1px outline in `#455a50`. On focus, transitions outline to `#52a378` accompanied by a `0 0 0 3px rgba(82, 163, 120, 0.15)` focus ring. Placeholder text set in `#b0bec5` at 60% opacity.

### Selection Controls
- **Checkboxes & Radios:** Unselected outline in `#455a50`. Selected state filled with `#52a378` bearing a `#121815` checkmark icon. Radio selections feature an inner core of `#e6a05e`.

### Lists
- **Waypoint Lists:** Separated by 1px rules in `rgba(69, 90, 80, 0.4)`. Each item hosts an icon badge with a `#1f2924` background and coordinate text set in `Space Grotesk`.

### Specialized Travel Components
- **Telemetry HUD:** Fixed bottom floating bar in `#24302a` with `rounded-full` contour, displaying current bearing, elevation gain, and solar twilight time.
- **Waypoint Marker:** Double-ring pin utilizing an outer halo of `rgba(230, 160, 94, 0.2)` and a solid `#e6a05e` core for immediate map legibility.
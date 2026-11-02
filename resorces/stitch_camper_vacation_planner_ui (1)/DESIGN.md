---
name: Wanderlust Illustrated
colors:
  surface: '#f9f9ff'
  surface-dim: '#cbdbf9'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee9ff'
  surface-container-highest: '#d5e3ff'
  on-surface: '#0b1c32'
  on-surface-variant: '#414943'
  inverse-surface: '#213148'
  inverse-on-surface: '#ebf1ff'
  outline: '#717973'
  outline-variant: '#c0c9c1'
  surface-tint: '#3a674f'
  primary: '#14422d'
  on-primary: '#ffffff'
  primary-container: '#2d5a43'
  on-primary-container: '#9fcfb2'
  inverse-primary: '#a1d1b4'
  secondary: '#a33d23'
  on-secondary: '#ffffff'
  secondary-container: '#ff8162'
  on-secondary-container: '#731a04'
  tertiary: '#5d2e00'
  on-tertiary: '#ffffff'
  tertiary-container: '#7e4205'
  on-tertiary-container: '#ffb57c'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#bceecf'
  primary-fixed-dim: '#a1d1b4'
  on-primary-fixed: '#002112'
  on-primary-fixed-variant: '#224f39'
  secondary-fixed: '#ffdad2'
  secondary-fixed-dim: '#ffb4a2'
  on-secondary-fixed: '#3c0700'
  on-secondary-fixed-variant: '#83260e'
  tertiary-fixed: '#ffdcc4'
  tertiary-fixed-dim: '#ffb780'
  on-tertiary-fixed: '#2f1400'
  on-tertiary-fixed-variant: '#6f3800'
  background: '#f9f9ff'
  on-background: '#0b1c32'
  surface-variant: '#d5e3ff'
typography:
  display-lg:
    fontFamily: Epilogue
    fontSize: 40px
    fontWeight: '800'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Epilogue
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 38px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Epilogue
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Epilogue
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Epilogue
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.04em
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

This design system expresses the romantic, liberated spirit of road-tripping and campervan adventures. It blends modern, disciplined mobile interface architecture with a warm, editorial comic-strip vitality. The target audience encompasses free-spirited road travelers, weekend campers, and adventure planners who value intuitive utility alongside warm storytelling.

The aesthetic marries **Tactile Graphic Illustration** with **Contemporary Minimal Structure**:
- **Tactile Organic Foundations**: Interfaces rely on warm, sun-baked paper tones rather than stark clinical whites, offering a field-notebook ambiance.
- **Graphic Accentuation**: Subtle 1.5px ink outlines, stamp-styled badges, and offset tonal blocks provide a curated graphic-novel aesthetic without devolving into cluttered kitsch.
- **Optimistic Clarity**: High legibility, generous touch targets, and balanced typographic hierarchy ensure the experience remains functional while navigating winding coastal highways or bustling campsites.

## Colors

The palette is rooted in earth, coastal scrub, and dusk campfires:

- **Primary (`#2D5A43` Deep Forest Sage)**: Anchors structural actions, active tab bars, primary button states, and navigational weight. An interactive tint (`#3E7B5C`) serves hover and focused states.
- **Secondary (`#E76F51` Poppy Coral)**: The spark of wanderlust. Reserved for high-value calls-to-action, active trip routes, alert notifications, and joyful graphic accents.
- **Tertiary (`#F4A261` Golden Sunset)**: Warms the palette through status tags, weather highlights, campfire indicators, and celebratory micro-interactions.
- **Neutral Core (`#1D2D44` Deep Slate Navy)**: Replaces harsh carbon blacks for text, iconic ink lines, and borders, establishing contrast that feels print-like and organic.
- **Surface Canvas (`#FDFBF7` Warm Sand)**: The foundation layer across all screens, paired with **Surface Container (`#F4EFE6` Oat Paper)** to layer interactive cards, bottom sheets, and input fields.

## Typography

The typographic pairing balances punchy character with smooth, utilitarian legibility:

- **Headlines (`Epilogue`)**: Offers bold geometric proportions with quirky ink traps and editorial weight. It evokes hand-lettered comic book headings and retro travel posters without sacrificing digital polish. Tight tracking (`-0.01em` to `-0.02em`) creates confident, grounded lockups.
- **Body & Labels (`Plus Jakarta Sans`)**: Delivers friendly, open counters and humanist terminal curves. At body and caption sizes, it guarantees rapid legibility when scanning packing checklists, campsite amenities, or GPS coordinates in direct sunlight.

## Layout & Spacing

The layout employs a rhythmic fluid grid structured for mobile-first handheld usage:

- **Mobile Rhythm (320px – 599px)**: 4-column layout with 16px (`1rem`) gutters and outer canvas margins. Components sit within thumb-friendly interactive zones, with horizontal carousel rails extending flush to edge margins.
- **Tablet Reflow (600px – 1023px)**: 8-column layout with 24px (`1.5rem`) gutters and margins. Splits daily itineraries and map views into master-detail split cards.
- **Desktop/Expanded (1024px+)**: 12-column layout centered to a max-width of 1200px with 32px (`2rem`) gutters, allowing expansive visual itinerary boards and route builders.
- **Spacing Units**: Strictly rooted in an 8pt base grid (`0.25rem` intervals) to align badge heights, card padding, and button proportions cleanly with text leading.

## Elevation & Depth

Visual hierarchy rejects hyper-diffused, synthetic blurs in favor of **Crisp Comic-Tonal Layering**:

- **Physical Ink Borders**: Cards, chips, and overlays utilize a crisp `1.5px solid #1D2D44` structural line (applied at 15% opacity for passive containers, and 100% opacity for interactive focal items).
- **Hard-Drop Offset Shadows**: High-emphasis elements (primary action triggers, active day markers, current destination cards) use hard-edged, zero-blur drop shadows (`2px 2px 0px #1D2D44` or `3px 3px 0px #1D2D44`). This mirrors silk-screened registration and comic ink panels.
- **Surface Elevation**: 
  - *Level 0 (Backdrop)*: `#FDFBF7` (Canvas).
  - *Level 1 (Cards, Lists)*: `#FFFFFF` or `#F4EFE6` with low-opacity ink borders.
  - *Level 2 (Modals, Floating Action Buttons)*: `#FFFFFF` paired with an offset hard shadow and full `1.5px` ink perimeter.

## Shapes

The design system uses deliberate, rounded organic containers (`roundedness: 2` = 0.5rem base) to maintain a soft, friendly silhouette:

- **Buttons & Chips**: Formed with full pill geometries (`rounded-full`) or `rounded-lg` (1rem) for an approachable, tactile field-tool feel.
- **Cards & Sheet Surfaces**: Standardized to `rounded-lg` (1rem) on interior surfaces, while parent bottom-sheet trays and modal drawers use `rounded-xl` (1.5rem) on top corners.
- **Stamp & Badge Trim**: Interactive pin points and trail tags use small, playful scallops or rounded geometric tags framed in dark slate ink.

## Components

### Buttons
- **Primary Action**: Pill-shaped container filled with `#E76F51` (Poppy Coral), typed in `label-lg` with white text, framed in a `1.5px` solid `#1D2D44` border with a `2px 2px 0px #1D2D44` offset shadow. Active tap state translates `1px 1px` with shadow collapse.
- **Secondary Action**: Filled with `#F4EFE6`, `#1D2D44` text, and a `1.5px` border. Used for secondary trail options, filter adjustments, and cancellations.
- **Ghost/Tertiary**: Text-only using `Epilogue` headline weight in `#2D5A43` with an inline organic underline.

### Chips & Filter Pills
- Compact, pill-shaped tags used for filtering camping amenities (e.g., "Fire Pit", "Water Hookup", "Pet Friendly").
- Inactive state: `#F4EFE6` background, `1px` subtle outline in `#1D2D44` (20% alpha), `label-md` slate text.
- Active state: `#2D5A43` filled background, crisp `#1D2D44` outline, white text, prefixed by an illustrated mini-glyph.

### Cards (Van & Campsite Stays)
- Composed on pure white or `#F4EFE6` containers with `1rem` corner rounding, a `1.5px` outer ink contour, and interior padding of `1rem` (`space-md`).
- Image headers feature a subtle inner organic border radius (`0.75rem`) with a top-right stamp badge denoting camp ratings or nightly rates.
- Footer sections provide quick spec pills (van height clearance, drive times) arranged using `space-xs` gaps.

### Lists & Timeline Itineraries
- Waypoints link via an illustrated dashed spine (`2px dashed #3E7B5C`).
- Stops utilize circular badge milestones (`#F4A261` fill, hard-edged shadow) displaying the sequence number in `label-md`.
- Items feature clean dividing spaces without grey horizontal dividers, maintaining paper-like visual continuity.

### Form Inputs & Text Fields
- Inset canvas fields utilizing `#FFFFFF` surface fills against the `#FDFBF7` canvas.
- Resting border: `1.5px solid rgba(29, 45, 68, 0.2)`. Focus border: `2px solid #2D5A43` with a subtle `#2D5A43` ring glow.
- Labels stay top-aligned in `label-md` (`#1D2D44`) paired with friendly, contextual placeholder prompts.

### Checkboxes & Radios
- Checkboxes: `20x20px` squares with `6px` rounded corners, `2px` slate contour. Checked state fills with `#2D5A43` displaying a crisp off-white hand-drawn style check icon.
- Radios: `20x20px` dual-ring circular selectors, filling with a `#E76F51` center dot when active.

### Application-Specific: Route Weather & Elevation Badges
- Compact horizontal banners styled like national park trail signs, finished in `#3E7B5C` or `#F4A261`, carrying vector line icons representing summit heights, wind levels, and sunset hours.
# Docs Navigation Redesign

## Goal

Turn `/docs/` into a polished knowledge-base hub that helps visitors choose a
route before they encounter the complete topic tree. Preserve every existing
article URL, Markdown source path, and weekly synchronization destination.

## Current Problems

- The root page and left sidebar repeat the same seven equal-weight categories.
- Visitors see technical domains before they understand which route fits their
  goal.
- Category depth varies significantly: some topics contain direct articles,
  while environment, robotics, and simulation contain several nested levels.
- The current card grid communicates only titles and one-line descriptions; it
  does not expose the next level of the hierarchy.
- On mobile, a long sequence of visually identical cards pushes useful reading
  paths and recent content below the fold.
- Chinese and English landing pages do not currently expose the same top-level
  topic set.

## Chosen Information Architecture

The hub uses two complementary layers.

### Layer 1: Intent Routes

Three prominent route cards answer what the visitor wants to do:

1. **Quick Start** — workstation setup, WSL, Conda, Git, and fundamentals.
2. **Solve a Problem** — Docker, RealSense, Jetson, YOLO, and debugging notes.
3. **Study a Topic** — AI, computer vision, robotics, reinforcement learning,
   simulation, and Locomotion practice.

Each route includes three representative destinations. These are curated entry
points, not new content sections, so they do not change URLs or duplicate pages.

### Layer 2: Domain Map

The domain map retains the seven existing technical areas:

- AI and large models;
- environment and deployment;
- robotics and device debugging;
- computer vision;
- fundamentals;
- reinforcement learning and simulation;
- training and course notes.

Each domain card exposes its main child topics as compact labels, making the
next hierarchy level visible before navigation. Chinese and English pages show
the same seven domains. English cards may state that some linked material is
currently Chinese when no translation exists.

## Root Hub Components

### Knowledge-Base Header

The current plain introduction becomes a compact header with:

- an eyebrow label identifying the technical knowledge base;
- a concise title and purpose statement;
- live counts derived from the current language site;
- a visual search hint that points to the existing Hextra search control.

This is informative only and does not introduce another search implementation.

### Intent Route Grid

A three-column desktop grid becomes a single-column stack on mobile. Route
cards have distinct accent treatments but share spacing, typography, focus
states, and interaction rules.

### Domain Map

The seven domain cards use a two-column desktop grid and one column on narrow
screens. Cards show an icon, title, summary, child-topic labels, and a clear
directional affordance. The visual weight is deliberately lower than the three
intent routes.

### Recommended and Recent

The bottom portion contains:

- curated recommended reading for stable, high-value entry points;
- the four most recently updated docs for the current language, derived from
  Hugo page metadata.

This replaces the current three-item plain list and avoids manually maintaining
recent dates.

## Category Landing Pages

Every top-level category landing page receives one consistent overview
component. It renders:

- immediate child sections first;
- direct articles second;
- child counts where Hugo can determine them;
- an empty-state message only when a language has no available child content.

Deeper pages retain their existing content. This creates a consistent visible
boundary between root hub, technical domain, subsection, and article without
moving files.

## Implementation Boundaries

### `docs-hub` Shortcode

`layouts/shortcodes/docs-hub.html` owns the root hub markup and localized route
metadata. It reads live page counts and recent pages from the current language
site. Both root index files invoke this shortcode, keeping structure aligned.

### `docs-section-overview` Shortcode

`layouts/shortcodes/docs-section-overview.html` lists the immediate children of
a category page. Top-level category index files invoke it after their localized
introductory copy.

### Scoped Styles

`assets/css/custom.css` receives styles under `.docs-hub` and
`.docs-section-overview` namespaces. Existing navbar and home-page animation
styles remain unchanged. The palette follows the site's current green accent,
neutral Hextra surfaces, dark mode, and reduced-motion preferences.

## Responsive and Accessibility Rules

- Route cards: three columns above the desktop breakpoint, one column on mobile.
- Domain cards: two columns on desktop, one column on mobile.
- No horizontal scrolling at 390 CSS pixels.
- Entire cards have visible keyboard focus states.
- Heading order remains semantic and contains one page-level heading.
- Icons are decorative; text carries all meaning.
- Color is not the sole route differentiator.
- Motion is limited to subtle hover transitions and disabled when
  `prefers-reduced-motion` is set.

## URL and Content Safety

- No article or section directory is moved or renamed.
- The Markdown sync manifest and its four managed destinations remain unchanged.
- Existing inbound links continue to resolve without aliases or redirects.
- Missing optional localized destinations are omitted or labeled; the shortcode
  never generates a guessed URL.
- The change does not fork or edit the vendored Hextra theme.

## Verification

1. Run the existing Pester suite for Markdown automation.
2. Run the real Markdown dry run and require `Changed=false`.
3. Build with the pinned official Hugo Extended `0.164.0` container.
4. Check generated hub links for missing internal destinations.
5. Inspect desktop and 390-pixel mobile screenshots in light and dark mode.
6. Verify keyboard focus, heading hierarchy, and absence of horizontal overflow.
7. Push `main`, wait for the Pages workflow to succeed, and verify `/docs/` plus
   representative category links return HTTP 200.

## Success Criteria

- A new visitor can choose an intent route without understanding the repository
  directory tree.
- The seven technical domains remain discoverable in one scan.
- The next hierarchy level is visible on both root and category landing pages.
- Desktop and mobile layouts look intentionally designed rather than like a
  default sequence of Hextra cards.
- Existing URLs, weekly Markdown synchronization, and generated articles remain
  unaffected.

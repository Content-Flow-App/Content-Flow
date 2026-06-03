# ContentFlow — Style Guide

A complete reference for every color, type, and spacing token in the ContentFlow
design system. All tokens are defined in `colors_and_type.css`; this document is
the human-readable companion. For brand voice, visual foundations, and
iconography, see `README.md`.

---

## 1. Colors

### 1.1 Base palette

| Token | Hex | RGB | Use |
|---|---|---|---|
| `--cf-orange` | `#FF5733` | `255, 87, 51` | **Brand primary.** Headlines, wordmark, sidebar fill, dividers, active states, primary buttons. |
| `--cf-orange-press` | `#E8431F` | `232, 67, 31` | Darkened orange for **press / active** states on orange buttons & links. |
| `--cf-cream` | `#FFFDF3` | `255, 253, 243` | **App background.** The default canvas; also text/icons on orange. |
| `--cf-ink` | `#000000` | `0, 0, 0` | Primary text, icons, hand-drawn arrows, ghost-button borders. |
| `--cf-white` | `#FFFFFF` | `255, 255, 255` | Form fields, inverse surfaces. |
| `--cf-gray` | `#737373` | `115, 115, 115` | Placeholder text, timestamps, meta / secondary copy. |
| `--cf-gray-line` | `#D9D9D9` | `217, 217, 217` | Hairline dividers between list rows. |

### 1.2 Wave texture tints

The signature wavy-line background is painted faintly over solid surfaces.

| Token | Value | Use |
|---|---|---|
| `--cf-wave-faint` | `rgba(255, 87, 51, 0.05)` | Orange waves on a cream surface (~5-8% opacity). |
| `--cf-wave-soft` | `rgba(255, 253, 243, 0.20)` | Cream waves on an orange surface (~20-30% opacity). |

> Implementation note: in the UI kit the wave is the real artwork
> (`assets/wave-panel.png` / `wave-panel-cream.png`), sized to the viewport with
> `background-attachment: fixed` so the lines run continuously across every panel.

### 1.3 Semantic colors

Use these in components so intent stays clear and re-theming is one place.

| Token | Maps to | Meaning |
|---|---|---|
| `--cf-bg` | `--cf-cream` | Default page background. |
| `--cf-bg-inverse` | `--cf-orange` | Sidebar / inverse panels. |
| `--cf-fg` | `--cf-ink` | Default text. |
| `--cf-fg-on-cream-accent` | `--cf-orange` | Headlines & links on cream. |
| `--cf-fg-inverse` | `--cf-cream` | Text on orange. |
| `--cf-fg-muted` | `--cf-gray` | Placeholders, timestamps. |
| `--cf-accent` | `--cf-orange` | Dividers, active state, links. |
| `--cf-field-bg` | `--cf-white` | Input / field background. |
| `--cf-divider` | `--cf-orange` | Thick accent rule under section headers. |
| `--cf-divider-hair` | `--cf-gray-line` | Thin hairline between rows. |

### 1.4 Rules of use

- **Three-color world.** Orange, cream, black do ~95% of the work. Gray and
  white are supporting only. **Never** introduce blues, purples, or gradients.
- **Orange is load-bearing** — it signals brand, action, and emphasis. Don't
  dilute it across decorative fills.
- **No shadows for color depth.** Color blocking (orange / cream) and the wave
  texture create depth; elevation is conveyed with flat fills, not tints.

---

## 2. Typography

### 2.1 Families

| Token | Stack | Role |
|---|---|---|
| `--cf-font-display` | `"Helvetica Neue", Helvetica, Arial, sans-serif` | Big uppercase display headlines. |
| `--cf-font-ui` | `"Helvetica Neue", Helvetica, Arial, sans-serif` | All structural UI: headers, buttons, labels, rows. |
| `--cf-font-soft` | `"Sen", "Helvetica Neue", Arial, sans-serif` | The `ContentFlow.` wordmark (Bold) + soft body / placeholders (Regular). |

> **Sen** loads from Google Fonts (weights 400 / 700 / 800).
> **Helvetica Neue** is licensed and not web-embeddable, so the system stack is
> used; **Arial** is the metric-near-identical fallback. Swap in a licensed
> Helvetica Neue webfont for production if available.

### 2.2 Global type settings

These apply to nearly all text and are the brand's typographic signature.

| Token | Value | Meaning |
|---|---|---|
| `--cf-tracking` | `-0.04em` | Negative letter-spacing on virtually all type. |
| `--cf-leading-tight` | `0.8` | Crushed line-height for display headlines. |
| `--cf-leading-flat` | `1` | Flat line-height for UI labels / single lines. |
| (body leading) | `1.4` | Line-height for multi-line body / meta copy. |

### 2.3 Display scale — Helvetica Neue Bold, UPPERCASE, `lh 0.8`

| Token | Size | Use |
|---|---|---|
| `--cf-display-hero` | `190px` | Full-page hero headline (Home). |
| `--cf-display-xl` | `120px` | Page section headline. |
| `--cf-display-lg` | `68px` | Large statement. |

> On responsive surfaces these are set with `clamp()` (e.g.
> `clamp(72px, 13vw, 188px)` for the hero). The values above are the design
> ceilings on a ~1440-wide canvas.

### 2.4 UI scale — Helvetica Neue Bold

| Token | Size | Use |
|---|---|---|
| `--cf-text-xl` | `42px` | Wordmark size. |
| `--cf-text-lg` | `39px` | Table headers, buttons, primary actions. |
| `--cf-text-md` | `28px` | Secondary actions ("see more"). |
| `--cf-text-sm` | `24px` | Form labels, list rows. |
| `--cf-text-xs` | `20px` | Placeholder / meta (set in Sen). |

### 2.5 Semantic type classes

Ready-made classes from `colors_and_type.css`:

| Class | Family | Weight | Size | Transform | Tracking | Leading | Color |
|---|---|---|---|---|---|---|---|
| `.cf-wordmark` | Sen | 700 | 42px | — | -0.04em | 1 | orange |
| `.cf-hero` | Helvetica Neue | 700 | 190px | UPPERCASE | -0.04em | 0.8 | orange |
| `.cf-headline` | Helvetica Neue | 700 | 120px | UPPERCASE | -0.04em | 0.8 | orange |
| `.cf-h2` | Helvetica Neue | 700 | 39px | — | -0.04em | 1 | ink |
| `.cf-action` | Helvetica Neue | 700 | 28px | — | -0.04em | 1 | ink |
| `.cf-label` | Helvetica Neue | 700 | 24px | — | -0.04em | 1 | ink |
| `.cf-body` | Sen | 400 | 20px | — | -0.04em | 1.4 | ink |
| `.cf-meta` | Sen | 400 | 20px | — | -0.04em | 1 | gray |

### 2.6 Rules of use

- **Two casing registers:** display/headlines are **ALL CAPS**; UI chrome
  (buttons, labels, links, placeholders) is **all lowercase**. Title Case is
  reserved for a couple of standout CTAs and the wordmark.
- Headlines are **huge, orange, uppercase, with crushed 0.8 leading** —
  intentionally poster-like. Don't soften the tracking or leading.
- The wordmark always ends in a period: **`ContentFlow.`**
- **No emoji.** The ellipsis `...` is the only decorative glyph (placeholders,
  truncated rows).

---

## 3. Spacing, radii & elevation

### 3.1 Corner radii

| Token | Value | Use |
|---|---|---|
| `--cf-radius` | `10px` | Inputs, buttons, panels. |
| `--cf-radius-sm` | `5px` | Checkbox. |
| (full) | `9999px` | Line caps & icons render fully rounded. |

### 3.2 Dividers & rules

Structure comes from **rules, not boxes**.

| Element | Spec |
|---|---|
| Thick accent rule | `4px` solid `--cf-orange`, `border-radius: 2px` — sits under section headers. |
| Hairline | `1px` solid `--cf-gray-line` (`#D9D9D9`) — between list rows. |
| Composer rule | `1px` solid `--cf-ink` under the chat input. |

### 3.3 Elevation

**There is no shadow system.** The design is flat. Depth is created by:

1. Color blocking (orange panels on cream).
2. The wave background texture.
3. Rules and hairlines.

No `box-shadow`, no blur, no glassmorphism, no translucency except the wave tints.

### 3.4 Layout dimensions (from the UI kit)

| Element | Spec |
|---|---|
| Navbar height | `64px`, transparent, padding `0 28px`. |
| Sidebar width | `248px`, orange fill, full height. |
| Sidebar padding | `26px 28px`. |
| Page content padding | `~8-12px 28px 28px` (aligned with navbar). |
| Auth panel | `440px` wide, `border-radius: 18px`, padding `40px 38px`. |
| Form field height | `46-48px`. |
| Checkbox | `26 x 26px`, `5px` cream border. |

### 3.5 Spacing approach

- **H1 aligns with the logo.** Page content uses the same `28px` horizontal
  padding as the navbar so headings sit flush with the wordmark.
- **Generous, poster-like whitespace.** Large gaps between sections (40-64px).
- Use **flex / grid with `gap`** for grouping rather than per-element margins.
- List rows: `~18px` vertical padding, separated by hairlines.

---

## 4. Motion (recommended)

The source is static; these are the house rules for adding interaction.

| State | Behavior |
|---|---|
| Hover (links / actions) | Shift to orange, or darken; `transition: color .14s ease`. |
| Hover (ghost button) | Invert to solid ink fill, cream text. |
| Press (primary button) | Background → `--cf-orange-press`; `transform: translateY(1px)`. |
| Row hover | Subtle `rgba(255,87,51,.05)` background wash. |

Keep motion **quick and minimal (~120-160ms ease)** — the brand is punchy, not
bouncy. No elaborate or looping animation on content.

---

## 5. Quick-start

```html
<link rel="stylesheet" href="colors_and_type.css">

<h1 class="cf-hero">Start creating great content</h1>
<p class="cf-body">Generate engaging Reel scripts with a strong hook.</p>
<button style="background: var(--cf-orange); color: var(--cf-cream);
  border-radius: var(--cf-radius); padding: 14px 30px; border: none;
  font-family: var(--cf-font-ui); font-weight: 700;
  letter-spacing: var(--cf-tracking); font-size: 20px;">log in</button>
```

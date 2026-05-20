# UI/UX Pro Max — Design intelligence

Apply professional-grade UI/UX review to any frontend component, page, or design decision. Covers: visual quality, accessibility, interaction patterns, typography, color, responsive behavior, and anti-patterns to avoid.

**Usage:**
- `/user:ui-ux-promax` — review the current UI/UX changes in the branch
- `/user:ui-ux-promax [component or page]` — audit a specific component or page
- `/user:ui-ux-promax [design description]` — generate a design system for a new UI

---

## Review dimensions

### 1. Accessibility (mandatory)
- Color contrast: minimum 4.5:1 for normal text, 3:1 for large text (WCAG AA)
- Focus rings: visible and not suppressed (`outline: none` without replacement → 🔴)
- Alt text: descriptive on all meaningful images
- Keyboard navigation: all interactive elements reachable and operable without mouse
- ARIA: `aria-label` on icon-only buttons; roles correct
- Touch targets: minimum 44×44pt with 8px+ spacing between targets

### 2. Performance (visual)
- Images: WebP/AVIF format preferred; width/height set to prevent layout shift
- Lazy loading: `loading="lazy"` on below-fold images
- CLS (Cumulative Layout Shift): < 0.1 — reserve space for async content
- No layout recalculation in render loop

### 3. Typography
- Font pairing: max 2 typefaces per page (heading + body)
- Scale: systematic type scale (8pt grid: 12, 14, 16, 20, 24, 32, 40, 48)
- Line height: 1.4–1.6 for body text
- No justified text (causes rivers of whitespace on narrow screens)
- Font loading: `font-display: swap` to prevent invisible text flash

### 4. Color and spacing
- 4pt/8pt grid for all spacing — no random pixel values
- Dark mode: test independently, not as afterthought
- Semantic color tokens: never hard-coded hex in components
- Hover/active states on all interactive elements

### 5. Layout and responsive
- Mobile-first: base styles for small screens, `min-width` media queries upward
- Viewport meta: `<meta name="viewport" content="width=device-width, initial-scale=1">`
- No horizontal scroll on mobile
- Safe areas: account for notches and home indicator on iOS

### 6. Navigation patterns
- Max 5 items in bottom navigation
- Predictable back behavior
- Deep linking support
- Loading states: never leave the user without feedback

### 7. Interaction and animation
- Duration: 150–300ms for micro-interactions; longer = sluggish
- Easing: ease-out for entrances, ease-in for exits
- No hover-only interactions (break on touch devices)
- Loading/disabled feedback: clear visual difference from enabled state

### 8. Forms
- Labels visible (not just placeholder text — placeholder disappears on input)
- Error messages adjacent to the field, not at top of form only
- Inline validation when helpful, not on every keystroke
- Submit feedback: disable button + show spinner during processing

### 9. Icons
- SVG icons, not emoji as structural elements
- Consistent icon library (don't mix sources)
- Icon + text label for unclear icons
- Size consistent with surrounding text or design tokens

---

## Common anti-patterns (always flag)

- `outline: none` without `:focus-visible` replacement → accessibility failure
- `pointer-events: none` on interactive elements without keyboard equivalent
- Fixed/sticky elements covering > 25% of the viewport
- Random spacing values (margin: 13px) instead of grid multiples
- Dark mode only tested via CSS `prefers-color-scheme` without checking actual contrast
- Emoji used as structural icons (non-descriptive for screen readers)
- Forms with no label, only placeholder
- Buttons with vague labels ("Click here", "Submit") instead of action-specific text

---

## Output format

```
## Revisión UI/UX — [componente o rama]

### 🔴 Crítico (accesibilidad o broken interaction)
- **[selector o componente]** — descripción del problema
  - *Impacto:* usuarios afectados (low vision, keyboard-only, mobile)
  - *Fix:* corrección específica con código

### 🟡 Mejoras de calidad visual
- **[selector o componente]** — descripción
  - *Fix:* corrección

### 🔵 Sugerencias de polish
- **[selector o componente]** — oportunidad de mejora

### ✅ Áreas verificadas
- [lista de dimensiones que se revisaron y están limpias]
```

---

## Design system generation mode

When asked to design a new component or page:

1. **Identify** product type (dashboard / marketing / mobile app / admin tool)
2. **Choose** visual style matching product and audience
3. **Define** design system:
   - Color palette (primary, secondary, neutrals, semantic)
   - Typography scale and font pairing
   - Spacing scale (4pt grid)
   - Component states (default, hover, active, disabled, loading, error)
4. **Generate** code implementing the design with correct tokens
5. **Verify** against anti-patterns before delivering

---

*Skill adapted from [UI-UX-Pro-Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) by nextlevelbuilder. The original includes a Python CLI with a searchable database of 50+ styles, 161 color palettes, and 57 font pairings — install for advanced design system generation.*

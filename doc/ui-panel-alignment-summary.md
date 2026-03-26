# UI Panel Alignment Summary

## Overview

This round of work focused on aligning the new overlay control UI to the user-provided panel SVGs, especially the simplified panel outline:

- `apps/web-frontend/src/assets/images/panel_trace_simplified.svg`

The main goal was to make the left and right control wings visually match the SVG-defined circles and outline, while keeping the UI in a fixed-stage, game-style layout.

## Files Updated

- `apps/web-frontend/src/app/shell/AppShell.vue`
- `apps/web-frontend/src/app/shell/CenterConsole.vue`
- `apps/web-frontend/src/app/shell/LeftControlWing.vue`
- `apps/web-frontend/src/app/shell/RightControlWing.vue`

## What Was Completed

### 1. Fixed-stage UI scaling

The shell now uses a fixed design stage and scales uniformly, instead of using normal responsive reflow. This avoids layout drift when the browser size changes.

### 2. Full-height side panels

The left and right wings were changed to span the full stage height, instead of being constrained by the center work area.

### 3. Switched to the simplified SVG

The control wings now use:

- `panel_trace_simplified.svg`

This replaced the previous traced/cropped asset and made alignment more predictable.

### 4. Removed duplicate panel outline rendering

The duplicate lighter/darker overlapping outline was caused by stacked pseudo-elements. The extra layer was removed so each wing now renders as a single clean outline.

### 5. Bottom button alignment

The following buttons were converted to two-button layouts and aligned to the bottom SVG circles:

- Left: `RA-`, `DEC-`
- Right: `RA+`, `DEC+`

These are currently aligned correctly.

### 6. Right-side middle four-button alignment

The right-side vertical four-button column was aligned successfully.

### 7. Right-side top large button alignment

The right-side top large circular button was aligned successfully.

### 8. Left-side alignment fixes

The left side is currently considered correct by the user, including:

- top large button
- middle four circular buttons
- bottom two buttons

## Current Alignment Logic

There are now two positioning modes in use.

### A. Geometry-driven positioning

Some controls are no longer positioned by arbitrary CSS offsets. Instead, their positions are computed from SVG geometry using:

- SVG `viewBox`
- circle `cx`
- circle `cy`
- panel scale relative to SVG height

This logic is implemented in:

- `LeftControlWing.vue`
- `RightControlWing.vue`

This is currently used for:

- top large circular buttons
- left middle four circular buttons
- right middle four circular buttons

### B. Manual positioning

Some elements are still manually positioned with CSS offsets, such as:

- bottom label blocks like `R.A. CONTROL` and `DEC. CONTROL`
- some text labels
- some non-circular supporting UI blocks

If the SVG changes in those areas, these parts may still need manual adjustment.

## Important Note About Future SVG Changes

### Changes that should auto-update

If `panel_trace_simplified.svg` is updated only by moving the circle positions used by the current formulas, the following controls should update automatically:

- left top large button
- right top large button
- left middle four buttons
- right middle four buttons

### Changes that may still require manual updates

If the SVG changes affect any of the following, code adjustments may still be needed:

- bottom label text positions
- bottom control text blocks
- non-circular UI elements
- outer contour-dependent spacing
- any newly added circles not yet wired into formulas

## Recommended Next Step

If we want future SVG changes to propagate more automatically, the next improvement should be:

1. move bottom `RA/DEC` label blocks to geometry-based positioning
2. move more text anchor positions to SVG-derived coordinates
3. centralize panel geometry constants into a shared helper instead of repeating them inside both wing components

## Verification Status

The updated UI was repeatedly checked through:

- local build: `npm run build`
- browser screenshot inspection via Playwright helper

Builds succeeded. Existing warnings remain from the original project, mainly:

- case-sensitive duplicate SVG filenames
- large bundle size warnings

No new blocking build errors were introduced by this alignment work.

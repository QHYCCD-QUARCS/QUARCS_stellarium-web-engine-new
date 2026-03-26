# UI Viewport Frame Integration Summary

## Overview

This round of work focused on two related problems in the new shell UI:

1. the sky viewport was visually extending beyond the intended panel frame
2. mouse drag interactions for the sky map stopped working after the new overlay shell was added

The goal was to keep the legacy Stellarium/camera viewport running, but constrain it to the new shell frame and let pointer interactions reach the sky canvas again.

## Files Updated

- `apps/web-frontend/src/app/AppRoot.vue`
- `apps/web-frontend/src/app/viewport/ViewportHost.vue`
- `apps/web-frontend/src/app/viewport/LegacyAppHost.vue`
- `apps/web-frontend/src/app/shell/AppShell.vue`
- `apps/web-frontend/src/app/shell/CenterConsole.vue`

## What Was Completed

### 1. Moved the legacy viewport into the new fixed-stage shell space

`ViewportHost.vue` now uses the same fixed design stage logic as `AppShell.vue`:

- design size: `1600 x 900`
- uniform scale based on window size

This keeps the legacy viewport and the new shell aligned in the same stage coordinate system.

### 2. Constrained the sky viewport to `viewport-host__frame`

The legacy app is now rendered inside:

- `.viewport-host__stage`
- `.viewport-host__frame`

The frame uses:

- `inset: 26px 18px 18px`
- `border-radius: 44px`
- `overflow: hidden`

Additional clipping was added on:

- `.viewport-host__legacy`
- `.legacy-app-host`
- `.legacy-app-host .v-application`
- `.legacy-app-host .v-application--wrap`
- `.legacy-app-host .v-main__wrap`
- `.legacy-app-host .v-main`
- `.legacy-app-host .container.fill-height`
- `.legacy-app-host #stel`

This ensures the viewport is physically clipped to the intended frame container.

### 3. Fixed the real overflow source: legacy `#app`

The key bug was not the canvas itself.

The actual cause was an old global rule in `src/App.vue`:

- `html, body, #app { position: fixed !important; width: 100%; height: 100%; ... }`

Inside the embedded legacy host, the Vuetify root still uses `id="app"`, so it was being forced to fullscreen/fixed layout even though it had been placed inside the new frame.

Because of that:

- `.viewport-host__frame` was `1564 x 856`
- but legacy `#app`, `#stel`, and the canvases still measured `1600 x 900`

To fix this, `AppRoot.vue` now adds a stronger scoped override:

- `.legacy-app-host #app { position: absolute !important; inset: 0 !important; width: 100% !important; height: 100% !important; overflow: hidden !important; }`

After this change, browser measurement confirmed:

- `.viewport-host__frame`
- `.legacy-app-host #app`
- `#stel`
- `#stel-canvas`
- `#mainCamera-canvas`
- `#guiderCamera-canvas`

all resolve to the same frame size.

### 4. Restored mouse drag on the sky map

The second issue was that the new shell overlay was intercepting pointer events above the viewport.

Two main blockers were identified:

- `.app-shell__stage-frame`
- `.app-shell__center` / `.center-console`

These areas visually sit above the viewport and were still receiving pointer events, so mouse drag did not reach the underlying sky canvas.

The fix was:

- make `.app-shell__stage-frame` non-interactive
- make the center console non-interactive by default
- keep only the real center button interactive

Specifically:

- `AppShell.vue`
  - `.app-shell__stage-frame { pointer-events: none; }`
  - `.app-shell__center { pointer-events: none; }`
- `CenterConsole.vue`
  - `.center-console { pointer-events: none; }`
  - `.center-console__capture-chip { pointer-events: auto; }`

This lets drag/scroll/pan events pass through the center area to the sky canvas again, while preserving clickability for the intended center button.

## Temporary Naming Overlay

During this work, temporary discussion labels were also added to the shell UI so controls can be referred to by short names during design discussion.

Examples:

- `App-Panel`
- `L-Panel`
- `C-Panel`
- `R-Panel`
- `C-Capture`

These labels are:

- very small
- purple
- non-interactive

They are intended only for discussion and can be removed later.

## Main Div Hierarchy

The current UI is effectively made of two parallel trees:

1. the viewport tree that renders the legacy Stellarium/camera content
2. the shell tree that renders the new overlay frame and controls

They are mounted side by side inside `AppRoot`, then visually stacked with `z-index`.

### A. Top-level structure

Main structure:

```text
AppRoot
└─ .app-root
   ├─ ViewportHost (.app-root__viewport, z-index: 0)
   └─ AppShell (.app-root__shell, z-index: 20)
```

Meaning:

- `ViewportHost` is the visual content layer
- `AppShell` is the overlay UI layer

### B. Viewport tree

Main viewport path:

```text
.app-root
└─ .app-root__viewport
   └─ .viewport-host
      └─ .viewport-host__stage
         └─ .viewport-host__frame
            ├─ .viewport-host__legacy
            │  └─ .legacy-app-host
            │     └─ #app / .v-application
            │        └─ .v-application--wrap
            │           └─ .v-main
            │              └─ .v-main__wrap
            │                 └─ .container.fill-height
            │                    └─ #stel
            │                       └─ relative wrapper
            │                          ├─ #stel-canvas
            │                          ├─ #mainCamera-canvas
            │                          └─ #guiderCamera-canvas
            └─ .viewport-host__scrim
```

Responsibilities:

- `.viewport-host`
  - owns full-screen viewport area
- `.viewport-host__stage`
  - applies fixed-stage scaling (`1600 x 900`)
- `.viewport-host__frame`
  - the actual clip container for the visible sky viewport
- `.viewport-host__legacy` / `.legacy-app-host`
  - bridge layer that embeds the old app inside the new shell
- `#app`
  - legacy Vue/Vuetify app root
- `#stel`
  - main legacy sky viewport container
- `#stel-canvas`
  - Stellarium sky canvas
- `#mainCamera-canvas`
  - main camera canvas
- `#guiderCamera-canvas`
  - guider camera canvas
- `.viewport-host__scrim`
  - visual darkening layer above the viewport but below shell controls

### C. Shell tree

Main shell path:

```text
.app-root
└─ .app-root__shell
   └─ .app-shell
      └─ .app-shell__viewport
         └─ .app-shell__stage
            ├─ .app-shell__top
            │  └─ TopBar
            ├─ .app-shell__stage-frame
            ├─ .app-shell__body
            │  ├─ .app-shell__left
            │  │  └─ LeftControlWing
            │  ├─ .app-shell__center
            │  │  └─ CenterConsole
            │  └─ .app-shell__right
            │     └─ RightControlWing
            └─ .app-shell__bottom
               └─ BottomDock
```

Responsibilities:

- `.app-shell`
  - top overlay layer for new UI
- `.app-shell__viewport`
  - centers the shell stage in the window
- `.app-shell__stage`
  - uses the same fixed-stage scaling as `ViewportHost`
- `.app-shell__stage-frame`
  - decorative large frame for the shell, labeled `App-Panel`
- `.app-shell__body`
  - main control band inside the shell
- `.app-shell__left`
  - left control wing, labeled `L-Panel`
- `.app-shell__center`
  - center information layer, labeled `C-Panel`
- `.app-shell__right`
  - right control wing, labeled `R-Panel`
- `.app-shell__bottom`
  - bottom dock / chart area

### D. Visual stacking order

At a high level, the stacking order is:

```text
Top
└─ AppShell controls
   └─ AppShell decorative frame
      └─ Viewport scrim
         └─ Legacy viewport canvases
Bottom
```

In practice:

- `AppShell` sits above `ViewportHost`
- `viewport-host__scrim` sits above the legacy canvases
- `app-shell__stage-frame` is decorative only
- center drag should pass through shell center area to the viewport canvas below

### E. Pointer-event logic

Pointer event behavior is intentionally split by role:

- `AppShell` root:
  - `pointer-events: none`
  - default behavior is pass-through
- interactive shell areas:
  - left wing
  - right wing
  - top bar
  - bottom dock
- non-interactive shell overlays:
  - `.app-shell__stage-frame`
  - `.app-shell__center`
  - `.center-console`
- explicitly interactive center control:
  - `.center-console__capture-chip`

This means:

- the sky viewport should receive mouse drag in the center area
- side controls still receive direct clicks
- decorative frame layers should never block viewport interaction

### F. Why this hierarchy matters

When debugging layout or interaction bugs, the most important distinction is:

- if the problem is geometric, inspect the viewport tree
- if the problem is visual overlay or pointer blocking, inspect the shell tree

Typical examples:

- viewport escaping frame:
  - inspect `#app`, `#stel`, canvas sizes, and `viewport-host__frame`
- mouse drag blocked:
  - inspect shell layers above the center region and their `pointer-events`
- shell/viewport misalignment:
  - inspect whether `ViewportHost` and `AppShell` still use identical stage dimensions and scale logic

## Verification

Verification was done in two ways:

### A. Build verification

- `npm run build`

Build succeeded after the changes.

Existing warnings remained unchanged:

- case-sensitive duplicate SVG asset names
- bundle size warnings

### B. Runtime DOM measurement

Playwright was used to inspect runtime bounding boxes in the browser.

This confirmed the final geometry is aligned:

- `.viewport-host__frame`: `1564 x 856`
- `.legacy-app-host #app`: `1564 x 856`
- `#stel`: `1564 x 856`
- `#stel-canvas`: `1564 x 856`
- `#mainCamera-canvas`: `1564 x 856`
- `#guiderCamera-canvas`: `1564 x 856`

This was the key confirmation that the viewport was no longer escaping the frame.

## Notes For Future Work

### If the viewport appears to overflow again

Check these first:

- `src/App.vue` global `#app` rules
- whether the embedded legacy root still uses `id="app"`
- whether any fullscreen/fixed-position global selector was reintroduced

### If sky drag stops working again

Check whether any shell layer above the viewport has:

- `pointer-events: auto`
- full-area absolute positioning
- transparent backgrounds that still intercept mouse input

The most likely future regression points are:

- `AppShell.vue`
- `CenterConsole.vue`
- new decorative overlay layers added above the viewport

### Recommended next cleanup

If we want this architecture to be easier to maintain, the next cleanup should be:

1. centralize shared stage geometry constants used by both shell and viewport host
2. document which shell layers are decorative-only versus interactive
3. eventually replace the legacy embedded `#app` assumptions with a dedicated embedded viewport root

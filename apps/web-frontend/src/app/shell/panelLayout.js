import { PANEL_VIEWBOX } from './panelGeometry.generated'

export const PANEL_RENDER_HEIGHT = 856

// These Y values come from the lower contour of panel_trace_simplified.svg:
// Q388 751 468 764 ... Q541 764 541 801 ... Q541 897 500 897
// The footer region visually starts around the first lower shoulder at y=751.
export const PANEL_OUTLINE_Y = Object.freeze({
  footerTop: 751,
  footerShoulder: 764,
  footerNeckTop: 801,
  bottomEdge: 897
})

export function svgYToPanelY (svgY) {
  const scale = PANEL_RENDER_HEIGHT / PANEL_VIEWBOX.height
  return (svgY - PANEL_VIEWBOX.y) * scale
}

export const PANEL_FOOTER_HEIGHT = Math.round(
  PANEL_RENDER_HEIGHT - svgYToPanelY(PANEL_OUTLINE_Y.footerTop)
)

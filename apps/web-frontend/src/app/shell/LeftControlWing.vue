<template>
  <aside class="control-wing control-wing--left">
    <div ref="panelInner" class="control-wing__inner" :style="panelStyle">
      <div class="control-wing__aux-border" aria-hidden="true"></div>
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <section class="wing-hero">
        <p class="wing-eyebrow">{{ heroEyebrow }}</p>
        <div class="mode-gear" :style="modeGearStyle" aria-hidden="true">
          <span class="mode-gear__ring"></span>
          <span class="mode-gear__halo"></span>
          <span class="mode-gear__tick"></span>
          <span class="mode-gear__label">{{ currentModeRingLabel }}</span>
        </div>
        <button
          class="hero-orb hero-orb--button"
          :style="heroOrbStyle"
          type="button"
          @click="$emit('hero-action')"
        >
          <div class="hero-orb__inner">
            <span class="hero-orb__accent"></span>
            <span class="hero-orb__mode">{{ activeModeLabel }}</span>
          </div>
        </button>
        <div class="hero-caption">
          <span class="hero-caption__label">Current Mode</span>
          <span class="hero-caption__title">{{ heroTitle }}</span>
        </div>
      </section>

      <section class="wing-menu">
        <button
          v-for="(item, index) in actionItems"
          :key="item.id"
          class="menu-item"
          :style="leftActionButtonStyle(index)"
          type="button"
          @click="$emit('left-action', item.id)"
        >
          <span class="menu-item__orb">
            <v-icon v-if="menuActionIcon(item)" class="menu-item__icon">{{ menuActionIcon(item) }}</v-icon>
            <span v-else class="menu-item__glyph">{{ item.icon }}</span>
          </span>
          <span class="menu-item__text">{{ item.title }}</span>
        </button>
      </section>

      <section class="wing-footer">
        <div class="dual-pad">
          <button
            class="dual-pad__btn"
            :style="footerLeftButtonStyle"
            type="button"
            @mousedown="$emit('footer-press', footerLeft.id)"
            @mouseup="$emit('footer-release', footerLeft.id)"
            @mouseleave="$emit('footer-release', footerLeft.id)"
            @touchstart.stop.prevent="$emit('footer-press', footerLeft.id)"
            @touchend.stop.prevent="$emit('footer-release', footerLeft.id)"
          >
            <span class="dual-pad__cap">
              <v-icon>{{ footerButtonIcon(footerLeft.id, footerLeft.label) }}</v-icon>
            </span>
            <span class="dual-pad__label">{{ footerLeft.label }}</span>
          </button>
          <button
            class="dual-pad__btn"
            :style="footerRightButtonStyle"
            type="button"
            @mousedown="$emit('footer-press', footerRight.id)"
            @mouseup="$emit('footer-release', footerRight.id)"
            @mouseleave="$emit('footer-release', footerRight.id)"
            @touchstart.stop.prevent="$emit('footer-press', footerRight.id)"
            @touchend.stop.prevent="$emit('footer-release', footerRight.id)"
          >
            <span class="dual-pad__cap">
              <v-icon>{{ footerButtonIcon(footerRight.id, footerRight.label) }}</v-icon>
            </span>
            <span class="dual-pad__label">{{ footerRight.label }}</span>
          </button>
          <button
            class="dual-pad__btn dual-pad__btn--func"
            :class="{ 'dual-pad__btn--active': dockerChartParamsOpen }"
            :style="footerFuncButtonStyle"
            type="button"
            data-testid="lcw-btn-toggle-docker-chart-params"
            @click="handleFooterAction"
          >
            <span class="dual-pad__cap dual-pad__cap--small">
              <v-icon>{{ footerButtonIcon(footerAction.id, footerAction.label) }}</v-icon>
            </span>
            <span class="dual-pad__label">{{ footerAction.label }}</span>
          </button>
        </div>
      </section>
    </div>
  </aside>
</template>

<script>
import { PANEL_ANCHORS, PANEL_VIEWBOX } from './panelGeometry.generated'
import { PANEL_FOOTER_HEIGHT, PANEL_RENDER_HEIGHT } from './panelLayout'

const VIEWBOX = PANEL_VIEWBOX
const HERO_CIRCLE = PANEL_ANCHORS.heroOrb
const ACTION_CIRCLES = [
  PANEL_ANCHORS.actionSlot1,
  PANEL_ANCHORS.actionSlot2,
  PANEL_ANCHORS.actionSlot3
]
const FOOTER_LEFT_CIRCLE = PANEL_ANCHORS.leftFooterRaMinus
const FOOTER_RIGHT_CIRCLE = PANEL_ANCHORS.leftFooterDecMinus
const FOOTER_FUNC_CIRCLE = PANEL_ANCHORS.leftFooterFunc
const PANEL_HEIGHT = PANEL_RENDER_HEIGHT
const MENU_BUTTON_WIDTH = 92
const MENU_BUTTON_HEIGHT = 108
const FOOTER_BTN_WRAP_WIDTH = 88
const FOOTER_BTN_CIRCLE_SIZE = 76
const FOOTER_ZONE_TOP = PANEL_HEIGHT - PANEL_FOOTER_HEIGHT
const HERO_ORB_SIZE = 148
const PANEL_CLIP_PATH = 'path("M 84.66 15.29 H 238.68 Q 264.18 15.29 281.52 51.97 Q 313.14 124.32 315.18 193.62 Q 310.08 246.61 277.44 292.47 Q 237.66 345.46 229.50 356.67 V 523.79 Q 234.60 580.86 275.40 625.70 Q 334.56 683.78 416.16 697.03 H 452.88 Q 490.62 697.03 490.62 734.73 V 790.78 Q 490.62 832.56 448.80 832.56 H 84.66 Q 20.40 832.56 20.40 770.40 V 615.50 Q 20.40 597.16 35.70 589.01 V 274.12 Q 35.70 259.86 20.40 248.65 V 79.49 Q 20.40 38.72 48.96 23.44 Q 65.28 15.29 84.66 15.29 Z")'
const BLUR_SOURCE_IDS = ['guiderCamera-canvas', 'mainCamera-canvas', 'stel-canvas']

export default {
  name: 'LeftControlWing',
  props: {
    activeMode: {
      type: String,
      default: 'mount'
    },
    heroTitle: {
      type: String,
      default: 'Mount'
    },
    heroEyebrow: {
      type: String,
      default: 'Mode'
    },
    primaryModes: {
      type: Array,
      default: () => []
    },
    actionItems: {
      type: Array,
      default: () => []
    },
    footerLeft: {
      type: Object,
      default: () => ({ id: 'mount-ra-minus', label: 'RA-', tag: 'L-RA-' })
    },
    footerRight: {
      type: Object,
      default: () => ({ id: 'mount-dec-minus', label: 'DEC-', tag: 'L-DEC-' })
    },
    footerAction: {
      type: Object,
      default: () => ({ id: 'dock-toggle', label: 'D-Chart', tag: 'L-Docker' })
    },
    dockExpanded: {
      type: Boolean,
      default: false
    }
  },
  data () {
    return {
      panelShapeUrl: require('@/assets/images/panel_fill_mask.svg'),
      blurTimer: null,
      dockerChartParamsOpen: false
    }
  },
  watch: {
    dockExpanded: {
      immediate: true,
      handler (value) {
        this.dockerChartParamsOpen = !!value
      }
    }
  },
  mounted () {
    this.refreshBlurCanvas()
    this.blurTimer = window.setInterval(this.refreshBlurCanvas, 120)
    window.addEventListener('resize', this.refreshBlurCanvas, { passive: true })
  },
  beforeDestroy () {
    if (this.blurTimer) window.clearInterval(this.blurTimer)
    window.removeEventListener('resize', this.refreshBlurCanvas)
  },
  computed: {
    panelStyle () {
      return {
        '--panel-shape-url': `url(${this.panelShapeUrl})`,
        '--panel-clip-path': PANEL_CLIP_PATH,
        '--panel-texture-image': 'none'
      }
    },
    geometryScale () {
      return PANEL_HEIGHT / VIEWBOX.height
    },
    heroOrbStyle () {
      const scale = this.geometryScale
      const x = (HERO_CIRCLE.cx - VIEWBOX.x) * scale
      const y = (HERO_CIRCLE.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - 74)}px`,
        top: `${Math.round(y - 74)}px`
      }
    },
    modeGearStyle () {
      const scale = this.geometryScale
      const x = (HERO_CIRCLE.cx - VIEWBOX.x) * scale
      const y = (HERO_CIRCLE.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - 92)}px`,
        top: `${Math.round(y - 92)}px`
      }
    },
    activeModeLabel () {
      const active = this.primaryModes.find((item) => item.id === this.activeMode)
      return active ? active.label : 'EQ'
    },
    currentModeRingLabel () {
      const active = this.primaryModes.find((item) => item.id === this.activeMode)
      return active ? this.modeDisplayName(active.id).toUpperCase() : 'MOUNT'
    },
    footerLeftButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_LEFT_CIRCLE)
    },
    footerRightButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_RIGHT_CIRCLE)
    },
    footerFuncButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_FUNC_CIRCLE)
    }
  },
  methods: {
    handleFooterAction () {
      this.dockerChartParamsOpen = !this.dockerChartParamsOpen
      this.$emit('footer-action', this.footerAction.id)
    },
    findActiveViewportCanvas () {
      let best = null
      let bestZ = -Infinity
      for (const id of BLUR_SOURCE_IDS) {
        const candidate = document.getElementById(id)
        if (!candidate) continue
        const style = window.getComputedStyle(candidate)
        if (style.display === 'none' || style.visibility === 'hidden' || Number(style.opacity) === 0) continue
        const rect = candidate.getBoundingClientRect()
        if (rect.width <= 0 || rect.height <= 0) continue
        const z = Number(style.zIndex)
        if (Number.isFinite(z) && z >= bestZ) {
          best = candidate
          bestZ = z
        }
      }
      return best
    },
    refreshBlurCanvas () {
      const blurCanvas = this.$refs.blurCanvas
      const sourceCanvas = this.findActiveViewportCanvas()
      if (!blurCanvas || !sourceCanvas || !this.$el) return

      const hostRect = this.$el.getBoundingClientRect()
      const sourceRect = sourceCanvas.getBoundingClientRect()
      if (hostRect.width <= 0 || hostRect.height <= 0 || sourceRect.width <= 0 || sourceRect.height <= 0) return

      const dpr = Math.min(window.devicePixelRatio || 1, 1.5)
      const renderScale = 0.42
      const width = Math.max(1, Math.round(hostRect.width * renderScale * dpr))
      const height = Math.max(1, Math.round(hostRect.height * renderScale * dpr))
      if (blurCanvas.width !== width || blurCanvas.height !== height) {
        blurCanvas.width = width
        blurCanvas.height = height
      }

      const ctx = blurCanvas.getContext('2d')
      if (!ctx) return

      const scaleX = sourceCanvas.width / Math.max(sourceRect.width, 1)
      const scaleY = sourceCanvas.height / Math.max(sourceRect.height, 1)
      const srcX = Math.max(0, (hostRect.left - sourceRect.left) * scaleX)
      const srcY = Math.max(0, (hostRect.top - sourceRect.top) * scaleY)
      const srcW = Math.min(sourceCanvas.width - srcX, hostRect.width * scaleX)
      const srcH = Math.min(sourceCanvas.height - srcY, hostRect.height * scaleY)

      ctx.clearRect(0, 0, width, height)
      ctx.save()
      ctx.imageSmoothingEnabled = true
      ctx.filter = 'blur(10px) saturate(1.08) brightness(1.02)'
      const pad = Math.round(Math.max(width, height) * 0.04)
      ctx.drawImage(sourceCanvas, srcX, srcY, srcW, srcH, -pad, -pad, width + (pad * 2), height + (pad * 2))
      ctx.restore()
    },
    leftActionButtonStyle (index) {
      const circle = ACTION_CIRCLES[index]
      if (!circle) return {}

      const scale = this.geometryScale
      const x = (circle.cx - VIEWBOX.x) * scale
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - (MENU_BUTTON_WIDTH / 2) - 8)}px`,
        top: `${Math.round(y - (MENU_BUTTON_HEIGHT / 2))}px`
      }
    },
    footerButtonStyleFromCircle (circle) {
      const scale = this.geometryScale
      const x = (circle.cx - VIEWBOX.x) * scale
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - (FOOTER_BTN_WRAP_WIDTH / 2))}px`,
        top: `${Math.round(y - (FOOTER_BTN_CIRCLE_SIZE / 2) - FOOTER_ZONE_TOP)}px`
      }
    },
    modeDisplayName (modeId) {
      const labels = {
        mount: 'Mount',
        capture: 'Capture',
        guiding: 'Guiding',
        focus: 'Focus',
        settings: 'Setup'
      }
      return labels[modeId] || 'Mode'
    },
    menuActionIcon (item) {
      const directIcon = String(item && item.icon ? item.icon : '')
      if (directIcon.startsWith('mdi-')) return directIcon

      const iconMap = {
        'capture-sync': 'mdi-crosshairs-gps',
        'capture-fwhm': 'mdi-chart-bell-curve',
        'capture-focus': 'mdi-image-filter-center-focus-strong',
        'guiding-loop': 'mdi-refresh',
        'guiding-range': 'mdi-arrow-left-right-bold-outline',
        'guiding-clear': 'mdi-broom',
        'focus-roi': 'mdi-select-drag',
        'focus-loop': 'mdi-refresh',
        'focus-calibration': 'mdi-tune',
        'mount-grid': 'mdi-grid',
        'mount-dso': 'mdi-star-four-points-outline',
        'mount-constellation': 'mdi-asterisk'
      }
      return iconMap[item && item.id] || ''
    },
    footerButtonIcon (actionId, label) {
      const iconMap = {
        'mount-ra-minus': 'mdi-arrow-left-thick',
        'mount-dec-minus': 'mdi-arrow-down-thick',
        'open-devices': 'mdi-lan-connect',
        'focus-left-hold': 'mdi-arrow-left-thick',
        'focus-left-step': 'mdi-minus-circle-outline',
        'focus-loop': 'mdi-refresh',
        'focus-calibration': 'mdi-tune'
      }
      if (iconMap[actionId]) return iconMap[actionId]
      if (String(label).includes('RA')) return 'mdi-arrow-left-thick'
      if (String(label).includes('DEC')) return 'mdi-arrow-down-thick'
      if (String(label).includes('Loop')) return 'mdi-refresh'
      if (String(label).includes('Device')) return 'mdi-lan-connect'
      return 'mdi-circle-medium'
    }
  }
}
</script>

<style scoped>
.control-wing {
  width: 510px;
  height: 100%;
  min-height: 0;
  flex: 0 0 auto;
  position: relative;
  pointer-events: none;
}

.control-wing__inner {
  --panel-texture-image: none;
  position: relative;
  height: 100%;
  isolation: isolate;
  padding: 0;
  pointer-events: none;
}

.control-wing__aux-border {
  position: absolute;
  inset: -14px -12px -16px -18px;
  border-radius: 0;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.22), rgba(240, 246, 255, 0.10) 18%, rgba(235, 242, 255, 0.08) 84%, rgba(220, 232, 255, 0.14)),
    linear-gradient(180deg, rgba(185, 200, 225, 0.20), rgba(168, 185, 215, 0.14));
  box-shadow:
    inset 0 0 0 1px rgba(210, 225, 255, 0.32),
    inset 0 0 0 2px rgba(160, 192, 240, 0.18),
    inset -28px 0 46px rgba(180, 208, 245, 0.12),
    0 0 0 1px rgba(232, 240, 255, 0.06),
    0 22px 38px rgba(0, 4, 10, 0.14);
  -webkit-clip-path: path("M 72 9 H 246 Q 275 9 294 49 Q 326 124 328 194 Q 324 254 286 308 Q 249 356 242 366 V 521 Q 248 587 287 631 Q 344 692 425 706 H 466 Q 506 706 506 744 V 806 Q 506 850 460 850 H 68 Q 8 850 8 792 V 622 Q 8 599 24 590 V 272 Q 24 255 8 244 V 68 Q 8 30 38 16 Q 52 9 72 9 Z");
  clip-path: path("M 72 9 H 246 Q 275 9 294 49 Q 326 124 328 194 Q 324 254 286 308 Q 249 356 242 366 V 521 Q 248 587 287 631 Q 344 692 425 706 H 466 Q 506 706 506 744 V 806 Q 506 850 460 850 H 68 Q 8 850 8 792 V 622 Q 8 599 24 590 V 272 Q 24 255 8 244 V 68 Q 8 30 38 16 Q 52 9 72 9 Z");
  opacity: 0.95;
  z-index: 0;
  pointer-events: none;
}

.control-wing__blur-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  display: block;
  opacity: 0.06;
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  z-index: 0;
  pointer-events: none;
}

.control-wing__inner::before {
  content: "";
  position: absolute;
  inset: 0;
  background-image:
    radial-gradient(circle at 16% 7%, rgba(255, 255, 255, 0.88), transparent 18%),
    radial-gradient(circle at 68% 5%, rgba(255, 255, 255, 0.55), transparent 15%),
    radial-gradient(circle at 22% 36%, rgba(225, 240, 255, 0.44), transparent 32%),
    radial-gradient(circle at 16% 74%, rgba(195, 212, 240, 0.24), transparent 22%),
    linear-gradient(118deg, transparent 0%, rgba(255, 255, 255, 0.22) 14%, transparent 15.5%, transparent 54%, rgba(255, 255, 255, 0.14) 55.5%, transparent 57%),
    linear-gradient(154deg, transparent 0%, transparent 34%, rgba(235, 245, 255, 0.14) 35%, transparent 36.2%, transparent 72%, rgba(235, 245, 255, 0.08) 73%, transparent 74%),
    var(--panel-texture-image),
    linear-gradient(180deg, rgba(245, 250, 255, 0.99) 0%, rgba(222, 233, 252, 0.99) 22%, rgba(198, 212, 238, 0.99) 52%, rgba(168, 184, 215, 0.99) 78%, rgba(148, 166, 200, 0.99) 100%);
  background-repeat: no-repeat;
  background-position: center;
  background-size: auto, auto, auto, auto, 100% 100%, 100% 100%, cover, 100% 100%;
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.90),
    inset 0 0 0 1px rgba(215, 232, 255, 0.32),
    inset -18px 0 38px rgba(200, 222, 255, 0.18),
    inset 0 36px 64px rgba(255, 255, 255, 0.26),
    inset 0 -48px 68px rgba(70, 92, 138, 0.42),
    14px 28px 56px rgba(0, 4, 10, 0.32);
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  z-index: 0;
  pointer-events: none;
}

.control-wing__inner::after {
  content: "";
  position: absolute;
  inset: 0;
  background:
    linear-gradient(to left, rgba(255, 255, 255, 0.42) 0%, rgba(242, 247, 255, 0.24) 10%, rgba(228, 238, 254, 0.08) 28%, transparent 50%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.16) 0%, rgba(255, 255, 255, 0.08) 14%, rgba(10, 22, 44, 0.04) 36%, rgba(8, 18, 38, 0.12) 100%),
    radial-gradient(circle at 12% 44%, rgba(205, 222, 255, 0.22), transparent 30%),
    radial-gradient(circle at 24% 76%, rgba(172, 198, 238, 0.16), transparent 26%),
    linear-gradient(132deg, rgba(255, 255, 255, 0.18), transparent 20%, transparent 72%, rgba(215, 230, 255, 0.12));
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  opacity: 0.96;
  z-index: 0;
  pointer-events: none;
}

.control-wing__inner > * {
  position: relative;
  z-index: 1;
}

.wing-hero {
  position: absolute;
  inset: 0;
}

.wing-eyebrow {
  position: absolute;
  left: 36px;
  top: 12px;
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 11px;
  color: var(--qs-text-muted);
  text-shadow: 0 1px 10px rgba(0, 0, 0, 0.28);
}

.mode-gear {
  position: absolute;
  width: 184px;
  height: 184px;
  pointer-events: none;
  filter: drop-shadow(0 0 18px rgba(92, 182, 255, 0.22));
}

.mode-gear__ring,
.mode-gear__halo {
  position: absolute;
  inset: 0;
  border-radius: 50%;
}

.mode-gear__ring {
  border: 2px solid rgba(120, 155, 210, 0.44);
  background:
    radial-gradient(circle at 50% 50%, transparent 0 64px, rgba(140, 175, 230, 0.18) 64px 66px, transparent 66px),
    repeating-conic-gradient(
      from 0deg,
      rgba(55, 95, 160, 0.88) 0deg 1.2deg,
      rgba(160, 185, 225, 0.22) 1.2deg 7.5deg
    ),
    radial-gradient(circle at 26% 24%, rgba(255, 255, 255, 0.22), transparent 34%),
    linear-gradient(180deg, rgba(210, 220, 238, 0.70), rgba(185, 200, 228, 0.40));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.32),
    inset 0 0 0 10px rgba(175, 190, 218, 0.20),
    inset 0 0 24px rgba(130, 165, 225, 0.14),
    0 12px 28px rgba(60, 90, 140, 0.16),
    0 0 24px rgba(110, 155, 220, 0.14);
  -webkit-mask:
    radial-gradient(circle, transparent 0 68px, #000 68px 74px, transparent 74px 100%);
  mask:
    radial-gradient(circle, transparent 0 68px, #000 68px 74px, transparent 74px 100%);
}

.mode-gear__halo {
  inset: 8px;
  border: 1px solid rgba(120, 160, 215, 0.36);
  box-shadow:
    inset 0 0 0 1px rgba(255, 255, 255, 0.18),
    0 0 18px rgba(100, 140, 210, 0.12);
}

.mode-gear__tick {
  position: relative;
  position: absolute;
  right: 18px;
  top: 18px;
  width: 16px;
  height: 34px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(45, 85, 155, 0.98), rgba(70, 115, 195, 0.70));
  box-shadow:
    0 0 16px rgba(60, 110, 200, 0.28),
    inset 0 1px 0 rgba(255, 255, 255, 0.28);
  transform: rotate(24deg);
}

.mode-gear__label {
  position: absolute;
  right: -8px;
  top: 18px;
  font-size: 11px;
  line-height: 1;
  font-weight: 600;
  letter-spacing: 0.28em;
  color: rgba(30, 55, 100, 0.88);
  text-transform: uppercase;
  transform: rotate(44deg);
  transform-origin: left center;
  text-shadow: 0 1px 8px rgba(255, 255, 255, 0.28);
}

.hero-orb {
  position: absolute;
  width: 148px;
  height: 148px;
  margin: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background:
    radial-gradient(circle at 30% 18%, rgba(255, 255, 255, 0.72), transparent 26%),
    radial-gradient(circle at 68% 75%, rgba(140, 165, 215, 0.22), transparent 30%),
    linear-gradient(180deg, rgba(245, 250, 255, 0.99) 0%, rgba(215, 228, 252, 0.99) 46%, rgba(182, 198, 232, 0.99) 100%);
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.92),
    inset 0 0 0 2px rgba(255, 255, 255, 0.70),
    inset 0 22px 32px rgba(255, 255, 255, 0.32),
    inset 0 -22px 32px rgba(90, 115, 170, 0.36),
    0 20px 40px rgba(50, 72, 130, 0.30),
    0 0 32px rgba(120, 155, 230, 0.20);
  z-index: 2;
}

.hero-orb--button {
  border: 0;
  cursor: pointer;
  pointer-events: auto;
}

.hero-orb__inner {
  width: 116px;
  height: 116px;
  border-radius: 50%;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  background:
    radial-gradient(circle at 32% 26%, rgba(255, 255, 255, 0.56), transparent 28%),
    radial-gradient(circle at 50% 12%, rgba(210, 228, 255, 0.28), transparent 32%),
    linear-gradient(180deg, rgba(235, 244, 255, 0.98) 0%, rgba(205, 220, 248, 0.99) 50%, rgba(178, 196, 230, 0.99) 100%);
  box-shadow:
    inset 0 2px 0 rgba(255, 255, 255, 0.85),
    inset 0 0 0 2px rgba(255, 255, 255, 0.60),
    inset 0 -14px 20px rgba(110, 135, 188, 0.22),
    inset 0 0 28px rgba(170, 200, 248, 0.18);
}

.hero-orb__accent {
  width: 40px;
  height: 6px;
  border-radius: 999px;
  background: linear-gradient(90deg, rgba(60, 100, 185, 0.12), rgba(55, 105, 210, 0.92), rgba(60, 100, 185, 0.12));
  box-shadow: 0 0 14px rgba(70, 120, 220, 0.28);
}

.hero-orb__mode {
  font-size: 26px;
  font-weight: 500;
  letter-spacing: 0.16em;
  color: rgba(22, 38, 72, 0.96);
  text-shadow: 0 1px 8px rgba(255, 255, 255, 0.28);
}

.hero-caption {
  position: absolute;
  left: 68px;
  top: 214px;
  width: 180px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 6px;
  text-shadow: 0 2px 12px rgba(1, 5, 12, 0.32);
}

.hero-caption__label {
  font-size: 10px;
  letter-spacing: 0.24em;
  text-transform: uppercase;
  color: var(--qs-text-muted);
}

.hero-caption__title {
  font-size: 20px;
  color: rgba(22, 38, 68, 0.96);
}

.wing-menu {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.menu-item {
  position: absolute;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  width: 92px;
  min-height: 108px;
  padding: 0;
  border: 0;
  border-radius: 24px;
  background: transparent;
  color: rgba(22, 38, 68, 0.94);
  text-align: center;
  cursor: pointer;
  text-shadow: 0 1px 6px rgba(255, 255, 255, 0.22);
  pointer-events: auto;
}

.menu-item__orb {
  width: 72px;
  height: 72px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background:
    radial-gradient(circle at 30% 22%, rgba(255, 255, 255, 0.72), transparent 26%),
    radial-gradient(circle at 68% 75%, rgba(135, 160, 212, 0.22), transparent 32%),
    linear-gradient(145deg, rgba(255, 255, 255, 0.28) 0%, transparent 18%, rgba(255, 255, 255, 0.14) 34%, transparent 50%, rgba(195, 210, 238, 0.14) 66%, transparent 78%),
    linear-gradient(180deg, rgba(242, 248, 255, 0.99) 0%, rgba(215, 228, 252, 0.99) 46%, rgba(182, 198, 232, 0.99) 100%);
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.92),
    inset 0 0 0 2px rgba(255, 255, 255, 0.60),
    inset 0 12px 22px rgba(255, 255, 255, 0.26),
    0 8px 20px rgba(50, 72, 125, 0.26),
    0 0 22px rgba(110, 145, 220, 0.14);
  font-size: 26px;
}

.menu-item__icon,
.menu-item__orb :deep(.v-icon) {
  font-size: 26px;
  color: rgba(38, 72, 145, 0.94);
  text-shadow:
    0 1px 6px rgba(255, 255, 255, 0.36),
    0 0 14px rgba(90, 135, 230, 0.18);
}

.menu-item__glyph {
  font-size: 24px;
  line-height: 1;
  color: rgba(38, 72, 145, 0.94);
  text-shadow:
    0 1px 6px rgba(255, 255, 255, 0.36),
    0 0 14px rgba(90, 135, 230, 0.18);
}

.menu-item__text {
  font-size: 12px;
  line-height: 1;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--qs-text-secondary);
}

.wing-footer {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 170px;
  pointer-events: none;
}

.dual-pad {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.dual-pad__btn {
  position: absolute;
  top: 0;
  width: 88px;
  height: 110px;
  border: 0;
  background: transparent;
  color: rgba(22, 38, 68, 0.95);
  cursor: pointer;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  text-shadow: 0 1px 6px rgba(255, 255, 255, 0.28);
  pointer-events: auto;
}

.dual-pad__cap {
  width: 76px;
  height: 76px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background:
    radial-gradient(circle at 30% 22%, rgba(255, 255, 255, 0.70), transparent 26%),
    radial-gradient(circle at 70% 76%, rgba(140, 165, 215, 0.22), transparent 32%),
    linear-gradient(145deg, rgba(255, 255, 255, 0.28) 0%, transparent 18%, rgba(255, 255, 255, 0.14) 34%, transparent 50%, rgba(195, 212, 240, 0.14) 66%, transparent 78%),
    linear-gradient(180deg, rgba(242, 248, 255, 0.99) 0%, rgba(215, 228, 252, 0.99) 46%, rgba(182, 198, 232, 0.99) 100%);
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.92),
    inset 0 0 0 1px rgba(205, 222, 255, 0.44),
    inset 0 -18px 28px rgba(110, 135, 188, 0.28),
    0 6px 18px rgba(50, 72, 125, 0.28),
    0 2px 4px rgba(50, 72, 125, 0.16);
}

.dual-pad__cap :deep(.v-icon) {
  font-size: 26px;
  color: rgba(28, 50, 95, 0.96);
  text-shadow: 0 1px 6px rgba(255, 255, 255, 0.32);
}

.dual-pad__cap--small {
  width: 60px;
  height: 60px;
}

.dual-pad__btn--active {
  color: var(--qs-text-primary);
}

.dual-pad__btn--active .dual-pad__cap {
  background:
    radial-gradient(circle at 32% 24%, rgba(215, 235, 255, 0.65), transparent 30%),
    linear-gradient(180deg, rgba(195, 218, 252, 0.99) 0%, rgba(158, 185, 238, 0.99) 50%, rgba(130, 160, 220, 0.99) 100%);
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.88),
    inset 0 0 0 1px rgba(165, 205, 255, 0.52),
    inset 0 -18px 28px rgba(90, 125, 195, 0.32),
    0 8px 20px rgba(50, 85, 165, 0.30);
}

.dual-pad__label {
  font-size: 11px;
  line-height: 1;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(38, 60, 100, 0.82);
}

.control-tag {
  display: none !important;
}
</style>

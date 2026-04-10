<template>
  <aside class="control-wing control-wing--right">
    <div class="control-wing__inner" :style="panelStyle">
      <div class="control-wing__aux-border" aria-hidden="true"></div>
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <section class="wing-hero">
        <p class="wing-eyebrow wing-eyebrow--right">{{ heroEyebrow }}</p>
        <button class="hero-orb hero-orb--button" :style="heroOrbStyle" type="button" @click="$emit('hero-action')">
          <div class="hero-orb__inner">
            <span class="hero-orb__accent"></span>
            <span class="hero-orb__mode">{{ heroModeLabel }}</span>
          </div>
        </button>
        <div class="hero-caption">
          <span class="hero-caption__label">Primary Action</span>
          <span class="hero-caption__title">{{ heroTitle }}</span>
        </div>
      </section>

      <section class="wing-center-actions">
        <button
          v-for="(item, index) in actionItems"
          :key="item.id"
          class="orb-button"
          :style="rightActionButtonStyle(index)"
          type="button"
          @click="$emit('right-action', item.id)"
        >
          <span class="orb-button__cap">
            <v-icon v-if="item.icon" class="orb-button__icon">{{ item.icon }}</v-icon>
          </span>
          <span class="orb-button__label">{{ item.label }}</span>
        </button>
      </section>

      <div v-if="statusItems.length" class="wing-side-status">
        <div class="wing-side-status__title">Status</div>
        <button
          v-for="status in statusItems"
          :key="status.id"
          class="status-pill"
          :class="[status.pillClass, status.tone ? `status-pill--${status.tone}` : '']"
          type="button"
          @click="status.actionId ? $emit('tool-action', status.actionId) : null"
        >
          <img
            v-if="status.iconSrc"
            class="status-pill__icon-image"
            :src="status.iconSrc"
            :alt="status.id"
          >
          <v-icon
            v-else-if="status.icon"
            class="status-pill__icon"
            :class="status.iconClass"
          >
            {{ status.icon }}
          </v-icon>
        </button>
      </div>

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
            data-testid="rcw-btn-toggle-docker-chart-params"
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
const PANEL_WIDTH = 510
const ACTION_BUTTON_WIDTH = 92
const ACTION_BUTTON_HEIGHT = 108
const FOOTER_BTN_WRAP_WIDTH = 88
const FOOTER_BTN_CIRCLE_SIZE = 76
const FOOTER_ZONE_TOP = PANEL_HEIGHT - PANEL_FOOTER_HEIGHT
const PANEL_CLIP_PATH = 'path("M 425.34 15.29 H 271.32 Q 245.82 15.29 228.48 51.97 Q 196.86 124.32 194.82 193.62 Q 199.92 246.61 232.56 292.47 Q 272.34 345.46 280.50 356.67 V 523.79 Q 275.40 580.86 234.60 625.70 Q 175.44 683.78 93.84 697.03 H 57.12 Q 19.38 697.03 19.38 734.73 V 790.78 Q 19.38 832.56 61.20 832.56 H 425.34 Q 489.60 832.56 489.60 770.40 V 615.50 Q 489.60 597.16 474.30 589.01 V 274.12 Q 474.30 259.86 489.60 248.65 V 79.49 Q 489.60 38.72 461.04 23.44 Q 444.72 15.29 425.34 15.29 Z")'
const BLUR_SOURCE_IDS = ['guiderCamera-canvas', 'mainCamera-canvas', 'stel-canvas']

export default {
  name: 'RightControlWing',
  props: {
    heroTitle: {
      type: String,
      default: 'Action'
    },
    heroEyebrow: {
      type: String,
      default: 'Control'
    },
    actionItems: {
      type: Array,
      default: () => []
    },
    toolItems: {
      type: Array,
      default: () => []
    },
    statusItems: {
      type: Array,
      default: () => []
    },
    footerLeft: {
      type: Object,
      default: () => ({ id: 'mount-ra-plus', label: 'RA+', tag: 'R-RA+' })
    },
    footerRight: {
      type: Object,
      default: () => ({ id: 'mount-dec-plus', label: 'DEC+', tag: 'R-DEC+' })
    },
    footerAction: {
      type: Object,
      default: () => ({ id: 'dock-toggle', label: 'D-Chart', tag: 'R-Docker' })
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
      dockerChartParamsOpen: false,
      
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
    geometryOffsetX () {
      return PANEL_WIDTH - (VIEWBOX.width * this.geometryScale)
    },
    heroOrbStyle () {
      const scale = this.geometryScale
      const x = this.geometryOffsetX + ((HERO_CIRCLE.cx - VIEWBOX.x) * scale)
      const right = x - 74
      const y = (HERO_CIRCLE.cy - VIEWBOX.y) * scale
      return {
        right: `${Math.round(right)}px`,
        top: `${Math.round(y - 74)}px`
      }
    },
    footerLeftButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_RIGHT_CIRCLE)
    },
    footerRightButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_LEFT_CIRCLE)
    },
    footerFuncButtonStyle () {
      return this.footerButtonStyleFromCircle(FOOTER_FUNC_CIRCLE)
    },
    heroModeLabel () {
      const title = String(this.heroTitle || '').trim()
      if (!title) return 'RUN'
      const tokens = title.split(/\s+/)
      if (tokens.length === 1) return tokens[0].slice(0, 3).toUpperCase()
      return tokens.map((token) => token[0]).join('').slice(0, 3).toUpperCase()
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
    rightActionButtonStyle (index) {
      const circle = ACTION_CIRCLES[index]
      if (!circle) return {}

      const scale = this.geometryScale
      const x = this.geometryOffsetX + ((circle.cx - VIEWBOX.x) * scale)
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        right: `${Math.round(x - (ACTION_BUTTON_WIDTH / 2))}px`,
        top: `${Math.round(y - (ACTION_BUTTON_HEIGHT / 2))}px`
      }
    },
    footerButtonStyleFromCircle (circle) {
      const scale = this.geometryScale
      const x = this.geometryOffsetX + ((circle.cx - VIEWBOX.x) * scale)
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        right: `${Math.round(x - (FOOTER_BTN_WRAP_WIDTH / 2))}px`,
        top: `${Math.round(y - (FOOTER_BTN_CIRCLE_SIZE / 2) - FOOTER_ZONE_TOP)}px`
      }
    },
    footerButtonIcon (actionId, label) {
      const iconMap = {
        'mount-ra-plus': 'mdi-arrow-right-thick',
        'mount-dec-plus': 'mdi-arrow-up-thick',
        'switch-settings': 'mdi-tune',
        'focus-right-hold': 'mdi-arrow-right-thick',
        'focus-right-step': 'mdi-plus-circle-outline',
        'focus-calibration': 'mdi-tune'
      }
      if (iconMap[actionId]) return iconMap[actionId]
      if (String(label).includes('RA')) return 'mdi-arrow-right-thick'
      if (String(label).includes('DEC')) return 'mdi-arrow-up-thick'
      if (String(label).includes('Setting')) return 'mdi-tune'
      if (String(label).includes('Calib')) return 'mdi-tune'
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
  inset: -14px -18px -16px -12px;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.22), rgba(240, 246, 255, 0.10) 18%, rgba(235, 242, 255, 0.08) 84%, rgba(220, 232, 255, 0.14)),
    linear-gradient(180deg, rgba(185, 200, 225, 0.20), rgba(168, 185, 215, 0.14));
  box-shadow:
    inset 0 0 0 1px rgba(210, 225, 255, 0.32),
    inset 0 0 0 2px rgba(160, 192, 240, 0.18),
    inset 28px 0 46px rgba(180, 208, 245, 0.12),
    0 0 0 1px rgba(232, 240, 255, 0.06),
    0 22px 38px rgba(0, 4, 10, 0.14);
  -webkit-clip-path: path("M 540 0 H 264 Q 235 9 216 49 Q 184 124 182 194 Q 186 254 224 308 Q 261 356 268 366 V 521 Q 262 587 223 631 Q 166 692 85 706 H 44 Q 4 706 4 744 V 900 H 540 V 622 Q 540 599 486 590 V 272 Q 486 255 540 244 V 0 Z");
  clip-path: path("M 540 0 H 264 Q 235 9 216 49 Q 184 124 182 194 Q 186 254 224 308 Q 261 356 268 366 V 521 Q 262 587 223 631 Q 166 692 85 706 H 44 Q 4 706 4 744 V 900 H 540 V 622 Q 540 599 486 590 V 272 Q 486 255 540 244 V 0 Z");
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
    radial-gradient(circle at 84% 7%, rgba(255, 255, 255, 0.88), transparent 18%),
    radial-gradient(circle at 32% 5%, rgba(255, 255, 255, 0.55), transparent 15%),
    radial-gradient(circle at 78% 36%, rgba(225, 240, 255, 0.44), transparent 32%),
    radial-gradient(circle at 84% 74%, rgba(195, 212, 240, 0.24), transparent 22%),
    linear-gradient(242deg, transparent 0%, rgba(255, 255, 255, 0.22) 14%, transparent 15.5%, transparent 54%, rgba(255, 255, 255, 0.14) 55.5%, transparent 57%),
    linear-gradient(206deg, transparent 0%, transparent 34%, rgba(235, 245, 255, 0.14) 35%, transparent 36.2%, transparent 72%, rgba(235, 245, 255, 0.08) 73%, transparent 74%),
    var(--panel-texture-image),
    linear-gradient(180deg, rgba(245, 250, 255, 0.99) 0%, rgba(222, 233, 252, 0.99) 22%, rgba(198, 212, 238, 0.99) 52%, rgba(168, 184, 215, 0.99) 78%, rgba(148, 166, 200, 0.99) 100%);
  background-repeat: no-repeat;
  background-position: center;
  background-size: auto, auto, auto, auto, 100% 100%, 100% 100%, cover, 100% 100%;
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.90),
    inset 0 0 0 1px rgba(215, 232, 255, 0.32),
    inset 18px 0 38px rgba(200, 222, 255, 0.18),
    inset 0 36px 64px rgba(255, 255, 255, 0.26),
    inset 0 -48px 68px rgba(70, 92, 138, 0.42),
    -14px 28px 56px rgba(0, 4, 10, 0.32);
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
    linear-gradient(to right, rgba(255, 255, 255, 0.42) 0%, rgba(242, 247, 255, 0.24) 10%, rgba(228, 238, 254, 0.08) 28%, transparent 50%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.16) 0%, rgba(255, 255, 255, 0.08) 14%, rgba(10, 22, 44, 0.04) 36%, rgba(8, 18, 38, 0.12) 100%),
    radial-gradient(circle at 88% 44%, rgba(205, 222, 255, 0.22), transparent 30%),
    radial-gradient(circle at 76% 76%, rgba(172, 198, 238, 0.16), transparent 26%),
    linear-gradient(228deg, rgba(255, 255, 255, 0.18), transparent 20%, transparent 72%, rgba(215, 230, 255, 0.12));
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
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.22em;
  font-size: 11px;
  color: var(--qs-text-muted);
  text-shadow: 0 1px 10px rgba(0, 0, 0, 0.28);
}

.wing-eyebrow--right {
  position: absolute;
  right: 102px;
  top: 28px;
  text-align: right;
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
  background: linear-gradient(90deg, rgba(185, 50, 80, 0.12), rgba(200, 65, 95, 0.88), rgba(185, 50, 80, 0.12));
  box-shadow: 0 0 14px rgba(210, 80, 110, 0.26);
}

.hero-orb__mode {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: 0.14em;
  color: rgba(22, 38, 72, 0.96);
  text-shadow:
    0 1px 8px rgba(255, 255, 255, 0.28),
    0 0 14px rgba(200, 80, 110, 0.16);
}

.hero-caption {
  position: absolute;
  right: 68px;
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
  text-shadow:
    0 1px 8px rgba(255, 255, 255, 0.28),
    0 0 12px rgba(195, 75, 105, 0.12);
}

.wing-center-actions {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.orb-button {
  position: absolute;
  width: 92px;
  height: 108px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  gap: 12px;
  border: 0;
  border-radius: 24px;
  background: transparent;
  color: rgba(22, 38, 68, 0.95);
  cursor: pointer;
  pointer-events: auto;
  text-shadow: 0 1px 6px rgba(255, 255, 255, 0.22);
}

.orb-button__cap {
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
}

.orb-button__icon {
  font-size: 26px !important;
  color: rgba(38, 72, 145, 0.94);
  text-shadow:
    0 1px 6px rgba(255, 255, 255, 0.36),
    0 0 14px rgba(90, 135, 230, 0.18);
}

.orb-button__label {
  font-size: 12px;
  line-height: 1;
  font-weight: 600;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: rgba(38, 60, 100, 0.82);
}

.wing-side-status {
  position: absolute;
  right: 4px;
  top: 228px;
  width: 72px;
  padding: 12px 8px 10px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 9px;
  border-radius: 26px;
  background:
    linear-gradient(180deg, rgba(238, 246, 255, 0.99) 0%, rgba(212, 226, 252, 0.99) 46%, rgba(182, 200, 235, 0.99) 100%);
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.90),
    inset 0 0 0 1px rgba(200, 220, 255, 0.40),
    inset 0 -24px 36px rgba(100, 125, 185, 0.28),
    0 16px 32px rgba(50, 72, 130, 0.24);
  backdrop-filter: blur(16px);
  pointer-events: none;
}

.wing-side-status__title {
  font-size: 10px;
  letter-spacing: 0.18em;
  text-transform: uppercase;
  color: var(--qs-text-muted);
}

.status-pill {
  position: relative;
  width: 46px;
  height: 46px;
  border: 0;
  border-radius: 50%;
  background:
    radial-gradient(circle at 32% 24%, rgba(255, 255, 255, 0.62), transparent 26%),
    linear-gradient(180deg, rgba(240, 248, 255, 0.99) 0%, rgba(212, 226, 252, 0.99) 50%, rgba(182, 198, 232, 0.99) 100%);
  color: rgba(28, 48, 90, 0.92);
  cursor: pointer;
  box-shadow:
    inset 0 3px 0 rgba(255, 255, 255, 0.90),
    inset 0 0 0 1px rgba(205, 222, 255, 0.44),
    inset 0 -12px 18px rgba(110, 135, 188, 0.26),
    0 6px 14px rgba(50, 72, 125, 0.24);
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0;
  pointer-events: auto;
}

.status-pill__icon-image {
  width: 22px;
  height: 22px;
  object-fit: contain;
  pointer-events: none;
}

.status-pill__icon {
  font-size: 22px !important;
}

.status-pill__icon--connected {
  color: #78ec9a;
}

.status-pill__icon--busy {
  color: #ffd66e;
}

.status-pill__icon--error {
  color: #ff6d6d;
}

.status-pill__icon--offline {
  color: rgba(100, 125, 175, 0.72);
}

.status-pill--clickable:active {
  transform: scale(0.97);
}

.status-pill--connected {
  box-shadow:
    inset 0 1px 0 rgba(230, 240, 255, 0.2),
    inset 0 0 0 1px rgba(82, 187, 126, 0.22),
    0 8px 18px rgba(2, 7, 16, 0.18);
}

.status-pill--busy {
  box-shadow:
    inset 0 1px 0 rgba(230, 240, 255, 0.2),
    inset 0 0 0 1px rgba(240, 191, 92, 0.24),
    0 8px 18px rgba(2, 7, 16, 0.18);
}

.status-pill--error {
  box-shadow:
    inset 0 1px 0 rgba(230, 240, 255, 0.2),
    inset 0 0 0 1px rgba(255, 109, 109, 0.26),
    0 8px 18px rgba(2, 7, 16, 0.18);
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

@media (max-width: 960px) {
  .wing-side-status {
    right: 6px;
    top: 238px;
    width: 60px;
    padding: 10px 6px 8px;
    gap: 7px;
  }

  .status-pill {
    width: 40px;
    height: 40px;
  }
}

</style>

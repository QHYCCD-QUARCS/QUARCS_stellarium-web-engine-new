<template>
  <aside class="control-wing control-wing--right">
    <div class="control-wing__inner" :style="panelStyle">
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <span class="control-tag control-tag--panel">R-Panel</span>
      <section class="wing-hero">
        <span class="control-tag control-tag--section">R-Hero</span>
        <p class="wing-eyebrow wing-eyebrow--right">{{ heroEyebrow }}</p>
        <button class="hero-orb hero-orb--button" :style="heroOrbStyle" type="button" @click="$emit('hero-action')">
          <span class="control-tag control-tag--orb">R-HeroOrb</span>
          <div class="hero-orb__inner"></div>
        </button>
        <div class="hero-caption">
          <span class="control-tag control-tag--caption">R-HeroText</span>
          <span>{{ heroTitle }}</span>
        </div>
      </section>

      <section class="wing-center-actions">
        <div v-if="actionItems.length" class="wing-actions-card">
          <div class="wing-actions-card__title">Actions</div>
        </div>
        <button
          v-for="(item, index) in actionItems"
          :key="item.id"
          class="orb-button"
          :style="rightActionButtonStyle(index)"
          type="button"
          @click="$emit('right-action', item.id)"
        >
          <span class="control-tag control-tag--button">{{ item.tag }}</span>
          <span class="orb-button__content">
            <v-icon v-if="item.icon" class="orb-button__icon">{{ item.icon }}</v-icon>
            <span class="orb-button__text">{{ item.label }}</span>
          </span>
        </button>
      </section>

      <div v-if="statusItems.length" class="wing-side-status">
        <button
          v-for="status in statusItems"
          :key="status.id"
          class="status-pill"
          :class="[status.pillClass, status.tone ? `status-pill--${status.tone}` : '']"
          type="button"
          @click="status.actionId ? $emit('tool-action', status.actionId) : null"
        >
          <span class="control-tag control-tag--button">{{ status.tag }}</span>
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
            <span class="control-tag control-tag--button">{{ footerLeft.tag }}</span>
            {{ footerLeft.label }}
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
            <span class="control-tag control-tag--button">{{ footerRight.tag }}</span>
            {{ footerRight.label }}
          </button>
          <button
            class="dual-pad__btn dual-pad__btn--func"
            :class="{ 'dual-pad__btn--active': dockerChartParamsOpen }"
            :style="footerFuncButtonStyle"
            type="button"
            data-testid="rcw-btn-toggle-docker-chart-params"
            @click="handleFooterAction"
          >
            <span class="control-tag control-tag--button">{{ footerAction.tag }}</span>
            {{ footerAction.label }}
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
const FOOTER_BTN_SIZE = 76
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
        right: `${Math.round(x - 29)}px`,
        top: `${Math.round(y - 29)}px`
      }
    },
    footerButtonStyleFromCircle (circle) {
      const scale = this.geometryScale
      const x = this.geometryOffsetX + ((circle.cx - VIEWBOX.x) * scale)
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        right: `${Math.round(x - (FOOTER_BTN_SIZE / 2))}px`,
        top: `${Math.round(y - (FOOTER_BTN_SIZE / 2) - FOOTER_ZONE_TOP)}px`
      }
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

.control-wing__blur-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  display: block;
  opacity: 0.46;
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
    radial-gradient(circle at 78% 12%, rgba(126, 170, 255, 0.18), transparent 24%),
    radial-gradient(circle at 72% 34%, rgba(62, 99, 180, 0.16), transparent 36%),
    radial-gradient(circle at 66% 58%, rgba(32, 68, 142, 0.14), transparent 34%),
    radial-gradient(circle at 80% 20%, rgba(245, 248, 255, 0.14) 0 0.8px, transparent 1.6px),
    radial-gradient(circle at 66% 30%, rgba(214, 229, 255, 0.12) 0 0.9px, transparent 1.8px),
    radial-gradient(circle at 76% 46%, rgba(205, 225, 255, 0.1) 0 1px, transparent 2px),
    radial-gradient(circle at 70% 68%, rgba(245, 250, 255, 0.08) 0 1.1px, transparent 2.2px),
    linear-gradient(242deg, transparent 0%, rgba(156, 196, 255, 0.06) 14%, transparent 15.5%, transparent 54%, rgba(156, 196, 255, 0.05) 55.5%, transparent 57%),
    linear-gradient(206deg, transparent 0%, transparent 34%, rgba(120, 168, 240, 0.05) 35%, transparent 36.2%, transparent 72%, rgba(120, 168, 240, 0.04) 73%, transparent 74%),
    var(--panel-texture-image),
    linear-gradient(180deg, rgba(10, 17, 31, 0.72) 0%, rgba(7, 13, 24, 0.82) 42%, rgba(4, 9, 17, 0.92) 100%);
  background-repeat: no-repeat;
  background-position: center;
  background-size: auto, auto, auto, auto, auto, auto, auto, 100% 100%, 100% 100%, cover, 100% 100%;
  box-shadow:
    inset 0 1px 0 rgba(225, 237, 255, 0.16),
    inset 0 0 0 1px rgba(120, 164, 236, 0.12),
    inset 18px 0 38px rgba(86, 132, 220, 0.07),
    inset 0 28px 44px rgba(176, 207, 255, 0.04),
    inset 0 -30px 42px rgba(3, 7, 14, 0.34),
    -10px 16px 28px rgba(0, 4, 10, 0.16);
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
    linear-gradient(180deg, rgba(255, 255, 255, 0.04) 0%, rgba(255, 255, 255, 0.015) 12%, rgba(5, 10, 18, 0.08) 36%, rgba(4, 9, 17, 0.22) 100%),
    radial-gradient(circle at 92% 42%, rgba(146, 193, 255, 0.12), transparent 28%),
    radial-gradient(circle at 74% 72%, rgba(79, 121, 204, 0.1), transparent 24%),
    linear-gradient(228deg, rgba(255, 255, 255, 0.08), transparent 20%, transparent 72%, rgba(181, 214, 255, 0.06));
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
  letter-spacing: 0.08em;
  font-size: 14px;
  color: rgba(230, 238, 249, 0.84);
  text-shadow: 0 1px 10px rgba(0, 0, 0, 0.28);
}

.wing-eyebrow--right {
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
    radial-gradient(circle at 30% 28%, rgba(189, 223, 255, 0.18), transparent 34%),
    linear-gradient(180deg, rgba(22, 33, 56, 0.72), rgba(10, 17, 31, 0.82));
  box-shadow:
    inset 0 0 0 2px rgba(223, 236, 255, 0.34),
    inset 0 14px 24px rgba(178, 212, 255, 0.08),
    0 12px 28px rgba(1, 6, 14, 0.24);
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
  background:
    radial-gradient(circle at 34% 30%, rgba(194, 226, 255, 0.12), transparent 32%),
    linear-gradient(180deg, rgba(18, 29, 48, 0.82), rgba(8, 14, 25, 0.92));
  box-shadow:
    inset 0 0 0 2px rgba(218, 234, 255, 0.24);
}

.hero-caption {
  position: absolute;
  right: 72px;
  top: 214px;
  width: 170px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0;
  font-size: 18px;
  color: rgba(243, 247, 252, 0.92);
  text-shadow: 0 2px 12px rgba(1, 5, 12, 0.32);
}

.wing-center-actions {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.wing-actions-card {
  display: none;
}

.wing-actions-card__title {
  display: none;
}

.orb-button {
  position: absolute;
  width: 58px;
  height: 58px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border: 0;
  border-radius: 50%;
  background:
    radial-gradient(circle at 30% 28%, rgba(194, 226, 255, 0.18), transparent 34%),
    linear-gradient(180deg, rgba(22, 33, 56, 0.8), rgba(9, 15, 27, 0.9));
  color: rgba(245, 248, 252, 0.95);
  font-size: 22px;
  cursor: pointer;
  box-shadow:
    inset 0 0 0 2px rgba(226, 238, 255, 0.46),
    inset 0 10px 20px rgba(196, 225, 255, 0.08),
    0 10px 24px rgba(1, 6, 14, 0.22);
  pointer-events: auto;
}

.orb-button__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1px;
  line-height: 1;
}

.orb-button__icon {
  font-size: 18px !important;
}

.orb-button__text {
  font-size: 9px;
  letter-spacing: 0.04em;
}

.wing-side-status {
  position: absolute;
  right: 8px;
  top: 244px;
  width: 58px;
  padding: 10px 6px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  border-radius: 22px;
  background:
    linear-gradient(180deg, rgba(15, 27, 46, 0.8), rgba(7, 13, 25, 0.9));
  box-shadow:
    inset 0 1px 0 rgba(220, 236, 255, 0.12),
    inset 0 0 0 1px rgba(131, 171, 239, 0.12),
    0 14px 28px rgba(2, 8, 18, 0.18);
  backdrop-filter: blur(14px);
  pointer-events: none;
}

.status-pill {
  position: relative;
  width: 42px;
  height: 42px;
  border: 0;
  border-radius: 50%;
  background:
    linear-gradient(180deg, rgba(30, 44, 70, 0.78), rgba(15, 24, 40, 0.88));
  color: rgba(242, 246, 251, 0.9);
  cursor: pointer;
  box-shadow:
    inset 0 1px 0 rgba(230, 240, 255, 0.2),
    inset 0 0 0 1px rgba(122, 166, 239, 0.12),
    0 8px 18px rgba(2, 7, 16, 0.18);
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
  color: rgba(233, 239, 246, 0.74);
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
  width: 76px;
  height: 76px;
  border: 0;
  border-radius: 50%;
  background:
    radial-gradient(circle at 30% 26%, rgba(194, 225, 255, 0.2), transparent 34%),
    linear-gradient(180deg, rgba(25, 38, 62, 0.84), rgba(10, 16, 28, 0.92));
  color: rgba(245, 248, 252, 0.95);
  font-size: 16px;
  cursor: pointer;
  box-shadow:
    inset 0 1px 0 rgba(235, 243, 255, 0.22),
    inset 0 0 0 1px rgba(127, 169, 237, 0.16),
    0 12px 24px rgba(1, 6, 14, 0.24);
  text-shadow: 0 1px 8px rgba(0, 0, 0, 0.24);
  pointer-events: auto;
}

.dual-pad__btn--func {
  width: 58px;
  height: 58px;
  font-size: 13px;
  line-height: 1.1;
}

.dual-pad__btn--active {
  background:
    radial-gradient(circle at 30% 26%, rgba(191, 225, 255, 0.26), transparent 34%),
    linear-gradient(180deg, rgba(48, 79, 125, 0.92), rgba(23, 40, 66, 0.96));
  box-shadow:
    inset 0 1px 0 rgba(245, 249, 255, 0.34),
    inset 0 0 0 1px rgba(155, 205, 255, 0.3),
    0 12px 24px rgba(18, 42, 79, 0.28);
}

.control-tag {
  display: none !important;
}

.control-tag--panel {
  left: 50%;
  top: 16px;
  transform: translateX(-50%);
}

.control-tag--section {
  right: 74px;
  top: 72px;
}

.control-tag--orb,
.control-tag--caption,
.control-tag--button {
  left: 50%;
  top: -10px;
  transform: translateX(-50%);
}

.control-tag--orb,
.control-tag--caption {
  top: -12px;
}

@media (max-width: 960px) {
  .wing-side-status {
    right: 6px;
    top: 238px;
    width: 54px;
    padding: 8px 5px;
    gap: 7px;
  }

  .status-pill {
    width: 40px;
    height: 40px;
  }
}

</style>

<template>
  <aside class="control-wing control-wing--left">
    <div ref="panelInner" class="control-wing__inner" :style="panelStyle">
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <span class="control-tag control-tag--panel">L-Panel</span>
      <section class="wing-hero">
        <span class="control-tag control-tag--section">L-Hero</span>
        <p class="wing-eyebrow">{{ heroEyebrow }}</p>
        <div class="mode-ring" :style="modeRingStyle">
          <button
            v-for="(item, index) in primaryModes"
            :key="item.id"
            class="mode-ring__slot"
            :class="{ 'mode-ring__slot--active': item.id === activeMode }"
            :style="modeRingItemStyle(index)"
            type="button"
            @click="$emit('set-mode', item.id)"
          >
            <span class="control-tag control-tag--button">{{ item.tag }}</span>
            <span class="mode-ring__label" :style="modeRingLabelStyle(index)">{{ item.label }}</span>
          </button>
        </div>
        <button
          class="hero-orb hero-orb--button"
          :style="heroOrbStyle"
          type="button"
          @click="$emit('hero-action')"
        >
          <span class="control-tag control-tag--orb">L-HeroOrb</span>
          <div class="hero-orb__inner"></div>
        </button>
        <div class="hero-caption">
          <span class="control-tag control-tag--caption">L-HeroText</span>
          <span>{{ heroTitle }}</span>
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
          <span class="control-tag control-tag--button">{{ item.tag }}</span>
          <span class="menu-item__icon">
            <v-icon v-if="String(item.icon || '').startsWith('mdi-')">{{ item.icon }}</v-icon>
            <span v-else>{{ item.icon }}</span>
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
            data-testid="lcw-btn-toggle-docker-chart-params"
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
const MENU_ICON_SIZE = 58
const FOOTER_BTN_SIZE = 76
const FOOTER_ZONE_TOP = PANEL_HEIGHT - PANEL_FOOTER_HEIGHT
const HERO_ORB_SIZE = 148
const MODE_RING_SIZE = 248
const MODE_RING_SEGMENT_WIDTH = 74
const MODE_RING_SEGMENT_HEIGHT = 118
const MODE_RING_START_ANGLE = -90
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
    modeRingStyle () {
      const scale = this.geometryScale
      const x = (HERO_CIRCLE.cx - VIEWBOX.x) * scale
      const y = (HERO_CIRCLE.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - (MODE_RING_SIZE / 2))}px`,
        top: `${Math.round(y - (MODE_RING_SIZE / 2))}px`
      }
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
        left: `${Math.round(x - (MENU_ICON_SIZE / 2) - 8)}px`,
        top: `${Math.round(y - (MENU_ICON_SIZE / 2))}px`
      }
    },
    footerButtonStyleFromCircle (circle) {
      const scale = this.geometryScale
      const x = (circle.cx - VIEWBOX.x) * scale
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - (FOOTER_BTN_SIZE / 2))}px`,
        top: `${Math.round(y - (FOOTER_BTN_SIZE / 2) - FOOTER_ZONE_TOP)}px`
      }
    },
    modeRingItemStyle (index) {
      const segmentAngle = 360 / Math.max(this.primaryModes.length, 1)
      const angle = MODE_RING_START_ANGLE + (segmentAngle * index)
      return {
        transform: `translate(-50%, -50%) rotate(${angle}deg) translateY(-${(MODE_RING_SIZE - MODE_RING_SEGMENT_HEIGHT) / 2}px)`
      }
    },
    modeRingLabelStyle (index) {
      const segmentAngle = 360 / Math.max(this.primaryModes.length, 1)
      const angle = MODE_RING_START_ANGLE + (segmentAngle * index)
      return {
        transform: `rotate(${-angle}deg)`
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
  opacity: 0.48;
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
    radial-gradient(circle at 22% 12%, rgba(126, 170, 255, 0.18), transparent 24%),
    radial-gradient(circle at 28% 36%, rgba(62, 99, 180, 0.16), transparent 36%),
    radial-gradient(circle at 34% 56%, rgba(32, 68, 142, 0.14), transparent 34%),
    radial-gradient(circle at 18% 18%, rgba(245, 248, 255, 0.14) 0 0.8px, transparent 1.6px),
    radial-gradient(circle at 30% 28%, rgba(214, 229, 255, 0.12) 0 0.9px, transparent 1.8px),
    radial-gradient(circle at 21% 43%, rgba(205, 225, 255, 0.1) 0 1px, transparent 2px),
    radial-gradient(circle at 27% 68%, rgba(245, 250, 255, 0.08) 0 1.1px, transparent 2.2px),
    linear-gradient(118deg, transparent 0%, rgba(156, 196, 255, 0.06) 14%, transparent 15.5%, transparent 54%, rgba(156, 196, 255, 0.05) 55.5%, transparent 57%),
    linear-gradient(154deg, transparent 0%, transparent 34%, rgba(120, 168, 240, 0.05) 35%, transparent 36.2%, transparent 72%, rgba(120, 168, 240, 0.04) 73%, transparent 74%),
    var(--panel-texture-image),
    linear-gradient(180deg, rgba(10, 17, 31, 0.72) 0%, rgba(7, 13, 24, 0.82) 42%, rgba(4, 9, 17, 0.92) 100%);
  background-repeat: no-repeat;
  background-position: center;
  background-size: auto, auto, auto, auto, auto, auto, auto, 100% 100%, 100% 100%, cover, 100% 100%;
  box-shadow:
    inset 0 1px 0 rgba(225, 237, 255, 0.16),
    inset 0 0 0 1px rgba(120, 164, 236, 0.12),
    inset -18px 0 38px rgba(86, 132, 220, 0.07),
    inset 0 28px 44px rgba(176, 207, 255, 0.04),
    inset 0 -30px 42px rgba(3, 7, 14, 0.34),
    10px 16px 28px rgba(0, 4, 10, 0.16);
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
    radial-gradient(circle at 8% 42%, rgba(146, 193, 255, 0.12), transparent 28%),
    radial-gradient(circle at 26% 72%, rgba(79, 121, 204, 0.1), transparent 24%),
    linear-gradient(132deg, rgba(255, 255, 255, 0.08), transparent 20%, transparent 72%, rgba(181, 214, 255, 0.06));
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

.mode-ring {
  position: absolute;
  width: 248px;
  height: 248px;
  pointer-events: none;
}

.mode-ring__slot {
  position: absolute;
  left: 50%;
  top: 50%;
  width: 74px;
  height: 118px;
  margin: 0;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding-top: 10px;
  border: 1px solid rgba(165, 205, 255, 0.18);
  border-radius: 999px 999px 22px 22px;
  background:
    linear-gradient(180deg, rgba(36, 54, 88, 0.56), rgba(12, 19, 33, 0.72));
  box-shadow:
    inset 0 1px 0 rgba(236, 244, 255, 0.12),
    inset 0 0 0 1px rgba(120, 164, 236, 0.08),
    0 10px 24px rgba(1, 6, 14, 0.12);
  cursor: pointer;
  pointer-events: auto;
  backdrop-filter: blur(8px);
}

.mode-ring__slot--active {
  border-color: rgba(174, 220, 255, 0.38);
  background:
    radial-gradient(circle at 50% 18%, rgba(192, 228, 255, 0.24), transparent 42%),
    linear-gradient(180deg, rgba(58, 90, 144, 0.9), rgba(24, 39, 64, 0.95));
  box-shadow:
    inset 0 1px 0 rgba(247, 250, 255, 0.28),
    inset 0 0 0 1px rgba(166, 210, 255, 0.2),
    0 14px 28px rgba(20, 46, 86, 0.22);
}

.mode-ring__label {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 38px;
  min-height: 38px;
  border-radius: 999px;
  color: rgba(243, 247, 252, 0.96);
  font-size: 21px;
  font-weight: 500;
  letter-spacing: 0.04em;
  text-shadow: 0 1px 8px rgba(1, 5, 12, 0.24);
}

.wing-eyebrow {
  margin: 0;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 14px;
  color: rgba(230, 238, 249, 0.84);
  text-shadow: 0 1px 10px rgba(0, 0, 0, 0.28);
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
  background:
    radial-gradient(circle at 34% 30%, rgba(194, 226, 255, 0.12), transparent 32%),
    linear-gradient(180deg, rgba(18, 29, 48, 0.82), rgba(8, 14, 25, 0.92));
  box-shadow:
    inset 0 0 0 2px rgba(218, 234, 255, 0.24);
}

.hero-caption {
  position: absolute;
  left: 90px;
  top: 214px;
  width: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0;
  font-size: 18px;
  color: rgba(242, 247, 252, 0.94);
  text-shadow: 0 2px 12px rgba(1, 5, 12, 0.32);
}

.wing-menu {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.menu-item {
  position: absolute;
  display: flex;
  align-items: center;
  gap: 14px;
  width: 248px;
  min-height: 58px;
  padding: 0 12px 0 8px;
  border: 0;
  border-radius: 20px;
  background: transparent;
  color: rgba(239, 245, 252, 0.94);
  text-align: left;
  cursor: pointer;
  text-shadow: 0 1px 10px rgba(1, 5, 12, 0.24);
  pointer-events: auto;
}

.menu-item__icon {
  width: 58px;
  height: 58px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  border-radius: 50%;
  background:
    radial-gradient(circle at 30% 28%, rgba(198, 228, 255, 0.18), transparent 34%),
    linear-gradient(180deg, rgba(21, 34, 57, 0.82), rgba(8, 14, 25, 0.9));
  box-shadow:
    inset 0 0 0 2px rgba(223, 236, 255, 0.46),
    inset 0 10px 20px rgba(196, 225, 255, 0.08),
    0 10px 22px rgba(1, 6, 14, 0.22);
  font-size: 22px;
}

.menu-item__icon :deep(.v-icon) {
  font-size: 24px;
  color: inherit;
}

.menu-item__text {
  font-size: 16px;
  line-height: 1;
  font-weight: 500;
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
  color: rgba(240, 246, 252, 0.95);
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
  position: absolute;
  z-index: 3;
  padding: 1px 4px;
  border-radius: 999px;
  background: rgba(123, 74, 226, 0.14);
  color: rgba(170, 111, 255, 0.96);
  font-size: 7px;
  line-height: 1.2;
  letter-spacing: 0.04em;
  white-space: nowrap;
  pointer-events: none;
  border: 1px solid rgba(170, 111, 255, 0.34);
}

.control-tag--panel {
  left: 50%;
  top: 16px;
  transform: translateX(-50%);
}

.control-tag--section {
  left: 74px;
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

</style>

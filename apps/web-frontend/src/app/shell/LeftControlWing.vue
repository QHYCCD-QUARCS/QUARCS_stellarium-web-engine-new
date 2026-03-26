<template>
  <aside
    class="control-wing control-wing--left"
    @mousemove="handlePanelPointerMove"
    @mouseleave="clearPanelPointer"
  >
    <div ref="panelInner" class="control-wing__inner" :style="panelStyle">
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <span class="control-tag control-tag--panel">L-Panel</span>
      <div v-if="panelPointer" class="panel-pointer-guides" aria-hidden="true">
        <div
          class="panel-pointer-guide panel-pointer-guide--vertical"
          :style="{ left: `${panelPointer.localX}px` }"
        ></div>
        <div
          class="panel-pointer-guide panel-pointer-guide--horizontal"
          :style="{ top: `${panelPointer.localY}px` }"
        ></div>
        <div
          class="panel-pointer-crosshair"
          :style="{ left: `${panelPointer.localX}px`, top: `${panelPointer.localY}px` }"
        ></div>
      </div>
      <div v-if="panelPointer" class="panel-pointer-readout">
        X: {{ panelPointer.x }} / Y: {{ panelPointer.y }}
      </div>
      <section class="wing-hero">
        <span class="control-tag control-tag--section">L-Hero</span>
        <p class="wing-eyebrow">Mode</p>
        <div class="hero-orb" :style="heroOrbStyle">
          <span class="control-tag control-tag--orb">L-HeroOrb</span>
          <div class="hero-orb__inner"></div>
        </div>
        <div class="hero-caption">
          <span class="control-tag control-tag--caption">L-HeroText</span>
          <span>Guiding</span>
        </div>
      </section>

      <div class="wing-side-rail">
        <button
          v-for="item in primaryModes"
          :key="item.glyph"
          class="side-rail__button"
          type="button"
        >
          <span class="control-tag control-tag--button">{{ item.tag }}</span>
          {{ item.glyph }}
        </button>
      </div>

      <section class="wing-menu">
        <button
          v-for="(item, index) in leftActions"
          :key="item.title"
          class="menu-item"
          :style="leftActionButtonStyle(index)"
          type="button"
        >
          <span class="control-tag control-tag--button">{{ item.tag }}</span>
          <span class="menu-item__icon">{{ item.icon }}</span>
          <span class="menu-item__text">{{ item.title }}</span>
        </button>
      </section>

      <section class="wing-footer">
        <div class="dual-pad">
          <button class="dual-pad__btn" :style="footerLeftButtonStyle" type="button">
            <span class="control-tag control-tag--button">L-RA-</span>
            RA-
          </button>
          <button class="dual-pad__btn" :style="footerRightButtonStyle" type="button">
            <span class="control-tag control-tag--button">L-DEC-</span>
            DEC-
          </button>
          <button
            class="dual-pad__btn dual-pad__btn--func"
            :class="{ 'dual-pad__btn--active': dockerChartParamsOpen }"
            :style="footerFuncButtonStyle"
            type="button"
            data-testid="lcw-btn-toggle-docker-chart-params"
            @click="toggleDockerChartParams"
          >
            <span class="control-tag control-tag--button">L-Docker</span>
            D-Chart
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
const PANEL_CLIP_PATH = 'path("M 84.66 15.29 H 238.68 Q 264.18 15.29 281.52 51.97 Q 313.14 124.32 315.18 193.62 Q 310.08 246.61 277.44 292.47 Q 237.66 345.46 229.50 356.67 V 523.79 Q 234.60 580.86 275.40 625.70 Q 334.56 683.78 416.16 697.03 H 452.88 Q 490.62 697.03 490.62 734.73 V 790.78 Q 490.62 832.56 448.80 832.56 H 84.66 Q 20.40 832.56 20.40 770.40 V 615.50 Q 20.40 597.16 35.70 589.01 V 274.12 Q 35.70 259.86 20.40 248.65 V 79.49 Q 20.40 38.72 48.96 23.44 Q 65.28 15.29 84.66 15.29 Z")'
const BLUR_SOURCE_IDS = ['guiderCamera-canvas', 'mainCamera-canvas', 'stel-canvas']

export default {
  name: 'LeftControlWing',
  data () {
    return {
      panelShapeUrl: require('@/assets/images/panel_fill_mask.svg'),
      blurTimer: null,
      panelPointer: null,
      dockerChartParamsOpen: false,
      primaryModes: [
        { glyph: '☆', tag: 'L-Mode-1' },
        { glyph: '✦', tag: 'L-Mode-2' },
        { glyph: '◎', tag: 'L-Mode-3' },
        { glyph: '◌', tag: 'L-Mode-4' }
      ],
      leftActions: [
        { icon: '☆', title: 'Guiding', tag: 'L-Guide' },
        { icon: '⟳', title: 'Tracking', tag: 'L-Track' },
        { icon: '⊙', title: 'Focus', tag: 'L-Focus' }
      ]
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
        '--panel-clip-path': PANEL_CLIP_PATH
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
    handlePanelPointerMove (event) {
      const panel = this.$refs.panelInner
      if (!panel) return

      const rect = panel.getBoundingClientRect()
      if (rect.width <= 0 || rect.height <= 0) return

      const relativeX = Math.min(Math.max(event.clientX - rect.left, 0), rect.width)
      const relativeY = Math.min(Math.max(event.clientY - rect.top, 0), rect.height)
      const localWidth = Math.max(panel.clientWidth, 1)
      const localHeight = Math.max(panel.clientHeight, 1)
      const scaleX = rect.width / localWidth
      const scaleY = rect.height / localHeight
      const localX = relativeX / Math.max(scaleX, 0.0001)
      const localY = relativeY / Math.max(scaleY, 0.0001)

      this.panelPointer = {
        x: Math.round(VIEWBOX.x + ((relativeX / rect.width) * VIEWBOX.width)),
        y: Math.round(VIEWBOX.y + ((relativeY / rect.height) * VIEWBOX.height)),
        localX: Math.round(localX),
        localY: Math.round(localY)
      }
    },
    clearPanelPointer () {
      this.panelPointer = null
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
      ctx.filter = 'blur(8px) saturate(1.15) brightness(0.92)'
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
    toggleDockerChartParams () {
      this.dockerChartParamsOpen = !this.dockerChartParamsOpen
      this.$bus && this.$bus.$emit('toggleDockerChartParams', {
        source: 'left-control-wing',
        open: this.dockerChartParamsOpen
      })
    },
    footerButtonStyleFromCircle (circle) {
      const scale = this.geometryScale
      const x = (circle.cx - VIEWBOX.x) * scale
      const y = (circle.cy - VIEWBOX.y) * scale
      return {
        left: `${Math.round(x - (FOOTER_BTN_SIZE / 2))}px`,
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
}

.control-wing__inner {
  position: relative;
  height: 100%;
  isolation: isolate;
  padding: 0;
}

.control-wing__blur-canvas {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  display: block;
  opacity: 0.82;
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  z-index: 0;
  pointer-events: none;
}

.control-wing__inner::before {
  content: "";
  position: absolute;
  inset: 0;
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0.10)),
    radial-gradient(circle at 18% 12%, rgba(255, 255, 255, 0.16), transparent 30%),
    linear-gradient(180deg, rgba(118, 132, 160, 0.16), rgba(70, 81, 104, 0.12));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.42),
    inset 0 0 0 1px rgba(255, 255, 255, 0.14),
    inset 0 18px 30px rgba(255, 255, 255, 0.10),
    inset 0 -18px 34px rgba(16, 24, 38, 0.10),
    16px 18px 30px rgba(0, 0, 0, 0.16);
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
    linear-gradient(135deg, rgba(255, 255, 255, 0.26), rgba(255, 255, 255, 0.08) 20%, transparent 42%, transparent 74%, rgba(255, 255, 255, 0.08));
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  opacity: 0.8;
  mix-blend-mode: screen;
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
  color: rgba(16, 24, 37, 0.9);
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
  background: rgba(240, 245, 252, 0.2);
  box-shadow:
    inset 0 0 0 3px rgba(246, 249, 255, 0.66),
    0 10px 22px rgba(28, 39, 55, 0.1);
}

.hero-orb__inner {
  width: 116px;
  height: 116px;
  border-radius: 50%;
  background: rgba(245, 248, 252, 0.18);
  box-shadow:
    inset 0 0 0 2px rgba(248, 251, 255, 0.54);
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
  color: rgba(18, 27, 41, 0.92);
}

.wing-side-rail {
  position: absolute;
  left: 18px;
  top: 252px;
  width: 60px;
  padding: 12px 8px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  border-radius: 28px;
  background: rgba(13, 22, 39, 0.72);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 14px 30px rgba(0, 0, 0, 0.22);
}

.side-rail__button {
  position: relative;
  width: 44px;
  height: 44px;
  border: 0;
  border-radius: 50%;
  background: rgba(244, 248, 252, 0.3);
  color: rgba(21, 29, 41, 0.88);
  font-size: 20px;
  cursor: pointer;
}

.wing-menu {
  position: absolute;
  inset: 0;
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
  color: rgba(17, 26, 39, 0.94);
  text-align: left;
  cursor: pointer;
}

.menu-item__icon {
  width: 58px;
  height: 58px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 auto;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.14);
  box-shadow:
    inset 0 0 0 5px rgba(250, 252, 255, 0.84),
    0 10px 18px rgba(20, 30, 44, 0.12);
  font-size: 22px;
}

.menu-item__text {
  font-size: 16px;
  line-height: 1;
}

.wing-footer {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  height: 170px;
}

.dual-pad {
  position: absolute;
  inset: 0;
}

.dual-pad__btn {
  position: absolute;
  top: 0;
  width: 76px;
  height: 76px;
  border: 0;
  border-radius: 50%;
  background: rgba(250, 252, 255, 0.38);
  color: rgba(17, 26, 39, 0.92);
  font-size: 16px;
  cursor: pointer;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.76),
    0 12px 22px rgba(33, 44, 62, 0.12);
}

.dual-pad__btn--func {
  width: 58px;
  height: 58px;
  font-size: 13px;
  line-height: 1.1;
}

.dual-pad__btn--active {
  background: rgba(186, 224, 255, 0.52);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.84),
    0 12px 24px rgba(33, 80, 128, 0.22);
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

.panel-pointer-readout {
  position: absolute;
  top: 18px;
  left: 18px;
  z-index: 4;
  padding: 8px 12px;
  border-radius: 999px;
  background: rgba(9, 16, 28, 0.74);
  color: rgba(244, 248, 255, 0.96);
  font-size: 12px;
  line-height: 1;
  letter-spacing: 0.04em;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.12),
    0 10px 22px rgba(0, 0, 0, 0.18);
  pointer-events: none;
  backdrop-filter: blur(10px);
}

.panel-pointer-guides {
  position: absolute;
  inset: 0;
  z-index: 3;
  pointer-events: none;
}

.panel-pointer-guide {
  position: absolute;
  background: rgba(112, 201, 255, 0.7);
  box-shadow: 0 0 10px rgba(112, 201, 255, 0.28);
}

.panel-pointer-guide--vertical {
  top: 0;
  bottom: 0;
  width: 1px;
  transform: translateX(-0.5px);
}

.panel-pointer-guide--horizontal {
  left: 0;
  right: 0;
  height: 1px;
  transform: translateY(-0.5px);
}

.panel-pointer-crosshair {
  position: absolute;
  width: 14px;
  height: 14px;
  border: 1px solid rgba(204, 243, 255, 0.96);
  border-radius: 50%;
  background: rgba(112, 201, 255, 0.18);
  box-shadow:
    0 0 0 4px rgba(112, 201, 255, 0.08),
    0 0 14px rgba(112, 201, 255, 0.26);
  transform: translate(-50%, -50%);
  pointer-events: none;
}

</style>

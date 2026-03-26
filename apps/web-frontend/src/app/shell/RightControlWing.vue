<template>
  <aside class="control-wing control-wing--right">
    <div class="control-wing__inner" :style="panelStyle">
      <canvas ref="blurCanvas" class="control-wing__blur-canvas" aria-hidden="true"></canvas>
      <span class="control-tag control-tag--panel">R-Panel</span>
      <section class="wing-hero">
        <span class="control-tag control-tag--section">R-Hero</span>
        <p class="wing-eyebrow wing-eyebrow--right">Shoot</p>
        <div class="hero-orb" :style="heroOrbStyle">
          <span class="control-tag control-tag--orb">R-HeroOrb</span>
          <div class="hero-orb__inner"></div>
        </div>
        <div class="hero-caption">
          <span class="control-tag control-tag--caption">R-HeroText</span>
          <span>Astro Cam</span>
        </div>
      </section>

      <section class="wing-center-actions">
        <button
          v-for="(item, index) in rightActions"
          :key="item.tag"
          class="orb-button"
          :style="rightActionButtonStyle(index)"
          type="button"
        >
          <span class="control-tag control-tag--button">{{ item.tag }}</span>
          {{ item.glyph }}
        </button>
      </section>

      <div class="wing-side-rail">
        <button
          v-for="tool in tools"
          :key="tool.tag"
          class="side-rail__button"
          type="button"
        >
          <span class="control-tag control-tag--button">{{ tool.tag }}</span>
          {{ tool.glyph }}
        </button>
      </div>

      <section class="wing-footer">
        <div class="dual-pad">
          <button class="dual-pad__btn" :style="footerLeftButtonStyle" type="button">
            <span class="control-tag control-tag--button">R-RA+</span>
            RA+
          </button>
          <button class="dual-pad__btn" :style="footerRightButtonStyle" type="button">
            <span class="control-tag control-tag--button">R-DEC+</span>
            DEC+
          </button>
          <button
            class="dual-pad__btn dual-pad__btn--func"
            :class="{ 'dual-pad__btn--active': dockerChartParamsOpen }"
            :style="footerFuncButtonStyle"
            type="button"
            data-testid="rcw-btn-toggle-docker-chart-params"
            @click="toggleDockerChartParams"
          >
            <span class="control-tag control-tag--button">R-Docker</span>
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
const FOOTER_BTN_SIZE = 76
const FOOTER_ZONE_TOP = PANEL_HEIGHT - PANEL_FOOTER_HEIGHT
const PANEL_CLIP_PATH = 'path("M 425.34 15.29 H 271.32 Q 245.82 15.29 228.48 51.97 Q 196.86 124.32 194.82 193.62 Q 199.92 246.61 232.56 292.47 Q 272.34 345.46 280.50 356.67 V 523.79 Q 275.40 580.86 234.60 625.70 Q 175.44 683.78 93.84 697.03 H 57.12 Q 19.38 697.03 19.38 734.73 V 790.78 Q 19.38 832.56 61.20 832.56 H 425.34 Q 489.60 832.56 489.60 770.40 V 615.50 Q 489.60 597.16 474.30 589.01 V 274.12 Q 474.30 259.86 489.60 248.65 V 79.49 Q 489.60 38.72 461.04 23.44 Q 444.72 15.29 425.34 15.29 Z")'
const BLUR_SOURCE_IDS = ['guiderCamera-canvas', 'mainCamera-canvas', 'stel-canvas']

export default {
  name: 'RightControlWing',
  data () {
    return {
      panelShapeUrl: require('@/assets/images/panel_fill_mask.svg'),
      blurTimer: null,
      dockerChartParamsOpen: false,
      rightActions: [
        { glyph: '◔', tag: 'R-Orb-1' },
        { glyph: 'ISO', tag: 'R-ISO' },
        { glyph: '◀', tag: 'R-Orb-3' }
      ],
      tools: [
        { glyph: '◉', tag: 'R-Tool-1' },
        { glyph: '↓', tag: 'R-Tool-2' },
        { glyph: '⚙', tag: 'R-Tool-3' },
        { glyph: '▭', tag: 'R-Tool-4' }
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
    toggleDockerChartParams () {
      this.dockerChartParamsOpen = !this.dockerChartParamsOpen
      this.$bus && this.$bus.$emit('toggleDockerChartParams', {
        source: 'right-control-wing',
        open: this.dockerChartParamsOpen
      })
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
  opacity: 0.8;
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
    linear-gradient(180deg, rgba(255, 255, 255, 0.14), rgba(255, 255, 255, 0.08)),
    radial-gradient(circle at 82% 12%, rgba(255, 255, 255, 0.14), transparent 30%),
    linear-gradient(180deg, rgba(108, 121, 148, 0.16), rgba(62, 72, 96, 0.12));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.32),
    inset 0 0 0 1px rgba(255, 255, 255, 0.12),
    inset 0 18px 28px rgba(255, 255, 255, 0.08),
    inset 0 -18px 34px rgba(10, 18, 34, 0.14),
    16px 18px 30px rgba(0, 0, 0, 0.18);
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
    linear-gradient(135deg, rgba(255, 255, 255, 0.18), rgba(255, 255, 255, 0.05) 20%, transparent 44%, transparent 74%, rgba(255, 255, 255, 0.06));
  -webkit-clip-path: var(--panel-clip-path);
  clip-path: var(--panel-clip-path);
  opacity: 0.78;
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
  color: rgba(242, 246, 251, 0.92);
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
  background: rgba(244, 248, 252, 0.1);
  box-shadow:
    inset 0 0 0 3px rgba(229, 238, 250, 0.58),
    0 10px 22px rgba(16, 24, 40, 0.14);
}

.hero-orb__inner {
  width: 116px;
  height: 116px;
  border-radius: 50%;
  background: rgba(245, 248, 252, 0.08);
  box-shadow:
    inset 0 0 0 2px rgba(241, 247, 255, 0.42);
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
}

.wing-center-actions {
  position: absolute;
  inset: 0;
}

.orb-button {
  position: absolute;
  width: 58px;
  height: 58px;
  border: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
  color: rgba(245, 248, 252, 0.95);
  font-size: 22px;
  cursor: pointer;
  box-shadow:
    inset 0 0 0 5px rgba(245, 249, 255, 0.8),
    0 10px 24px rgba(6, 12, 26, 0.16);
}

.wing-side-rail {
  position: absolute;
  right: 18px;
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
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.08);
  color: rgba(242, 246, 251, 0.9);
  font-size: 20px;
  cursor: pointer;
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
  background: rgba(255, 255, 255, 0.22);
  color: rgba(245, 248, 252, 0.95);
  font-size: 16px;
  cursor: pointer;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.56),
    0 12px 22px rgba(6, 12, 26, 0.16);
}

.dual-pad__btn--func {
  width: 58px;
  height: 58px;
  font-size: 13px;
  line-height: 1.1;
}

.dual-pad__btn--active {
  background: rgba(111, 160, 214, 0.42);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.66),
    0 12px 24px rgba(14, 42, 79, 0.24);
}

.control-tag {
  position: absolute;
  z-index: 3;
  padding: 1px 4px;
  border-radius: 999px;
  background: rgba(123, 74, 226, 0.14);
  color: rgba(193, 150, 255, 0.98);
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

</style>

<template>
  <section
    class="bottom-dock"
    :class="{ 'bottom-dock--compact': isCompact }"
    :style="dockStyle"
  >
    <div class="bottom-dock__tabs">
      <button
        v-for="tab in tabs"
        :key="tab.id"
        type="button"
        class="bottom-dock__tab"
        :class="{ 'bottom-dock__tab--active': tab.id === activeTab }"
        @click="$emit('select-tab', tab.id)"
      >
        <span class="control-tag">{{ tab.tag }}</span>
        {{ tab.label }}
      </button>

      <button type="button" class="bottom-dock__toggle" @click="toggleHeightMode">
        <span class="control-tag control-tag--toggle">Dock-Height</span>
        {{ isCompact ? 'Expand' : 'Compact' }}
      </button>
    </div>

    <div class="bottom-dock__chart">
      <span class="control-tag control-tag--chart">Dock-Chart</span>
      <div class="chart-grid"></div>
      <svg viewBox="0 0 520 220" class="chart-line" preserveAspectRatio="none">
        <path
          d="M0,130 C38,48 78,58 118,112 C162,168 202,66 244,84 C284,102 322,216 362,184 C406,152 454,84 520,72"
          fill="none"
          stroke="rgba(143, 192, 250, 0.95)"
          stroke-width="4"
          stroke-linecap="round"
        />
        <path
          d="M244,84 C284,102 322,216 362,184 C406,152 454,84 520,72"
          fill="none"
          stroke="rgba(244, 215, 121, 0.88)"
          stroke-width="4"
          stroke-linecap="round"
        />
        <circle cx="202" cy="84" r="6" fill="transparent" stroke="rgba(143, 192, 250, 0.95)" stroke-width="3" />
        <circle cx="322" cy="184" r="6" fill="transparent" stroke="rgba(244, 215, 121, 0.88)" stroke-width="3" />
        <circle cx="396" cy="136" r="6" fill="transparent" stroke="rgba(244, 215, 121, 0.88)" stroke-width="3" />
      </svg>
      <div class="chart-label chart-label--a">{{ chartLabelA }}</div>
      <div class="chart-label chart-label--b">{{ chartLabelB }}</div>
      <div class="chart-label chart-label--c">{{ chartLabelC }}</div>
    </div>
  </section>
</template>

<script>
import { PANEL_FOOTER_HEIGHT, PANEL_OUTLINE_Y, svgYToPanelY } from './panelLayout'

export default {
  name: 'BottomDock',
  props: {
    activeTab: {
      type: String,
      default: 'guiding'
    },
    chartLabelA: {
      type: String,
      default: 'RMS --'
    },
    chartLabelB: {
      type: String,
      default: 'Loop --'
    },
    chartLabelC: {
      type: String,
      default: 'State --'
    }
  },
  data () {
    return {
      heightMode: 'compact',
      tabs: [
        { id: 'guiding', label: 'Guiding', tag: 'Dock-Guiding' },
        { id: 'focus', label: 'Focus', tag: 'Dock-Focus' },
        { id: 'histogram', label: 'Histogram', tag: 'Dock-Hist' },
        { id: 'diagonal', label: 'Diagonal', tag: 'Dock-Diag' }
      ]
    }
  },
  computed: {
    compactHeight () {
      return PANEL_FOOTER_HEIGHT
    },
    expandedHeight () {
      // Keep the expanded state visually close to the current chart-heavy layout,
      // while anchoring it to the lower contour transition in the SVG.
      return Math.round(this.compactHeight + (svgYToPanelY(PANEL_OUTLINE_Y.footerTop) - svgYToPanelY(658)) + 8)
    },
    isCompact () {
      return this.heightMode === 'compact'
    },
    dockStyle () {
      return {
        '--bottom-dock-height': `${this.isCompact ? this.compactHeight : this.expandedHeight}px`
      }
    }
  },
  methods: {
    toggleHeightMode () {
      this.heightMode = this.isCompact ? 'expanded' : 'compact'
      this.$emit('toggle-height', this.heightMode)
    }
  }
}
</script>

<style scoped>
.bottom-dock {
  position: absolute;
  left: 534px;
  right: 534px;
  bottom: 22px;
  width: auto;
  height: var(--bottom-dock-height);
  display: flex;
  flex-direction: column;
  padding: 0;
  border-radius: 28px;
  border: 1px solid rgba(233, 241, 252, 0.14);
  background:
    linear-gradient(180deg, rgba(18, 28, 46, 0.78) 0%, rgba(12, 18, 31, 0.68) 100%);
  backdrop-filter: blur(20px);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.18),
    0 24px 70px rgba(2, 5, 12, 0.38);
  overflow: hidden;
  transition: height 220ms ease, box-shadow 220ms ease, background 220ms ease;
}

.bottom-dock__tabs {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 18px;
  padding: 14px 22px 10px;
  border-bottom: 1px solid rgba(233, 241, 252, 0.1);
}

.bottom-dock__tab {
  position: relative;
  border: 0;
  padding: 0 0 10px;
  background: transparent;
  color: rgba(234, 240, 248, 0.64);
  font-size: 15px;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  cursor: pointer;
}

.bottom-dock__tab--active {
  color: rgba(244, 247, 251, 0.98);
  box-shadow: inset 0 -3px 0 #69a6ff;
}

.bottom-dock__toggle {
  position: relative;
  margin-left: auto;
  border: 0;
  min-width: 84px;
  height: 30px;
  padding: 0 12px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.09);
  color: rgba(244, 247, 251, 0.9);
  font-size: 12px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  cursor: pointer;
}

.bottom-dock__chart {
  position: relative;
  flex: 1;
  min-height: 0;
  margin: 0 16px 16px;
  border-radius: 22px;
  overflow: hidden;
  transition: margin 220ms ease;
}

.chart-grid {
  position: absolute;
  inset: 18px 18px 18px 18px;
  border-radius: 18px;
  background:
    linear-gradient(to right, rgba(220, 228, 240, 0.14) 1px, transparent 1px),
    linear-gradient(to bottom, rgba(220, 228, 240, 0.14) 1px, transparent 1px);
  background-size: 25% 25%;
}

.chart-grid::before {
  content: "";
  position: absolute;
  inset: 0;
  border-radius: 18px;
  border: 1px solid rgba(220, 228, 240, 0.08);
}

.chart-line {
  position: absolute;
  inset: 22px 20px 24px 20px;
  width: calc(100% - 40px);
  height: calc(100% - 46px);
  transition: inset 220ms ease, opacity 220ms ease;
}

.chart-label {
  position: absolute;
  font-size: 14px;
  color: rgba(244, 247, 251, 0.78);
  transition: opacity 220ms ease, transform 220ms ease;
}

.chart-label--a {
  left: 32%;
  top: 18%;
}

.chart-label--b {
  left: 58%;
  top: 52%;
}

.chart-label--c {
  left: 70%;
  top: 35%;
}

.control-tag {
  display: none !important;
}

.control-tag--chart {
  top: 10px;
}

.control-tag--toggle {
  top: -9px;
}

.bottom-dock--compact {
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.16),
    0 20px 52px rgba(2, 5, 12, 0.3);
}

.bottom-dock--compact .bottom-dock__tabs {
  padding-bottom: 8px;
}

.bottom-dock--compact .bottom-dock__chart {
  margin-bottom: 12px;
}

.bottom-dock--compact .chart-grid {
  inset: 14px 16px 12px 16px;
}

.bottom-dock--compact .chart-line {
  inset: 18px 18px 18px 18px;
}

.bottom-dock--compact .chart-label {
  opacity: 0.72;
  transform: scale(0.92);
  transform-origin: center;
}

</style>

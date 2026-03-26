<template>
  <div class="app-shell">
    <div class="app-shell__viewport">
      <div class="app-shell__stage" :style="stageStyle">
        <TopBar class="app-shell__top" />
        <div class="app-shell__stage-frame">
          <span class="control-tag">App-Panel</span>
        </div>

        <div class="app-shell__body">
          <LeftControlWing class="app-shell__left" />
          <CenterConsole class="app-shell__center" />
          <RightControlWing class="app-shell__right" />
        </div>

        <BottomDock class="app-shell__bottom" />
      </div>
    </div>
  </div>
</template>

<script>
import BottomDock from './BottomDock.vue'
import CenterConsole from './CenterConsole.vue'
import LeftControlWing from './LeftControlWing.vue'
import RightControlWing from './RightControlWing.vue'
import TopBar from './TopBar.vue'

export default {
  name: 'AppShell',
  data () {
    return {
      designMinWidth: 1600,
      designHeight: 900,
      stageWidth: 1600,
      shellScale: 1
    }
  },
  computed: {
    stageStyle () {
      return {
        width: `${this.stageWidth}px`,
        height: `${this.designHeight}px`,
        transform: `scale(${this.shellScale})`
      }
    }
  },
  components: {
    BottomDock,
    CenterConsole,
    LeftControlWing,
    RightControlWing,
    TopBar
  },
  mounted () {
    this.updateShellScale()
    window.addEventListener('resize', this.updateShellScale, { passive: true })
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.updateShellScale)
  },
  methods: {
    updateShellScale () {
      // Keep the original 1600px layout as the baseline, but let the stage
      // grow wider on extra-wide displays so the side panels can sit on the
      // actual window edges instead of staying inside a centered 16:9 frame.
      this.stageWidth = Math.max(
        this.designMinWidth,
        (window.innerWidth * this.designHeight) / Math.max(window.innerHeight, 1)
      )
      const widthScale = window.innerWidth / this.stageWidth
      const heightScale = window.innerHeight / this.designHeight
      this.shellScale = Math.min(widthScale, heightScale)
    }
  }
}
</script>

<style scoped>
.app-shell {
  position: absolute;
  inset: 0;
  pointer-events: none;
  color: #f4f7fb;
  font-family: "Avenir Next", "PingFang SC", "Noto Sans SC", sans-serif;
  z-index: 20;
}

.app-shell__viewport {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.app-shell__stage {
  position: relative;
  flex: 0 0 auto;
  transform-origin: center center;
}

.app-shell__top,
.app-shell__left,
.app-shell__right,
.app-shell__bottom {
  pointer-events: auto;
}

.app-shell__stage-frame {
  pointer-events: none;
  position: absolute;
  inset: 26px 18px 18px;
  border-radius: 44px;
  border: 1px solid rgba(214, 226, 244, 0.12);
  background:
    radial-gradient(circle at 50% 0%, rgba(143, 182, 255, 0.08), transparent 24%),
    radial-gradient(circle at 50% 100%, rgba(143, 182, 255, 0.06), transparent 26%);
  box-shadow:
    inset 0 0 0 1px rgba(255, 255, 255, 0.05),
    inset 0 -40px 120px rgba(2, 7, 16, 0.18);
}

.control-tag {
  position: absolute;
  left: 50%;
  top: 10px;
  transform: translateX(-50%);
  z-index: 2;
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

.app-shell__body {
  position: absolute;
  inset: 26px 24px 18px 24px;
  display: flex;
  justify-content: space-between;
  align-items: stretch;
  gap: 14px;
}

.app-shell__center {
  pointer-events: none;
}
</style>

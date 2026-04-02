<template>
  <div class="viewport-host">
    <div class="viewport-host__stage" :style="stageStyle">
      <div class="viewport-host__frame">
        <LegacyAppHost class="viewport-host__legacy" />
        <div class="viewport-host__scrim"></div>
      </div>
    </div>
  </div>
</template>

<script>
import LegacyAppHost from './LegacyAppHost.vue'

export default {
  name: 'ViewportHost',
  components: {
    LegacyAppHost
  },
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
  mounted () {
    this.updateShellScale()
    window.addEventListener('resize', this.updateShellScale, { passive: true })
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.updateShellScale)
  },
  methods: {
    updateShellScale () {
      // Match the shell stage sizing so the underlying viewport expands with
      // wide screens and stays aligned with the overlay panels.
      const viewportWidth = Math.max(window.innerWidth, 1)
      const viewportHeight = Math.max(window.innerHeight, 1)
      if (viewportWidth <= 960) {
        this.stageWidth = this.designMinWidth
      } else {
        this.stageWidth = Math.max(
          this.designMinWidth,
          (viewportWidth * this.designHeight) / viewportHeight
        )
      }
      const widthScale = viewportWidth / this.stageWidth
      const heightScale = viewportHeight / this.designHeight
      this.shellScale = Math.min(widthScale, heightScale)
    }
  }
}
</script>

<style scoped>
.viewport-host {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: #02060d;
}

.viewport-host__stage {
  position: relative;
  flex: 0 0 auto;
  transform-origin: center center;
}

.viewport-host__frame {
  position: absolute;
  inset: 26px 18px 18px;
  overflow: hidden;
  border-radius: 44px;
  background: #02060d;
  isolation: isolate;
}

.viewport-host__legacy,
.viewport-host__scrim {
  position: absolute;
  inset: 0;
  overflow: hidden;
  border-radius: inherit;
}

.viewport-host__scrim {
  pointer-events: none;
  background: transparent;
}

@media (max-width: 960px) {
  .viewport-host__frame {
    inset: 10px;
    border-radius: 28px;
  }
}
</style>

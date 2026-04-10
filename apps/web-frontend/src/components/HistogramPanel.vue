<template>
  <transition name="panel">
    <div
      class="chart-panel"
      :style="{ bottom: bottom + 'px', left: ComponentPadding + 'px', right: ComponentPadding + 'px', height: height + 'px' }"
      @click.stop
      @mousedown.stop
      @mouseup.stop
      @touchstart.stop
      @touchmove.stop
      @touchend.stop
      @wheel.stop
      data-testid="hp-panel"
    >
    <HistogramChart ref="histogramchart" class="histogram-chart" data-testid="hp-chart"/>
    <DialKnob class="dial-knob" data-testid="hp-dial-knob"/>
    <div class="buttons-container" data-testid="hp-buttons-container">
      <button @click.stop.prevent="calcWhiteBalanceGains" class="get-click btn-Reset" data-testid="hp-btn-white-balance">
        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/WhiteBalance.svg" height="20px" style="min-height: 20px; pointer-events: none;" data-testid="hp-img-white-balance"></img>
        </div>
      </button>

      <button @click.stop.prevent="AutoHistogram" class="get-click btn-Auto" data-testid="hp-btn-auto"><v-icon data-testid="hp-icon-auto">mdi-alpha-a-circle-outline</v-icon></button>

      <button @click.stop.prevent="ResetHistogram" class="get-click btn-Reset" data-testid="hp-btn-reset">
        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/reset.svg" height="25px" style="min-height: 25px; pointer-events: none;" data-testid="hp-img-reset"></img>
        </div>
      </button>

      <!-- 切换：全图 / 有效区间（支持鼠标点击和触摸） -->
      <button @click.stop.prevent="toggleHistogramRangeMode" class="get-click btn-Range" :class="{ 'active-range': showEffectiveRange }" 
        data-testid="hp-btn-toggle-range" :data-state="showEffectiveRange ? 'range' : 'full'">
        <span v-if="showEffectiveRange" data-testid="hp-range-label-range">区</span>
        <span v-else data-testid="hp-range-label-full">全</span>
      </button>

    </div>

  </div>
</transition>
</template>

<script>
import HistogramChart from './Chart-Histogram.vue'
import DialKnob from './Dial-Knob.vue'

export default {
  name: 'HistogramPanel',
  data() {
    return {
      bottom: 14,
      ComponentPadding: 0,
      height: 128,

      histogram_min: 0,
      histogram_max: 65535,

      // true：只绘制有效区间；false：绘制全局直方图
      showEffectiveRange: true,
    };
  },
  components: {
    HistogramChart,
    DialKnob,
  },
  created() {
    this.$bus.$on('AutoHistogramNum', this.setAutoHistogramNum);
  },
  mounted() {
    this.updatePosition(); // 初始化位置
    window.addEventListener('resize', this.updatePosition);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.updatePosition);
    this.$bus.$off('AutoHistogramNum', this.setAutoHistogramNum);
  },
  methods: {
    getStageMetrics() {
      const stageEl = this.$el && this.$el.parentElement ? this.$el.parentElement : null
      const logicalWidth = stageEl && stageEl.offsetWidth ? stageEl.offsetWidth : Math.max(window.innerWidth || 0, 320)
      const visibleWidth = stageEl && stageEl.getBoundingClientRect
        ? stageEl.getBoundingClientRect().width
        : Math.max(window.innerWidth || 0, 320)
      const scale = logicalWidth > 0 ? (visibleWidth / logicalWidth) : 1
      return {
        logicalWidth: Math.max(logicalWidth, 320),
        visibleWidth: Math.max(visibleWidth, 320),
        scale: scale > 0 ? scale : 1
      }
    },
    getViewportWidth() {
      const visualWidth = window.visualViewport && window.visualViewport.width
        ? window.visualViewport.width
        : 0
      const innerWidth = window.innerWidth || 0
      const width = visualWidth > 0 ? Math.min(innerWidth || visualWidth, visualWidth) : innerWidth
      return Math.max(width, 320)
    },
    isTouchMobileViewport(screenWidth) {
      const ua = navigator.userAgent || ''
      const touch = ('ontouchstart' in window) || (navigator.maxTouchPoints > 0)
      const mobileLike = /Android|iPhone|iPad|iPod|Mobile|Tablet/i.test(ua)
      return !!touch && (mobileLike || screenWidth <= 900)
    },
    updatePosition() {
      const screenWidth = this.getViewportWidth();
      const { logicalWidth, visibleWidth, scale } = this.getStageMetrics()
      const wingEdge = 518;
      if (this.isTouchMobileViewport(screenWidth)) {
        const desiredVisibleWidth = Math.min(Math.max(Math.floor(visibleWidth * 0.46), 220), visibleWidth - 180)
        const logicalTargetWidth = Math.max(220, Math.round(desiredVisibleWidth / scale))
        this.ComponentPadding = Math.max(Math.round((logicalWidth - logicalTargetWidth) / 2), 18)
      } else {
        this.ComponentPadding = Math.max(wingEdge, 18);
      }

      const widthBase = this.isTouchMobileViewport(screenWidth) ? logicalWidth : logicalWidth
      const newWidth = Math.max(220, widthBase - (this.ComponentPadding * 2));
      this.$bus.$emit('updateHistogramWidth', newWidth);
    },
    AutoHistogram() {
      console.log('[HistogramPanel] 触发自动拉伸模式（使用后端计算的黑白点）');
      // 自动拉伸通常配合“区间模式”观察有效范围
      if (!this.showEffectiveRange) {
        this.showEffectiveRange = true;
        this.$bus.$emit('HistogramRangeMode', true);
      }
      this.$bus.$emit('HandleHistogramNum', -1, -1);
    },
    ResetHistogram() {
      console.log('[HistogramPanel] 重置直方图到全范围 [0, 65535]');
      // 重置到全范围时，切换到“全图模式”以避免坐标轴仍停留在有效区间导致观感异常
      if (this.showEffectiveRange) {
        this.showEffectiveRange = false;
        this.$bus.$emit('HistogramRangeMode', false);
      }
      // 恢复原功能：将区间重置为 0 ~ 65535 全范围
      this.$bus.$emit('HandleHistogramNum', 0, 65535);
    },
    // 切换"全图 / 有效区间"显示模式
    toggleHistogramRangeMode() {
      this.showEffectiveRange = !this.showEffectiveRange;
      const modeText = this.showEffectiveRange ? '有效区间模式' : '全图模式';
      console.log(`[HistogramPanel] 切换直方图显示模式 -> ${modeText} (showEffectiveRange: ${this.showEffectiveRange})`);
      
      // 通知拨盘组件和直方图图表组件同步区间模式
      this.$bus.$emit('HistogramRangeMode', this.showEffectiveRange);
      
      // 提供用户反馈
      this.$bus.$emit('SendConsoleLogMsg', `直方图切换到${modeText}`, 'info');
    },
    setAutoHistogramNum(min, max) {
      this.histogram_min = min;
      this.histogram_max = max;
    },
    calcWhiteBalanceGains() {
      console.log('[HistogramPanel] 触发白平衡计算');
      this.$bus.$emit('calcWhiteBalanceGains');
    },
  }
}
</script>

<style scoped>
.chart-panel {
  position: absolute;
  overflow: hidden;
  background: transparent;
  backdrop-filter: none;
  border: none;
  border-radius: 0;
  box-shadow: none;
  transition: width 0.2s ease;
}

.chart-panel::before {
  content: "";
  position: absolute;
  left: 14px;
  right: 14px;
  top: 46px;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(125, 168, 230, 0.44), transparent);
}

@keyframes showPanelAnimation {
  from {
    bottom: -150px;
  }
  to {
    bottom: 14px;
  }
}

@keyframes hidePanelAnimation {
  from {
    bottom: 14px;
  }
  to {
    bottom: -150px;
  }
}

.panel-enter-active {
  animation: showPanelAnimation 0.15s forwards;
}

.panel-leave-active {
  animation: hidePanelAnimation 0.15s forwards;
}

.histogram-chart {
  position: absolute;
  top: 42px;
  left: 12px;
}

.dial-knob {
  position: absolute;
  top: 42px;
  left: 12px;
}

.buttons-container {
  display: flex;
  justify-content: space-between;
  position: absolute;
  top: 8px;
  left: 18px;
  right: 18px;
}

@media (max-width: 1024px) {
  .buttons-container {
    left: 16px;
    right: 16px;
  }
}

@media (max-width: 640px) {
  .buttons-container {
    left: 14px;
    right: 14px;
  }
}

.btn-Auto {
  width: 34px;
  height: 34px;
  user-select: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background:
    linear-gradient(180deg, rgba(212, 224, 248, 0.96), rgba(188, 204, 234, 0.98));
  backdrop-filter: blur(10px);
  border: 1px solid rgba(165, 192, 238, 0.42);
  border-radius: 50%; 
  box-sizing: border-box;
  color: rgba(28, 52, 95, 0.92);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-Range {
  width: 34px;
  height: 34px;
  user-select: none;
  background:
    linear-gradient(180deg, rgba(212, 224, 248, 0.96), rgba(188, 204, 234, 0.98));
  backdrop-filter: blur(10px);
  border: 1px solid rgba(165, 192, 238, 0.42);
  border-radius: 50%;
  box-sizing: border-box;
  color: rgba(28, 52, 95, 0.92);
  font-size: 13px;
  font-weight: 600;
  transition: all 0.2s ease;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-Range.active-range {
  background:
    linear-gradient(180deg, rgba(95, 148, 218, 0.94), rgba(62, 108, 188, 0.96));
  border-color: rgba(160, 205, 255, 0.48);
  color: rgba(255, 255, 255, 0.95);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.28),
    0 0 16px rgba(90, 156, 255, 0.22);
}

.btn-Reset {
  width: 34px;
  height: 34px;
  user-select: none;
  background:
    linear-gradient(180deg, rgba(212, 224, 248, 0.96), rgba(188, 204, 234, 0.98));
  backdrop-filter: blur(10px);
  border: 1px solid rgba(165, 192, 238, 0.42);
  border-radius: 50%; 
  box-sizing: border-box;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-WhiteBalance {
  width: 34px;
  height: 34px;
  user-select: none;
  background:
    linear-gradient(180deg, rgba(212, 224, 248, 0.96), rgba(188, 204, 234, 0.98));
  backdrop-filter: blur(10px);
  border: 1px solid rgba(165, 192, 238, 0.42);
  border-radius: 50%; 
  box-sizing: border-box;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-Auto:active,
.btn-Reset:active,
.btn-WhiteBalance:active,
.btn-Range:active {
  transform: scale(0.95); /* 点击时缩小按钮 */
  filter: brightness(1.1);
}

</style>

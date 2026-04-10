<template>
<transition name="panel">
  <div
    class="chart-panel"
    :style="{ bottom: bottom + 'px', left: ComponentPadding + 'px', right: ComponentPadding + 'px', height: height + 'px' }"
    data-testid="ui-chart-component-root"
    :data-exp-time-ms="String(ExpTime)"
    :data-loop-exp-state="isLoopping ? 'on' : 'off'"
    :data-guiding="isGuiding ? 'true' : 'false'"
    :data-guider-status="CurrentGuiderStatus"
  >
    <LineChart ref="linechart" class="line-chart"/>
    
    <ScatterChart ref="scatterchart" class="scatter-chart"/>

    <div class="buttons-container">

      <button
        :class="LoopExpSwitchBtnClass"
        :style="{ animationDuration: ExpTime + 'ms' }"
        @click="LoopExpSwitch"
        data-testid="ui-chart-component-btn-loop-exp-switch"
        :data-state="isLoopping ? 'on' : 'off'"
        :aria-pressed="isLoopping ? 'true' : 'false'"
      >
        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/GuiderLoopExp.svg" height="20px" style="min-height: 20px; pointer-events: none;"></img>
        </div>
      </button>

      <button class="btn-Style" :class="GuiderSwitchBtnClass"
        @mousedown="startPress" @mouseup="endPress" @mouseleave="cancelPress"
        @touchstart.stop.prevent="startPress" @touchend.stop.prevent="endPress"
        @touchcancel.stop.prevent="cancelPress"
        data-testid="ui-chart-component-btn-start-press"
        :data-guiding="isGuiding ? 'true' : 'false'"
        :data-status="CurrentGuiderStatus"
        :aria-pressed="isGuiding ? 'true' : 'false'">

        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/Guider.svg" height="20px" style="min-height: 20px; pointer-events: none;"></img>
        </div>
      </button>

      <button
        class="btn-Style"
        @click="ExpTimeSwitch"
        data-testid="ui-chart-component-btn-exp-time-switch"
        :data-exp-time-ms="String(ExpTime)"
      >
        <span v-if="ExpTime === 1000">
          <div style="display: flex; justify-content: center; align-items: center;">
            <img src="@/assets/images/svg/ui/Exp-1000.svg" height="25px" style="min-height: 25px; pointer-events: none;"></img>
          </div>
        </span>
        <span v-if="ExpTime === 2000">
          <div style="display: flex; justify-content: center; align-items: center;">
            <img src="@/assets/images/svg/ui/Exp-2000.svg" height="25px" style="min-height: 25px; pointer-events: none;"></img>
          </div>
        </span>
        <span v-if="ExpTime === 500">
          <div style="display: flex; justify-content: center; align-items: center;">
            <img src="@/assets/images/svg/ui/Exp-500.svg" height="25px" style="min-height: 25px; pointer-events: none;"></img>
          </div>
        </span>
      </button>

      <button class="btn-Style" @click="DataClear" data-testid="ui-chart-component-btn-data-clear">
        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/delete.svg" height="20px" style="min-height: 20px; pointer-events: none;"></img>
        </div>
      </button>

      <button class="btn-Style" @click="RangeSwitch" data-testid="ui-chart-component-btn-range-switch">
        <div style="display: flex; justify-content: center; align-items: center;">
          <img src="@/assets/images/svg/ui/suofang.svg" height="20px" style="min-height: 20px; pointer-events: none;"></img>
        </div>
      </button>

    </div>
    
  </div>
</transition>
</template>

<script>
import LineChart from './Chart-Line.vue';
import ScatterChart from './Chart-Scatter.vue';

export default {
  name: 'ChartsPanel',
  data() {
    return {
      bottom: 14,
      ComponentPadding: 0,
      height: 132,
      ExpTime: 1000,
      isGuiding: false,
      isLoopping: false,
      CurrentGuiderStatus: 'null',
      // 导星丢星弹窗节流：记录上次弹窗时间（ms），默认每 5s 最多弹一次
      lastStarLostAlertTime: 0,
      starLostAlertIntervalMs: 5000,

      pressTimer: null,
      longPressThreshold: 1000,
      isLongPress: false, // 标记是否为长按
      canClick: true,

      GuiderConnect: false,

    };
  },
  components: {
    LineChart,
    ScatterChart,
  },
  created() {
    this.$bus.$on('GuiderSwitchStatus', this.GuiderSwitchStatus);
    this.$bus.$on('GuiderLoopExpStatus', this.GuiderLoopExpStatus);
    this.$bus.$on('GuiderStatus', this.GuiderStatus);
    this.$bus.$on('GuiderConnected', this.GuiderConnected);
    this.$bus.$emit('AppSendMessage', 'Vue_Command', 'getGuiderStatus');
  },
  mounted() {
    this.updatePosition(); // 初始化位置
    window.addEventListener('resize', this.updatePosition);
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.updatePosition);
  },
  computed: {
    GuiderSwitchBtnClass() {
      if (this.isGuiding) {
        return [
          {
            'btn-InGuiding': this.CurrentGuiderStatus === 'InGuiding',
            'btn-InSelecting': this.CurrentGuiderStatus === 'InSelecting',
            'btn-InCalibration': this.CurrentGuiderStatus === 'InCalibration',
            'btn-StarLostAlert': this.CurrentGuiderStatus === 'StarLostAlert',
            'btn-null': this.CurrentGuiderStatus === 'null',
          }
        ];
      } else if (this.isLoopping && this.GuiderConnect) {
        return 'btn-Ready';
      } else {
        return 'btn-null';
      }
    },
    LoopExpSwitchBtnClass() {
        return [
          {
            'btn-LoopExp-true': this.isLoopping, 
            'btn-LoopExp-false': !this.isLoopping, 
          },
        ];
    }
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
      if (this.isTouchMobileViewport(screenWidth)) {
        const desiredVisibleWidth = Math.min(Math.max(Math.floor(visibleWidth * 0.46), 220), visibleWidth - 180)
        const logicalTargetWidth = Math.max(220, Math.round(desiredVisibleWidth / scale))
        this.ComponentPadding = Math.max(Math.round((logicalWidth - logicalTargetWidth) / 2), 18)
      } else {
        // Keep panel ~500px wide, centered between wing inner edges
        this.ComponentPadding = Math.max(Math.round(screenWidth / 2 - 250), 18);
      }

      const widthBase = this.isTouchMobileViewport(screenWidth) ? logicalWidth : screenWidth
      const newWidth = Math.max(220, widthBase - (this.ComponentPadding * 2));
      this.$bus.$emit('updateLineChartWidth', newWidth);
    },
    startPress() {
      if (this.pressTimer) {
        clearTimeout(this.pressTimer);
      }
      this.isLongPress = false; // 重置长按标记
      this.pressTimer = setTimeout(() => {
        this.isLongPress = true; // 标记为长按
        this.handleLongPress();
      }, this.longPressThreshold);
    },
    endPress() {
      clearTimeout(this.pressTimer); // 清除定时器
      if (!this.isLongPress) {
        this.handleClick(); // 如果不是长按，则触发点击事件
      }
      this.pressTimer = null; // 重置定时器
    },
    cancelPress() {
      if (this.pressTimer) {
        clearTimeout(this.pressTimer);
      }
      this.pressTimer = null;
      this.isLongPress = false;
    },
    handleClick() {
      if (!this.canClick) return; // 如果不可点击，直接返回
      this.canClick = false; // 设置为不可点击
      // console.log("Button clicked");

      this.GuiderSwitch();

      // 恢复点击权限
      setTimeout(() => {
        this.canClick = true;
      }, 1000); // 1秒后恢复
    },
    handleLongPress() {
      if(this.isGuiding) return;
      // 长按事件的处理
      console.log("Button long pressed");

      this.$bus.$emit('ShowConfirmDialog', 'Recalibrate', "Are you sure you need to clear the calibration data and recalibrate?", 'Recalibrate');
    },

    GuiderSwitch() {
      if(this.isLoopping) {
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'GuiderSwitch:'+!this.isGuiding);
      } else {
        this.$bus.$emit('showMsgBox', 'Please open the loop exposure first.', 'error');
      }
    },

    LoopExpSwitch() {
      if (this.GuiderConnect) {
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'GuiderLoopExpSwitch:' + !this.isLoopping);
      } else {
        this.$bus.$emit('showMsgBox', 'Please connect the Guider camera first.', 'error');
      }
    },

    ExpTimeSwitch() {
      if (this.ExpTime === 1000) {
        this.ExpTime = 2000;
      } else if (this.ExpTime === 2000) {
        this.ExpTime = 500;
      } else if (this.ExpTime === 500) {
        this.ExpTime = 1000;
      }
      this.$bus.$emit('AppSendMessage', 'Vue_Command', 'GuiderExpTimeSwitch:' + this.ExpTime);
    },

    GuiderSwitchStatus(value) {
      if(value === 'true' || value === "true") {
        this.isGuiding = true;
        // 若后端尚未返回细分状态，先以“选星中”显示，避免把自动选星误显示为校准
        if (this.CurrentGuiderStatus !== 'InGuiding'
          && this.CurrentGuiderStatus !== 'InCalibration'
          && this.CurrentGuiderStatus !== 'InDirectionDetection') {
          this.CurrentGuiderStatus = 'InSelecting';
        }
        this.$startFeature(['GuiderCamera'], 'GuiderGuiding');
      } else {
        this.isGuiding = false;
        this.CurrentGuiderStatus = 'null';
        // 停止导星时重置丢星弹窗时间
        this.lastStarLostAlertTime = 0;
        this.$bus.$emit('GuiderStop');
        this.$stopFeature(['GuiderCamera'], 'GuiderGuiding');
      }
      console.log('GuiderSwitchStatus:', this.isGuiding);
    },

    GuiderLoopExpStatus(value) {
      if(value === 'true' || value === "true") {
        this.isLoopping = true;
        this.$startFeature(['GuiderCamera'], 'GuiderLoop');
      } else {
        this.isLoopping = false;
        this.isGuiding = false;
        this.$stopFeature(['GuiderCamera'], 'GuiderLoop');
        this.$stopFeature(['GuiderCamera'], 'GuiderGuiding');
      }
      console.log('GuiderLoopExpSwitchStatus:', this.isLoopping);
    },

    GuiderStatus(status) {
      if(status === 'InGuiding') {
        this.CurrentGuiderStatus = 'InGuiding';
        // 恢复正常导星，重置丢星弹窗时间
        this.lastStarLostAlertTime = 0;
      } else if(status === 'InSelecting') {
        this.CurrentGuiderStatus = 'InSelecting';
        this.lastStarLostAlertTime = 0;
      } else if(status === 'InCalibration') {
        this.CurrentGuiderStatus = 'InCalibration';
        // 校准状态也视为“未丢星”，重置丢星弹窗时间
        this.lastStarLostAlertTime = 0;
      } else if(status === 'StarLostAlert') {
        this.CurrentGuiderStatus = 'StarLostAlert';
        // 节流：丢星期间每 starLostAlertIntervalMs 才弹一次
        const now = Date.now();
        if (now - this.lastStarLostAlertTime >= this.starLostAlertIntervalMs) {
          this.$bus.$emit('showMsgBox', 'Lost guiding star target.', 'error');
          this.lastStarLostAlertTime = now;
        }
      }
      console.log('GuiderStatus:', this.CurrentGuiderStatus);
      this.$bus.$emit('SendConsoleLogMsg', 'GuiderStatus:' + this.CurrentGuiderStatus, 'info');
    },
    
    DataClear() {
      this.$bus.$emit('clearChartData');
    },
    RangeSwitch() {
      this.$bus.$emit('ChartRangeSwitch');
    },
    GuiderConnected(num) {
      if(num === 0){
        this.GuiderConnect = false;
        // this.$bus.$emit('showMsgBox', 'Guider is not connected.', 'error');
      } else {
        this.GuiderConnect = true;
        // this.$bus.$emit('showMsgBox', 'Guider is connected.', 'info');
      }
    },
  }
}
</script>

<style scoped>
.chart-panel {
  position: absolute;
  overflow: hidden;
  /* Zero visual presence — wing surface is the background */
  background: transparent;
  backdrop-filter: none;
  border: none;
  border-radius: 0;
  box-shadow: none;
  box-sizing: border-box;
}

.chart-panel::before {
  content: "";
  position: absolute;
  left: 14px;
  right: 14px;
  top: 48px;
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

.line-chart {
  position: absolute;
  bottom: 10px;
  left: 12px;
}

.scatter-chart {
  position: absolute;
  top: 58px;
  right: 8px;
}

.buttons-container {
  display: flex;
  justify-content: space-between;
  position: absolute;
  top: 8px;
  left: 14px;
  right: 14px;
}

.btn-Style {
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
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-LoopExp-false {
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
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 10px 18px rgba(60, 85, 140, 0.16);
}

.btn-LoopExp-true {
  width: 34px;
  height: 34px;
  user-select: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background:
    linear-gradient(180deg, rgba(95, 148, 218, 0.94), rgba(62, 108, 188, 0.96));
  backdrop-filter: blur(10px);
  border-radius: 50%; 
  box-sizing: border-box;
  border: 1px solid rgba(160, 205, 255, 0.48);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.28),
    0 0 14px rgba(88, 152, 255, 0.22);

  animation: Animation_true infinite;
}

@keyframes Animation_true {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(-180deg);
  }
}

.btn-InGuiding {
  border: 1px solid rgba(51, 218, 121, 0.95);
  box-shadow: 0 0 16px rgba(51, 218, 121, 0.16);
}

.btn-InSelecting {
  border: 1px solid rgba(120, 170, 255, 0.95);
  box-shadow: 0 0 16px rgba(120, 170, 255, 0.16);
}

.btn-InCalibration {
  border: 1px solid rgba(255, 165, 0, 1);
  box-shadow: 0 0 16px rgba(255, 165, 0, 0.18);
}

.btn-StarLostAlert {
  border: 1px solid rgba(255, 0, 0, 1);
  box-shadow: 0 0 16px rgba(255, 0, 0, 0.18);
}

.btn-Ready {
  border: 1px solid rgba(120, 170, 255, 0.95);
  box-shadow: 0 0 16px rgba(120, 170, 255, 0.16);
}

.btn-null {
  border-color: rgba(147, 188, 255, 0.16);
}

.btn-Guider:active,
.btn-Style:active {
  transform: scale(0.95); /* 点击时缩小按钮 */
  filter: brightness(1.1);
}

</style>

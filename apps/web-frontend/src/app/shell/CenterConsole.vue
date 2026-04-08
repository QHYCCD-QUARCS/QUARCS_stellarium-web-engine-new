<template>
  <section class="center-console">
    <span class="control-tag control-tag--panel">C-Panel</span>
    <div class="center-console__topline">
      <span class="control-tag control-tag--inline">C-Topline</span>
      {{ topline }}
    </div>

    <div class="center-console__metrics">
      <div class="metrics-card metrics-card--object">
        <span class="control-tag">C-ObjectCard</span>
        <h2>{{ objectTitle }}</h2>
        <p>{{ objectLine1 }}</p>
        <p>{{ objectLine2 }}</p>
        <div class="metrics-card__status">
          <span class="control-tag control-tag--inline">C-Conn</span>
          <span>Connection</span>
          <span class="metrics-card__dot"></span>
          <span>{{ connectionLabel }}</span>
        </div>
      </div>

      <div class="metrics-card metrics-card--guide">
        <span class="control-tag">C-GuideCard</span>
        <h3>{{ guideTitle }}</h3>
        <p>{{ guideLine1 }}</p>
        <p>{{ guideLine2 }}</p>
        <p>{{ guideLine3 }}</p>
        <p>{{ guideLine4 }}</p>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'CenterConsole',
  props: {
    topline: {
      type: String,
      default: 'QUARCS ASTRONOMY'
    },
    objectTitle: {
      type: String,
      default: 'No Target'
    },
    objectLine1: {
      type: String,
      default: 'RA/DEC: --'
    },
    objectLine2: {
      type: String,
      default: 'Mode: Standby'
    },
    connectionLabel: {
      type: String,
      default: 'Offline'
    },
    guideTitle: {
      type: String,
      default: 'Guide Status'
    },
    guideLine1: {
      type: String,
      default: 'RMS: --'
    },
    guideLine2: {
      type: String,
      default: 'Loop: --'
    },
    guideLine3: {
      type: String,
      default: 'Focus: --'
    },
    guideLine4: {
      type: String,
      default: 'Mount: --'
    }
  }
}
</script>

<style scoped>
.center-console {
  position: relative;
  flex: 1 1 auto;
  min-width: 0;
  height: 100%;
  pointer-events: none;
  color: rgba(245, 248, 252, 0.94);
  padding: 42px 8px 0;
}

.center-console__topline {
  position: relative;
  text-align: center;
  letter-spacing: 0.18em;
  font-size: 14px;
  color: rgba(245, 248, 252, 0.56);
  text-transform: uppercase;
}

.center-console__metrics {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  margin-top: 20px;
}

.metrics-card {
  position: relative;
  padding: 10px 2px;
  text-shadow: 0 2px 12px rgba(0, 0, 0, 0.42);
}

.metrics-card h2,
.metrics-card h3,
.metrics-card p {
  margin: 0;
}

.metrics-card h2,
.metrics-card h3 {
  margin-bottom: 8px;
  font-weight: 500;
}

.metrics-card h2 {
  font-size: 20px;
}

.metrics-card h3 {
  font-size: 18px;
  text-transform: uppercase;
}

.metrics-card p {
  margin-bottom: 6px;
  font-size: 16px;
  color: rgba(245, 248, 252, 0.82);
}

.metrics-card__status {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
  font-size: 15px;
}

.metrics-card__dot {
  width: 12px;
  height: 12px;
  border-radius: 50%;
  background: #7be081;
  box-shadow: 0 0 14px rgba(123, 224, 129, 0.62);
}

.control-tag {
  display: none !important;
}

.control-tag--panel {
  left: 50%;
  top: 8px;
  transform: translateX(-50%);
}

.control-tag--inline {
  left: 50%;
  transform: translateX(-50%);
}

</style>

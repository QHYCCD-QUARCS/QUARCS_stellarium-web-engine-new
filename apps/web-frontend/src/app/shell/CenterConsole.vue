<template>
  <section class="center-console">
    <span class="control-tag control-tag--panel">C-Panel</span>
    <div class="center-console__topline">
      <span class="control-tag control-tag--inline">C-Topline</span>
      QUARCS ASTRONOMY
    </div>

    <div class="center-console__metrics">
      <div class="metrics-card metrics-card--object">
        <span class="control-tag">C-ObjectCard</span>
        <h2>Object FS</h2>
        <p>C: 227.29'S · -47° 51'</p>
        <p>C: 23°50 53' · -56°7 38'</p>
        <div class="metrics-card__status">
          <span class="control-tag control-tag--inline">C-Conn</span>
          <span>Connection</span>
          <span class="metrics-card__dot"></span>
          <span>Wi-Fi</span>
        </div>
      </div>

      <div class="metrics-card metrics-card--guide">
        <span class="control-tag">C-GuideCard</span>
        <h3>Guide Statis</h3>
        <p>RMS: 0.330</p>
        <p>RMS: 0.046</p>
        <p>SERR: 0.60</p>
        <p>RTC: 0.000</p>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'CenterConsole'
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
  position: absolute;
  left: 0;
  top: -10px;
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

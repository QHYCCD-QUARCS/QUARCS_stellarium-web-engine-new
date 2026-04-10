<template>
  <section class="center-console">
    <div class="center-console__metrics">
      <div class="metrics-card metrics-card--object">
        <div class="metrics-card__eyebrow">Target</div>
        <h2>{{ objectTitle }}</h2>
        <p>{{ objectLine1 }}</p>
        <p>{{ objectLine2 }}</p>
        <div class="metrics-card__status">
          <span>Connection</span>
          <span class="metrics-card__dot"></span>
          <span>{{ connectionLabel }}</span>
        </div>
      </div>

      <div class="metrics-card metrics-card--guide">
        <div class="metrics-card__eyebrow">Telemetry</div>
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
  color: var(--qs-text-primary);
  padding: 0;
  overflow: visible;
}

.center-console__metrics {
  position: absolute;
  top: 46px;
  /* Stage is 1600px; wings 510px each; center-console ~528px.
     -265px places cards between wing inner edge (~250px) and search box (~640px). */
  left: -200px;
  right: -200px;
  display: flex;
  justify-content: space-between;
  z-index: 210;
  pointer-events: none;
}

.center-console__metrics > * {
  pointer-events: auto;
}

.metrics-card {
  position: relative;
  min-width: 200px;
  max-width: 280px;
  padding: 18px 22px;
  border-radius: 26px;
  border: 1px solid rgba(165, 192, 238, 0.36);
  background:
    linear-gradient(180deg, rgba(208, 220, 244, 0.90), rgba(185, 200, 230, 0.94));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.52),
    inset 0 -18px 28px rgba(130, 155, 205, 0.18),
    0 18px 30px rgba(60, 85, 140, 0.14);
  text-shadow: 0 1px 6px rgba(255, 255, 255, 0.28);
  backdrop-filter: blur(16px);
}

.metrics-card__eyebrow {
  margin-bottom: 10px;
  font-size: 10px;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: var(--qs-text-muted);
}

.metrics-card h2,
.metrics-card h3,
.metrics-card p {
  margin: 0;
}

.metrics-card h2,
.metrics-card h3 {
  margin-bottom: 10px;
  font-weight: 600;
}

.metrics-card h2 {
  font-size: 28px;
}

.metrics-card h3 {
  font-size: 22px;
  text-transform: uppercase;
  letter-spacing: 0.06em;
}

.metrics-card p {
  margin-bottom: 7px;
  font-size: 14px;
  color: var(--qs-text-secondary);
}

.metrics-card__status {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid rgba(148, 178, 230, 0.28);
  font-size: 13px;
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
</style>

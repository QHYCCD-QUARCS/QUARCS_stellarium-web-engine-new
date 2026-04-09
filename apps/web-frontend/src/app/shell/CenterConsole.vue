<template>
  <section class="center-console">
    <div class="center-console__topline">
      <span class="center-console__topline-dot"></span>
      {{ topline }}
    </div>

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
  padding: 40px 12px 0;
}

.center-console__topline {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  left: 50%;
  transform: translateX(-50%);
  padding: 10px 18px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(18, 30, 49, 0.72), rgba(8, 14, 24, 0.78));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 0 0 1px rgba(129, 169, 233, 0.12),
    0 16px 28px rgba(2, 8, 16, 0.2);
  text-align: center;
  letter-spacing: 0.22em;
  font-size: 12px;
  color: rgba(245, 248, 252, 0.68);
  text-transform: uppercase;
}

.center-console__topline-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(132, 189, 255, 0.92);
  box-shadow: 0 0 12px rgba(132, 189, 255, 0.64);
}

.center-console__metrics {
  display: flex;
  justify-content: space-between;
  gap: 24px;
  margin-top: 22px;
}

.metrics-card {
  position: relative;
  min-width: 272px;
  max-width: 320px;
  padding: 18px 22px;
  border-radius: 26px;
  border: 1px solid rgba(128, 166, 227, 0.12);
  background:
    linear-gradient(180deg, rgba(23, 37, 60, 0.82), rgba(8, 14, 25, 0.9));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 -18px 28px rgba(3, 8, 14, 0.28),
    0 18px 30px rgba(0, 0, 0, 0.18);
  text-shadow: 0 2px 12px rgba(0, 0, 0, 0.42);
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
  border-top: 1px solid rgba(128, 166, 227, 0.12);
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

<template>
  <header class="top-bar">
    <div class="top-bar__actions top-bar__actions--left">
      <button
        v-for="action in primaryActions"
        :key="action.id"
        type="button"
        class="top-bar__action"
        :class="{ 'top-bar__action--active': isActionActive(action.id) }"
        @click="$emit('top-action', action.id)"
      >
        <span class="top-bar__action-label">{{ action.label }}</span>
      </button>
    </div>
    <div class="top-bar__brand">
      <span class="control-tag">Top-Brand</span>
      <span class="top-bar__dot"></span>
      <div class="top-bar__title">{{ titleText }}</div>
      <div v-if="subtitle" class="top-bar__subtitle">{{ subtitle }}</div>
    </div>
    <div class="top-bar__actions top-bar__actions--right">
      <button
        v-for="action in secondaryActions"
        :key="action.id"
        type="button"
        class="top-bar__action top-bar__action--compact"
        :class="{ 'top-bar__action--active': isActionActive(action.id) }"
        @click="$emit('top-action', action.id)"
      >
        <span class="top-bar__action-label">{{ action.label }}</span>
      </button>
    </div>
  </header>
</template>

<script>
export default {
  name: 'TopBar',
  props: {
    title: {
      type: String,
      default: 'QUARCS Device Shell'
    },
    subtitle: {
      type: String,
      default: ''
    },
    primaryActions: {
      type: Array,
      default: () => []
    },
    secondaryActions: {
      type: Array,
      default: () => []
    },
    activeActionIds: {
      type: Array,
      default: () => []
    }
  },
  computed: {
    titleText() {
      return this.title || 'QUARCS Device Shell'
    }
  },
  methods: {
    isActionActive(actionId) {
      return this.activeActionIds.includes(actionId)
    }
  }
}
</script>

<style scoped>
.top-bar {
  position: absolute;
  top: 10px;
  left: 236px;
  right: 236px;
  z-index: 260;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.top-bar__brand {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 20px;
  height: 34px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(210, 222, 244, 0.88), rgba(188, 202, 232, 0.92));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.52),
    inset 0 0 0 1px rgba(175, 200, 248, 0.28),
    0 10px 22px rgba(60, 85, 140, 0.14);
  backdrop-filter: blur(14px);
  pointer-events: none;
}

.top-bar__actions {
  display: flex;
  align-items: center;
  gap: 8px;
  pointer-events: auto;
}

.top-bar__actions--left,
.top-bar__actions--right {
  flex: 1 1 0;
}

.top-bar__actions--right {
  justify-content: flex-end;
}

.top-bar__action {
  min-width: 72px;
  height: 34px;
  padding: 0 14px;
  border: 1px solid rgba(165, 192, 240, 0.38);
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(208, 220, 244, 0.88), rgba(185, 200, 232, 0.92));
  color: rgba(28, 48, 88, 0.88);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.52),
    0 10px 20px rgba(60, 85, 140, 0.12);
  backdrop-filter: blur(14px);
  transition: border-color 0.16s ease, background-color 0.16s ease, color 0.16s ease, transform 0.16s ease;
}

.top-bar__action:hover {
  border-color: rgba(140, 175, 240, 0.58);
  color: rgba(18, 38, 78, 0.96);
}

.top-bar__action:active {
  transform: scale(0.97);
}

.top-bar__action--compact {
  min-width: 58px;
  padding: 0 10px;
}

.top-bar__action--active {
  border-color: rgba(110, 158, 240, 0.68);
  background: linear-gradient(180deg, rgba(175, 200, 242, 0.94), rgba(152, 180, 230, 0.96));
  color: rgba(18, 38, 80, 0.96);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.58),
    0 0 0 1px rgba(130, 175, 245, 0.26) inset;
}

.top-bar__action-label {
  font-size: 10px;
  line-height: 1;
  letter-spacing: 0.16em;
  text-transform: uppercase;
}

.top-bar__title {
  font-size: 13px;
  font-weight: 600;
  letter-spacing: 0.24em;
  text-transform: uppercase;
  color: rgba(28, 48, 88, 0.82);
}

.top-bar__subtitle {
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(45, 72, 118, 0.78);
}

.top-bar__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(65, 115, 220, 0.82);
  box-shadow: 0 0 10px rgba(70, 125, 230, 0.48);
}

.control-tag {
  display: none !important;
}

@media (max-width: 960px) {
  .top-bar {
    left: 132px;
    right: 132px;
  }

  .top-bar__actions {
    gap: 6px;
  }

  .top-bar__action {
    min-width: 58px;
    padding: 0 10px;
  }
}
</style>

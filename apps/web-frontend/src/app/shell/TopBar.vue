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
  left: 18px;
  right: 18px;
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
  padding: 10px 16px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(21, 34, 55, 0.84), rgba(7, 14, 24, 0.92));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 0 0 1px rgba(131, 171, 239, 0.12),
    0 16px 26px rgba(1, 6, 14, 0.22);
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
  border: 1px solid rgba(150, 187, 255, 0.2);
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(20, 33, 55, 0.72), rgba(7, 14, 24, 0.82));
  color: rgba(244, 247, 251, 0.8);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 10px 20px rgba(1, 6, 14, 0.16);
  backdrop-filter: blur(14px);
  transition: border-color 0.16s ease, background-color 0.16s ease, color 0.16s ease, transform 0.16s ease;
}

.top-bar__action:hover {
  border-color: rgba(150, 187, 255, 0.36);
  color: rgba(244, 247, 251, 0.96);
}

.top-bar__action:active {
  transform: scale(0.97);
}

.top-bar__action--compact {
  min-width: 58px;
  padding: 0 10px;
}

.top-bar__action--active {
  border-color: rgba(137, 181, 255, 0.62);
  background: rgba(34, 58, 97, 0.58);
  color: rgba(244, 247, 251, 0.96);
  box-shadow: 0 0 0 1px rgba(137, 181, 255, 0.18) inset;
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
  color: rgba(244, 247, 251, 0.7);
}

.top-bar__subtitle {
  font-size: 11px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: rgba(244, 247, 251, 0.72);
}

.top-bar__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(135, 181, 255, 0.84);
  box-shadow: 0 0 10px rgba(135, 181, 255, 0.72);
}

.control-tag {
  display: none !important;
}

@media (max-width: 960px) {
  .top-bar {
    left: 12px;
    right: 12px;
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

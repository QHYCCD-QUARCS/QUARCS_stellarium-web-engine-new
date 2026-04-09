<template>
  <section class="settings-workspace">
    <div class="settings-workspace__header">
      <div>
        <p class="settings-workspace__eyebrow">{{ $t('ShellSettingsEyebrow') }}</p>
        <h2 class="settings-workspace__title">{{ $t('ShellSettingsTitle') }}</h2>
      </div>
      <div class="settings-workspace__header-tools">
        <div class="settings-workspace__language-block">
          <span class="settings-workspace__language-label">{{ $t('Select Language') }}</span>
          <div class="settings-workspace__language-switch">
            <button
              v-for="option in languageOptions"
              :key="option.value"
              type="button"
              class="settings-workspace__language-button"
              :class="{ 'settings-workspace__language-button--active': option.value === selectedLanguage }"
              @click="$emit('language-change', option.value)"
            >
              <v-icon small>mdi-translate</v-icon>
              <span>{{ option.text }}</span>
            </button>
          </div>
        </div>
        <div class="settings-workspace__status">
          <span
            v-for="item in summaryItems"
            :key="item.label"
            class="settings-workspace__status-chip"
          >
            <strong>{{ item.label }}</strong>
            <span>{{ item.value }}</span>
          </span>
        </div>
      </div>
    </div>

    <div class="settings-workspace__panel">
      <div v-if="deviceActions.length" class="settings-workspace__section">
        <div class="settings-workspace__section-head">
          <h3>{{ $t('ShellSettingsDeviceSection') }}</h3>
          <span>{{ $t('ShellSettingsDeviceSectionHint') }}</span>
        </div>
        <div class="settings-workspace__grid settings-workspace__grid--compact">
          <button
            v-for="action in deviceActions"
            :key="action.id"
            type="button"
            class="settings-workspace__card settings-workspace__card--compact"
            :class="{ 'settings-workspace__card--active': isActionActive(action.id) }"
            @click="$emit('device-action', action.id)"
          >
            <span class="settings-workspace__card-head">
              <span class="settings-workspace__card-icon">
                <v-icon>{{ action.icon }}</v-icon>
              </span>
              <span class="settings-workspace__card-title">{{ action.title }}</span>
            </span>
            <span class="settings-workspace__card-desc">{{ action.description }}</span>
          </button>
        </div>
      </div>

      <div class="settings-workspace__section">
        <div class="settings-workspace__section-head">
          <h3>{{ $t('ShellSettingsSystemSection') }}</h3>
          <span>{{ quickActions.length }} {{ $t('ShellSettingsItems') }}</span>
        </div>
        <div class="settings-workspace__grid">
          <button
            v-for="action in quickActions"
            :key="action.id"
            type="button"
            class="settings-workspace__card"
            :class="{ 'settings-workspace__card--active': isActionActive(action.id) }"
            @click="$emit('quick-action', action.id)"
          >
            <span class="settings-workspace__card-head">
              <span class="settings-workspace__card-icon">
                <v-icon>{{ action.icon }}</v-icon>
              </span>
              <span class="settings-workspace__card-title">{{ action.title }}</span>
            </span>
            <span class="settings-workspace__card-desc">{{ action.description }}</span>
          </button>
        </div>
      </div>

      <div v-if="advancedActions.length" class="settings-workspace__section">
        <div class="settings-workspace__section-head">
          <h3>{{ $t('ShellSettingsAdvancedSection') }}</h3>
          <span>{{ $t('ShellSettingsAdvancedHint') }}</span>
        </div>
        <div class="settings-workspace__grid settings-workspace__grid--compact">
          <button
            v-for="action in advancedActions"
            :key="action.id"
            type="button"
            class="settings-workspace__card settings-workspace__card--compact"
            :class="{ 'settings-workspace__card--active': isActionActive(action.id) }"
            @click="$emit('quick-action', action.id)"
          >
            <span class="settings-workspace__card-head">
              <span class="settings-workspace__card-icon">
                <v-icon>{{ action.icon }}</v-icon>
              </span>
              <span class="settings-workspace__card-title">{{ action.title }}</span>
            </span>
            <span class="settings-workspace__card-desc">{{ action.description }}</span>
          </button>
        </div>
      </div>
    </div>
  </section>
</template>

<script>
export default {
  name: 'SettingsWorkspace',
  props: {
    summaryItems: {
      type: Array,
      default: () => []
    },
    deviceActions: {
      type: Array,
      default: () => []
    },
    quickActions: {
      type: Array,
      default: () => []
    },
    advancedActions: {
      type: Array,
      default: () => []
    },
    activeActionIds: {
      type: Array,
      default: () => []
    },
    languageOptions: {
      type: Array,
      default: () => []
    },
    selectedLanguage: {
      type: String,
      default: 'en'
    }
  },
  methods: {
    isActionActive (actionId) {
      return this.activeActionIds.includes(actionId)
    }
  }
}
</script>

<style scoped>
.settings-workspace {
  position: relative;
  flex: 1 1 auto;
  min-width: 0;
  height: 100%;
  padding: 34px 12px 86px;
  display: flex;
  flex-direction: column;
  gap: 18px;
  color: var(--qs-text-primary);
}

.settings-workspace::before {
  content: "";
  position: absolute;
  inset: 76px 6px 56px;
  border-radius: 34px;
  background:
    radial-gradient(circle at 50% 0%, rgba(118, 167, 244, 0.08), transparent 24%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.02), transparent 12%, transparent 88%, rgba(255, 255, 255, 0.02));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.04),
    inset 0 0 0 1px rgba(128, 166, 227, 0.06);
  pointer-events: none;
}

.settings-workspace__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 20px;
}

.settings-workspace__header-tools {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 14px;
  max-width: 52%;
}

.settings-workspace__eyebrow {
  margin: 0 0 8px;
  font-size: 12px;
  letter-spacing: 0.28em;
  text-transform: uppercase;
  color: var(--qs-text-muted);
}

.settings-workspace__title {
  margin: 0;
  font-size: 42px;
  font-weight: 700;
  letter-spacing: 0.05em;
}

.settings-workspace__language-block {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.settings-workspace__language-label {
  font-size: 12px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: rgba(170, 188, 214, 0.82);
}

.settings-workspace__language-switch {
  display: inline-flex;
  gap: 8px;
  padding: 6px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(18, 30, 48, 0.82), rgba(8, 14, 25, 0.9));
  border: 1px solid rgba(146, 176, 222, 0.16);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.settings-workspace__language-button {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 12px;
  border: 0;
  border-radius: 999px;
  background: transparent;
  color: rgba(198, 210, 227, 0.88);
  cursor: pointer;
  transition: background 0.18s ease, color 0.18s ease;
}

.settings-workspace__language-button--active {
  background: rgba(69, 120, 197, 0.34);
  color: rgba(244, 248, 252, 0.96);
}

.settings-workspace__status {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 10px;
  max-width: 100%;
}

.settings-workspace__status-chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  border-radius: 999px;
  background: linear-gradient(180deg, rgba(18, 30, 48, 0.82), rgba(8, 14, 25, 0.9));
  border: 1px solid rgba(146, 176, 222, 0.16);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(14px);
  font-size: 13px;
}

.settings-workspace__status-chip strong {
  font-weight: 600;
  color: rgba(245, 249, 255, 0.94);
}

.settings-workspace__status-chip span {
  color: rgba(198, 210, 227, 0.88);
}

.settings-workspace__panel {
  flex: 1 1 auto;
  min-height: 0;
  padding: 24px 26px 26px;
  border-radius: 34px;
  border: 1px solid rgba(157, 185, 228, 0.16);
  background:
    radial-gradient(circle at 50% 0%, rgba(113, 163, 247, 0.08), transparent 22%),
    linear-gradient(180deg, rgba(16, 26, 44, 0.96) 0%, rgba(9, 16, 29, 0.94) 100%);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 -24px 38px rgba(3, 8, 14, 0.26),
    0 30px 70px rgba(0, 0, 0, 0.26);
  display: flex;
  flex-direction: column;
  gap: 20px;
  overflow-y: auto;
  overscroll-behavior: contain;
  scrollbar-gutter: stable;
}

.settings-workspace__section {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.settings-workspace__section-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 16px;
}

.settings-workspace__section-head h3 {
  margin: 0;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.settings-workspace__section-head span {
  font-size: 12px;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: rgba(156, 176, 209, 0.72);
}

.settings-workspace__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
}

.settings-workspace__grid--compact {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.settings-workspace__card {
  min-height: 116px;
  padding: 18px 18px 16px;
  border: 1px solid rgba(145, 175, 221, 0.14);
  border-radius: 22px;
  background:
    linear-gradient(180deg, rgba(29, 46, 74, 0.92) 0%, rgba(15, 24, 39, 0.94) 100%);
  color: rgba(245, 248, 252, 0.96);
  text-align: left;
  cursor: pointer;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 -14px 24px rgba(3, 8, 14, 0.18);
  transition: transform 0.18s ease, border-color 0.18s ease, box-shadow 0.18s ease;
}

.settings-workspace__card:hover {
  transform: translateY(-2px);
  border-color: rgba(155, 197, 255, 0.3);
  box-shadow: 0 18px 32px rgba(4, 11, 20, 0.22);
}

.settings-workspace__card--active {
  border-color: rgba(126, 179, 255, 0.44);
  box-shadow:
    inset 0 0 0 1px rgba(126, 179, 255, 0.18),
    0 18px 36px rgba(16, 34, 66, 0.3);
}

.settings-workspace__card--compact {
  min-height: 96px;
}

.settings-workspace__card-head {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 10px;
}

.settings-workspace__card-icon {
  width: 40px;
  height: 40px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  border-radius: 14px;
  background: linear-gradient(180deg, rgba(255, 255, 255, 0.12), rgba(96, 134, 201, 0.12));
  color: rgba(214, 231, 255, 0.96);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    0 10px 16px rgba(4, 10, 18, 0.16);
}

.settings-workspace__card-title {
  display: block;
  font-size: 18px;
  font-weight: 600;
}

.settings-workspace__card-desc {
  display: block;
  font-size: 13px;
  line-height: 1.5;
  color: rgba(201, 213, 228, 0.86);
}

@media (max-width: 1400px) {
  .settings-workspace__header {
    flex-direction: column;
  }

  .settings-workspace__header-tools {
    align-items: stretch;
    max-width: none;
  }

  .settings-workspace__language-block {
    align-items: flex-start;
  }

  .settings-workspace__status {
    justify-content: flex-start;
  }

  .settings-workspace__grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}
</style>

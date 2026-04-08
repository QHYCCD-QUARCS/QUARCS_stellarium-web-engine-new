<template>
  <v-dialog
    :value="visible"
    attach="body"
    max-width="1180"
    :fullscreen="isCompactScreen"
    scrollable
    overlay-color="rgba(3, 8, 18, 0.92)"
    overlay-opacity="0.72"
    @input="handleDialogInput"
  >
    <v-card class="shell-device-dialog">
      <header class="shell-device-dialog__header">
        <div>
          <p class="shell-device-dialog__eyebrow">{{ $t('Device Connection') }}</p>
          <h2 class="shell-device-dialog__title">{{ displayName || driverType || 'Device' }}</h2>
        </div>
        <div class="shell-device-dialog__header-actions">
          <span
            class="shell-device-dialog__status"
            :class="connected ? 'shell-device-dialog__status--online' : 'shell-device-dialog__status--offline'"
          >
            <v-icon small>{{ connected ? 'mdi-check-circle-outline' : 'mdi-link-off' }}</v-icon>
            <span>{{ connected ? $t('Connected') : $t('Disconnected') }}</span>
          </span>
          <button type="button" class="shell-device-dialog__close" @click="$emit('close')">
            <v-icon>mdi-close</v-icon>
          </button>
        </div>
      </header>

      <div class="shell-device-dialog__body">
        <section class="shell-device-dialog__side">
          <div class="shell-device-dialog__panel">
            <div class="shell-device-dialog__panel-head">
              <h3>{{ $t('ShellSettingsDeviceSection') }}</h3>
              <span>{{ $t('ShellSettingsConnection') }}</span>
            </div>

            <div class="shell-device-dialog__summary">
              <div class="shell-device-dialog__summary-item">
                <span class="shell-device-dialog__summary-label">{{ $t('Driver') }}</span>
                <strong>{{ selectedDriver || '--' }}</strong>
              </div>
              <div class="shell-device-dialog__summary-item">
                <span class="shell-device-dialog__summary-label">{{ $t('Connection Mode') }}</span>
                <strong>{{ selectedConnectionMode || 'INDI' }}</strong>
              </div>
              <div class="shell-device-dialog__summary-item">
                <span class="shell-device-dialog__summary-label">{{ $t('Device') }}</span>
                <strong>{{ boundDeviceName || '--' }}</strong>
              </div>
            </div>

            <div v-if="supportsConnectionControls" class="shell-device-dialog__controls">
              <v-select
                dense
                outlined
                hide-details="auto"
                class="shell-device-dialog__field"
                :label="$t('Select Driver')"
                :items="driverOptions"
                item-text="label"
                item-value="value"
                :value="selectedDriver"
                @change="emitAction('select-driver', { value: $event })"
              />

              <v-select
                v-if="showConnectionModeSelector"
                dense
                outlined
                hide-details="auto"
                class="shell-device-dialog__field"
                :label="$t('Connection Mode')"
                :items="connectionModeOptions"
                item-text="label"
                item-value="value"
                item-disabled="disabled"
                :value="selectedConnectionMode"
                @change="emitAction('select-connection-mode', { value: $event })"
              />

              <div class="shell-device-dialog__field-row">
                <v-select
                  v-if="showBaudRateSelector"
                  dense
                  outlined
                  hide-details="auto"
                  class="shell-device-dialog__field"
                  :label="$t('Baud Rate')"
                  :items="baudRateItems"
                  item-text="label"
                  item-value="value"
                  :value="selectedBaudRate"
                  @change="emitAction('select-baud-rate', { value: $event })"
                />

                <v-select
                  v-if="serialPortItems.length"
                  dense
                  outlined
                  hide-details="auto"
                  class="shell-device-dialog__field"
                  :label="$t('Serial Port')"
                  :items="serialPortItems"
                  item-text="label"
                  item-value="value"
                  :value="selectedSerialPort"
                  @change="emitAction('select-serial-port', { value: $event })"
                />
              </div>

              <div class="shell-device-dialog__cta">
                <v-btn
                  text
                  color="grey lighten-2"
                  class="shell-device-dialog__cta-btn"
                  @click="emitAction('clear-driver')"
                >
                  {{ $t('Clear') }}
                </v-btn>
                <v-btn
                  depressed
                  color="primary"
                  class="shell-device-dialog__cta-btn"
                  :loading="isConnecting"
                  @click="emitAction(connected ? 'disconnect' : 'connect')"
                >
                  {{ connected ? $t('Disconnect') : $t('Connect') }}
                </v-btn>
              </div>
            </div>

            <div v-else class="shell-device-dialog__hint">
              {{ $t('Device Config Items') }}
            </div>

            <div v-if="isUnbound" class="shell-device-dialog__notice">
              <v-icon small color="#f6c96b">mdi-alert-circle-outline</v-icon>
              <span>{{ $t('Not Bind Device') }}</span>
            </div>
          </div>
        </section>

        <section class="shell-device-dialog__main">
          <div class="shell-device-dialog__panel shell-device-dialog__panel--config">
            <div class="shell-device-dialog__panel-head">
              <h3>{{ $t('Device Config Items') }}</h3>
              <span>{{ normalizedConfigItems.length }} ITEM</span>
            </div>

            <div v-if="normalizedConfigItems.length && connected" class="shell-device-dialog__config-grid">
              <div
                v-for="item in normalizedConfigItems"
                :key="keyFor(item)"
                class="shell-device-dialog__config-card"
              >
                <div class="shell-device-dialog__config-title">{{ translated(item.label) }}</div>

                <v-text-field
                  v-if="item.inputType === 'text' || item.inputType === 'number'"
                  dense
                  outlined
                  hide-details="auto"
                  class="shell-device-dialog__field"
                  :type="item.inputType === 'number' ? 'number' : 'text'"
                  :value="draftValue(item)"
                  :disabled="isConfigDisabled"
                  @input="setDraftValue(item, $event)"
                  @blur="commitDraftValue(item)"
                  @keydown.enter.prevent="commitDraftValue(item)"
                />

                <div v-else-if="item.inputType === 'slider'" class="shell-device-dialog__slider-wrap">
                  <div class="shell-device-dialog__slider-meta">
                    <span>{{ sliderMin(item) }}</span>
                    <strong>{{ draftValue(item) }}</strong>
                    <span>{{ sliderMax(item) }}</span>
                  </div>
                  <v-slider
                    dense
                    hide-details
                    thumb-label
                    color="primary"
                    :min="sliderMin(item)"
                    :max="sliderMax(item)"
                    :step="sliderStep(item)"
                    :value="numberDraftValue(item)"
                    :disabled="isConfigDisabled"
                    @change="commitDirectValue(item, $event)"
                  />
                </div>

                <v-select
                  v-else-if="item.inputType === 'select'"
                  dense
                  outlined
                  hide-details="auto"
                  class="shell-device-dialog__field"
                  :items="normalizeSelectOptions(item.selectValue)"
                  item-text="label"
                  item-value="value"
                  :value="draftValue(item)"
                  :disabled="isConfigDisabled"
                  @change="commitDirectValue(item, $event)"
                />

                <v-switch
                  v-else-if="item.inputType === 'switch'"
                  inset
                  dense
                  hide-details="auto"
                  color="primary"
                  class="shell-device-dialog__switch"
                  :input-value="!!draftValue(item)"
                  :disabled="isConfigDisabled"
                  @change="commitDirectValue(item, $event)"
                />

                <div v-else-if="item.inputType === 'tip'" class="shell-device-dialog__tip">
                  {{ formatValue(item.value) }}
                </div>

                <v-btn
                  v-else-if="item.inputType === 'button'"
                  block
                  depressed
                  color="primary"
                  class="shell-device-dialog__config-button"
                  :disabled="isConfigDisabled || !!item._disabled"
                  :loading="!!item._disabled"
                  @click="emitAction('config-button', { item })"
                >
                  {{ translated(item.buttonText || item.label) }}
                </v-btn>

                <div v-else class="shell-device-dialog__tip">
                  {{ formatValue(item.value) }}
                </div>
              </div>
            </div>

            <div v-else class="shell-device-dialog__empty">
              <v-icon color="#7f9ac8">mdi-tune</v-icon>
              <p v-if="connected">{{ $t('No data') }}</p>
              <p v-else>{{ $t('Connect') }} {{ displayName || driverType || 'device' }} {{ $t('first') }}</p>
            </div>
          </div>
        </section>
      </div>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  name: 'ShellDeviceDialog',
  props: {
    visible: {
      type: Boolean,
      default: false
    },
    driverType: {
      type: String,
      default: ''
    },
    displayName: {
      type: String,
      default: ''
    },
    connected: {
      type: Boolean,
      default: false
    },
    supportsConnectionControls: {
      type: Boolean,
      default: true
    },
    drivers: {
      type: Array,
      default: () => []
    },
    selectedDriver: {
      type: [String, Number, null],
      default: ''
    },
    showConnectionModeSelector: {
      type: Boolean,
      default: false
    },
    connectionModeItems: {
      type: Array,
      default: () => []
    },
    selectedConnectionMode: {
      type: String,
      default: 'INDI'
    },
    baudRateItems: {
      type: Array,
      default: () => []
    },
    selectedBaudRate: {
      type: [String, Number],
      default: ''
    },
    serialPortItems: {
      type: Array,
      default: () => []
    },
    selectedSerialPort: {
      type: String,
      default: 'default'
    },
    isConnecting: {
      type: Boolean,
      default: false
    },
    boundDeviceName: {
      type: String,
      default: ''
    },
    isUnbound: {
      type: Boolean,
      default: false
    },
    configItems: {
      type: Array,
      default: () => []
    }
  },
  data () {
    return {
      viewportWidth: typeof window !== 'undefined' ? window.innerWidth : 1440,
      draftValues: {}
    }
  },
  computed: {
    driverOptions () {
      return Array.isArray(this.drivers) ? this.drivers : []
    },
    connectionModeOptions () {
      return Array.isArray(this.connectionModeItems) ? this.connectionModeItems : []
    },
    normalizedConfigItems () {
      return Array.isArray(this.configItems) ? this.configItems : []
    },
    showBaudRateSelector () {
      return this.driverType === 'Mount' || this.driverType === 'Focuser'
    },
    isConfigDisabled () {
      return !this.connected || this.isUnbound
    },
    isCompactScreen () {
      return this.viewportWidth <= 640
    }
  },
  watch: {
    configItems: {
      immediate: true,
      deep: true,
      handler (items) {
        const next = {}
        ;(items || []).forEach((item) => {
          next[this.keyFor(item)] = item.value
        })
        this.draftValues = next
      }
    }
  },
  methods: {
    translated (text) {
      return this.$t(text)
    },
    handleDialogInput (value) {
      if (!value) this.$emit('close')
    },
    emitAction (type, payload = {}) {
      this.$emit('action', {
        type,
        driverType: this.driverType,
        ...payload
      })
    },
    keyFor (item) {
      return `${item.driverType || this.driverType}:${item.index}:${item.label || 'item'}`
    },
    draftValue (item) {
      const key = this.keyFor(item)
      return Object.prototype.hasOwnProperty.call(this.draftValues, key)
        ? this.draftValues[key]
        : item.value
    },
    numberDraftValue (item) {
      const value = Number(this.draftValue(item))
      return Number.isFinite(value) ? value : this.sliderMin(item)
    },
    setDraftValue (item, value) {
      this.$set(this.draftValues, this.keyFor(item), value)
    },
    commitDraftValue (item) {
      this.emitAction('config-change', {
        item,
        value: this.draftValue(item)
      })
    },
    commitDirectValue (item, value) {
      this.setDraftValue(item, value)
      this.emitAction('config-change', { item, value })
    },
    normalizeSelectOptions (values) {
      return (values || []).map((entry) => {
        if (entry && typeof entry === 'object') {
          return {
            label: entry.label || entry.value,
            value: entry.value
          }
        }
        return {
          label: String(entry),
          value: entry
        }
      })
    },
    sliderMin (item) {
      return Number(item.inputMin != null ? item.inputMin : item.min != null ? item.min : 0)
    },
    sliderMax (item) {
      return Number(item.inputMax != null ? item.inputMax : item.max != null ? item.max : 100)
    },
    sliderStep (item) {
      return Number(item.inputStep != null ? item.inputStep : item.step != null ? item.step : 1)
    },
    formatValue (value) {
      if (Array.isArray(value)) return value.join(', ')
      if (value === undefined || value === null || value === '') return '--'
      if (typeof value === 'object') return JSON.stringify(value)
      return String(value)
    },
    updateViewportWidth () {
      this.viewportWidth = typeof window !== 'undefined' ? window.innerWidth : 1440
    }
  },
  mounted () {
    window.addEventListener('resize', this.updateViewportWidth, { passive: true })
    this.updateViewportWidth()
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.updateViewportWidth)
  }
}
</script>

<style scoped>
.shell-device-dialog {
  border-radius: 28px;
  border: 1px solid rgba(149, 182, 230, 0.14);
  background:
    radial-gradient(circle at top, rgba(55, 92, 150, 0.24), transparent 32%),
    linear-gradient(180deg, rgba(7, 14, 27, 0.98) 0%, rgba(4, 10, 20, 0.98) 100%);
  color: rgba(244, 248, 252, 0.96);
  box-shadow:
    0 32px 90px rgba(0, 0, 0, 0.42),
    inset 0 1px 0 rgba(255, 255, 255, 0.08);
}

.shell-device-dialog__header {
  display: flex;
  justify-content: space-between;
  gap: 16px;
  padding: 24px 26px 18px;
  border-bottom: 1px solid rgba(149, 182, 230, 0.12);
}

.shell-device-dialog__eyebrow {
  margin: 0 0 6px;
  font-size: 11px;
  letter-spacing: 0.22em;
  text-transform: uppercase;
  color: rgba(167, 187, 217, 0.74);
}

.shell-device-dialog__title {
  margin: 0;
  font-size: 30px;
  line-height: 1.1;
}

.shell-device-dialog__header-actions {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.shell-device-dialog__status {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  border-radius: 999px;
  font-size: 13px;
  background: rgba(13, 23, 40, 0.8);
  border: 1px solid rgba(149, 182, 230, 0.12);
}

.shell-device-dialog__status--online {
  color: rgba(127, 235, 178, 0.96);
}

.shell-device-dialog__status--offline {
  color: rgba(246, 200, 133, 0.96);
}

.shell-device-dialog__close {
  width: 42px;
  height: 42px;
  border: 0;
  border-radius: 14px;
  background: rgba(13, 23, 40, 0.8);
  color: rgba(235, 241, 248, 0.94);
}

.shell-device-dialog__body {
  display: grid;
  grid-template-columns: 320px minmax(0, 1fr);
  gap: 18px;
  padding: 22px 26px 26px;
  max-height: min(78vh, 860px);
}

.shell-device-dialog__side,
.shell-device-dialog__main {
  min-width: 0;
}

.shell-device-dialog__panel {
  height: 100%;
  padding: 18px;
  border-radius: 24px;
  border: 1px solid rgba(149, 182, 230, 0.12);
  background: rgba(10, 19, 34, 0.84);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
}

.shell-device-dialog__panel--config {
  display: flex;
  flex-direction: column;
  min-height: 0;
}

.shell-device-dialog__panel-head {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 12px;
  margin-bottom: 16px;
}

.shell-device-dialog__panel-head h3 {
  margin: 0;
  font-size: 17px;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.shell-device-dialog__panel-head span {
  font-size: 11px;
  letter-spacing: 0.16em;
  color: rgba(166, 185, 214, 0.68);
}

.shell-device-dialog__summary {
  display: grid;
  gap: 10px;
  margin-bottom: 16px;
}

.shell-device-dialog__summary-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px 14px;
  border-radius: 18px;
  background: rgba(20, 33, 57, 0.78);
}

.shell-device-dialog__summary-label {
  font-size: 11px;
  letter-spacing: 0.14em;
  text-transform: uppercase;
  color: rgba(166, 185, 214, 0.66);
}

.shell-device-dialog__controls {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.shell-device-dialog__field-row {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.shell-device-dialog__cta {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.shell-device-dialog__cta-btn {
  border-radius: 14px;
  min-height: 44px;
}

.shell-device-dialog__notice,
.shell-device-dialog__hint {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 14px;
  font-size: 13px;
  color: rgba(209, 220, 236, 0.8);
}

.shell-device-dialog__config-grid {
  flex: 1 1 auto;
  min-height: 0;
  overflow-y: auto;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px;
  padding-right: 6px;
}

.shell-device-dialog__config-card {
  padding: 14px 14px 12px;
  border-radius: 18px;
  background: rgba(17, 29, 50, 0.86);
  border: 1px solid rgba(149, 182, 230, 0.1);
}

.shell-device-dialog__config-title {
  margin-bottom: 10px;
  font-size: 13px;
  font-weight: 600;
  color: rgba(238, 243, 250, 0.96);
}

.shell-device-dialog__slider-wrap {
  padding-top: 2px;
}

.shell-device-dialog__slider-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 6px;
  font-size: 12px;
  color: rgba(198, 210, 227, 0.82);
}

.shell-device-dialog__tip {
  min-height: 42px;
  display: flex;
  align-items: center;
  padding: 10px 12px;
  border-radius: 14px;
  background: rgba(8, 17, 29, 0.72);
  color: rgba(214, 224, 237, 0.82);
  word-break: break-word;
}

.shell-device-dialog__config-button {
  border-radius: 14px;
}

.shell-device-dialog__empty {
  flex: 1 1 auto;
  min-height: 220px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14px;
  color: rgba(171, 189, 216, 0.72);
  text-align: center;
}

@media (max-width: 960px) {
  .shell-device-dialog__body {
    grid-template-columns: 1fr;
    max-height: 80vh;
  }

  .shell-device-dialog__config-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .shell-device-dialog__header {
    padding: 18px 18px 14px;
  }

  .shell-device-dialog__title {
    font-size: 24px;
  }

  .shell-device-dialog__body {
    gap: 14px;
    padding: 16px 18px 18px;
  }

  .shell-device-dialog__field-row,
  .shell-device-dialog__cta {
    grid-template-columns: 1fr;
  }
}
</style>

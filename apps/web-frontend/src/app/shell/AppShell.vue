<template>
  <div class="app-shell">
    <div class="app-shell__viewport">
      <div class="app-shell__stage" :style="stageStyle">
        <TopBar
          class="app-shell__top"
          :title="topBarTitle"
          :subtitle="connectionSummary"
          :primary-actions="topBarPrimaryActions"
          :secondary-actions="topBarSecondaryActions"
          :active-action-ids="activeTopActionIds"
          @top-action="handleTopAction"
        />
        <TargetSearch
          v-show="showCompactSearch"
          class="app-shell__search"
        />
        <div class="app-shell__stage-frame" :class="{ 'app-shell__stage-frame--hidden': legacyOverlayOpen }">
          <span class="control-tag">App-Panel</span>
        </div>
        <div v-if="isSettingsMode" class="app-shell__settings-backdrop"></div>

        <!-- Van Gogh Starry Night background for camera / guiding / focus modes -->
        <transition name="art-bg-fade">
          <div
            v-if="!isSettingsMode && !legacyOverlayOpen && ['capture','guiding','focus'].includes(currentMode)"
            class="app-shell__art-bg"
          ></div>
        </transition>

        <!-- QUARCS branding overlay — always on top of art-bg -->
        <div
          v-if="!isSettingsMode && !legacyOverlayOpen && ['capture','guiding','focus'].includes(currentMode)"
          class="app-shell__quarcs-brand"
        >
          <img src="@/assets/images/logo.svg" class="app-shell__quarcs-brand-logo" alt="" />
          <span class="app-shell__quarcs-brand-text">QUARCS</span>
        </div>

        <div class="app-shell__body" :class="{ 'app-shell__body--hidden': legacyOverlayOpen }">
          <LeftControlWing
            class="app-shell__left"
            :active-mode="currentMode"
            :hero-title="leftHeroTitle"
            :hero-eyebrow="leftHeroEyebrow"
            :primary-modes="primaryModes"
            :action-items="leftActions"
            :footer-left="leftFooterButtons.left"
            :footer-right="leftFooterButtons.right"
            :footer-action="leftFooterButtons.action"
            :dock-expanded="dockExpanded"
            @hero-action="handleLeftHeroAction"
            @set-mode="setMode"
            @left-action="handleLeftAction"
            @footer-press="handleFooterPress"
            @footer-release="handleFooterRelease"
            @footer-action="handleFooterAction"
          />
          <CenterConsole
            v-if="!isSettingsMode"
            class="app-shell__center"
            :topline="centerTopline"
            :object-title="selectedObjectTitle"
            :object-line1="selectedObjectLine1"
            :object-line2="selectedObjectLine2"
            :connection-label="connectionSummary"
            :guide-title="guideTitle"
            :guide-line1="guideLine1"
            :guide-line2="guideLine2"
            :guide-line3="guideLine3"
            :guide-line4="guideLine4"
          />
          <SettingsWorkspace
            v-else
            class="app-shell__center app-shell__center--settings"
            :summary-items="settingsSummaryItems"
            :device-actions="settingsDeviceActions"
            :quick-actions="settingsQuickActions"
            :advanced-actions="settingsAdvancedActions"
            :active-action-ids="activeSettingActionIds"
            :language-options="shellLanguageOptions"
            :selected-language="$i18n.locale"
            @device-action="handleSettingsQuickAction"
            @quick-action="handleSettingsQuickAction"
            @language-change="switchShellLanguage"
          />
          <RightControlWing
            class="app-shell__right"
            :hero-title="rightHeroTitle"
            :hero-eyebrow="rightHeroEyebrow"
            :action-items="rightActions"
            :tool-items="rightTools"
            :status-items="rightStatusItems"
            :footer-left="rightFooterButtons.left"
            :footer-right="rightFooterButtons.right"
            :footer-action="rightFooterButtons.action"
            :dock-expanded="dockExpanded"
            @hero-action="handleHeroAction"
            @right-action="handleRightAction"
            @tool-action="handleToolAction"
            @footer-press="handleFooterPress"
            @footer-release="handleFooterRelease"
            @footer-action="handleFooterAction"
          />
        </div>

        <div class="app-shell__overlay-layer" :class="{ 'app-shell__overlay-layer--hidden': legacyOverlayOpen }">
          <div
            v-if="currentMode === 'mount' && !isSettingsMode"
            class="app-shell__mount-brand"
          >
            <span class="app-shell__mount-brand-text">QUARCS</span>
            <span class="app-shell__mount-brand-sub">Sky + Mount Control</span>
          </div>
          <ChartComponent
            v-show="guidingPanelVisible"
            ref="guidingPanel"
            class="app-shell__overlay-panel app-shell__overlay-panel--guiding"
          />
          <HistogramPanel
            v-show="histogramPanelVisible"
            ref="histogramPanel"
            class="app-shell__overlay-panel app-shell__overlay-panel--capture"
          />
          <FocuserPanel
            v-show="focuserPanelVisible"
            ref="focuserPanel"
            class="app-shell__overlay-panel app-shell__overlay-panel--focus"
          />
          <AutomaticPolarAlignmentCalibration
            :visible.sync="polarAlignmentVisible"
            :auto-start="false"
          />
        </div>

        <div class="app-shell__aux-layer">
          <DateTimePicker
            v-show="showDateTimePicker"
            v-model="pickerDate"
            :location="$store.state.currentLocation"
            class="app-shell__aux app-shell__aux--datetime"
          />
          <ImageManagerPanel
            ref="imageManagerPanel"
            v-show="showImageManagerPanel"
            :is-open="showImageManagerPanel"
            class="app-shell__aux"
          />
          <DeviceAllocationPanel
            ref="deviceAllocationPanel"
            v-show="showDeviceAllocationPanel"
            :is-open="showDeviceAllocationPanel"
            class="app-shell__aux"
          />
          <INDIDebugDialog
            ref="indiDebugDialog"
            v-show="showINDIDebugDialog"
            :is-open="showINDIDebugDialog"
            class="app-shell__aux"
          />
          <RPIHotspotDialog
            v-show="showRPIHotspotDialog"
            class="app-shell__aux"
          />
          <SchedulePanel
            ref="schedulePanel"
            v-show="showSchedulePanel"
            :is-open="showSchedulePanel"
            class="app-shell__aux app-shell__aux--schedule"
          />
        </div>

        <ShellDeviceDialog
          :visible="deviceDialog.visible"
          :driver-type="deviceDialog.driverType"
          :display-name="deviceDialog.displayName"
          :connected="deviceDialog.connected"
          :supports-connection-controls="deviceDialog.supportsConnectionControls"
          :drivers="deviceDialog.drivers"
          :selected-driver="deviceDialog.selectedDriver"
          :show-connection-mode-selector="deviceDialog.showConnectionModeSelector"
          :connection-mode-items="deviceDialog.connectionModeItems"
          :selected-connection-mode="deviceDialog.selectedConnectionMode"
          :baud-rate-items="deviceDialog.baudRateItems"
          :selected-baud-rate="deviceDialog.selectedBaudRate"
          :serial-port-items="deviceDialog.serialPortItems"
          :selected-serial-port="deviceDialog.selectedSerialPort"
          :is-connecting="deviceDialog.isConnecting"
          :bound-device-name="deviceDialog.boundDeviceName"
          :is-unbound="deviceDialog.isUnbound"
          :config-items="deviceDialog.configItems"
          @close="closeShellDeviceDialog"
          @action="handleShellDeviceDialogAction"
        />

        <div class="app-shell__legacy-adapters" aria-hidden="true">
          <CapturePanel ref="capturePanel" />
          <MountControlPanel ref="mountPanel" />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import CenterConsole from './CenterConsole.vue'
import LeftControlWing from './LeftControlWing.vue'
import RightControlWing from './RightControlWing.vue'
import SettingsWorkspace from './SettingsWorkspace.vue'
import ShellDeviceDialog from './ShellDeviceDialog.vue'
import TopBar from './TopBar.vue'
import CapturePanel from '@/components/CapturePanel.vue'
import ChartComponent from '@/components/ChartComponent.vue'
import FocuserPanel from '@/components/FocuserPanel.vue'
import HistogramPanel from '@/components/HistogramPanel.vue'
import MountControlPanel from '@/components/MountControlPanel.vue'
import AutomaticPolarAlignmentCalibration from '@/components/AutomaticPolarAlignmentCalibration.vue'
import DateTimePicker from '@/components/date-time-picker.vue'
import DeviceAllocationPanel from '@/components/DeviceAllocationPanel.vue'
import ImageManagerPanel from '@/components/ImageManagerPanel.vue'
import INDIDebugDialog from '@/components/indiDebugDialog.vue'
import RPIHotspotDialog from '@/components/RPI-Hotspot.vue'
import SchedulePanel from '@/components/SchedulePanel.vue'
import TargetSearch from '@/components/target-search.vue'

export default {
  name: 'AppShell',
  data () {
    return {
      designMinWidth: 1600,
      designHeight: 900,
      stageWidth: 1600,
      shellScale: 1,
      currentMode: 'mount',
      dockTab: 'guiding',
      dockExpanded: false,
      polarAlignmentVisible: false,
      pickerDate: new Date().toISOString(),
      showSchedulePanel: false,
      showImageManagerPanel: false,
      showDeviceAllocationPanel: false,
      showINDIDebugDialog: false,
      showRPIHotspotDialog: false,
      showDateTimePicker: false,
      mountConnected: false,
      mainCameraConnected: false,
      guiderConnected: false,
      focuserConnected: false,
      cfwConnected: false,
      mountTracking: false,
      mountParked: false,
      mountMoving: false,
      mountSpeed: 1,
      mountLocationText: '-- / --',
      captureInProgress: false,
      captureExpTimeLabel: '1s',
      currentFilterLabel: 'Null',
      guiderLoopActive: false,
      guiderActive: false,
      guiderStatusText: 'Idle',
      guiderExpTimeMs: 1000,
      focuserSpeedText: '1',
      focuserRoiText: '300',
      focuserPositionText: '0',
      focuserFwhmText: '--',
      focuserAutoActive: false,
      focuserBusy: false,
      guiderError: false,
      networkConnected: true,
      batteryLevel: null,
      batteryCharging: false,
      batteryManager: null,
      selectedObjectFallback: 'No Target',
      deviceDialog: {
        visible: false,
        driverType: '',
        displayName: '',
        connected: false,
        supportsConnectionControls: true,
        drivers: [],
        selectedDriver: '',
        showConnectionModeSelector: false,
        connectionModeItems: [],
        selectedConnectionMode: 'INDI',
        baudRateItems: [],
        selectedBaudRate: '',
        serialPortItems: [],
        selectedSerialPort: 'default',
        isConnecting: false,
        boundDeviceName: '',
        isUnbound: false,
        configItems: []
      },
      busListeners: []
    }
  },
  computed: {
    stageStyle () {
      return {
        width: `${this.stageWidth}px`,
        height: `${this.designHeight}px`,
        transform: `scale(${this.shellScale})`
      }
    },
    primaryModes () {
      return [
        { id: 'mount', label: 'EQ', tag: 'L-Mode-1' },
        { id: 'capture', label: 'CAM', tag: 'L-Mode-2' },
        { id: 'guiding', label: 'GUI', tag: 'L-Mode-3' },
        { id: 'focus', label: 'FOC', tag: 'L-Mode-4' },
        { id: 'settings', label: 'SET', tag: 'L-Mode-5' }
      ]
    },
    modeOrder () {
      return this.primaryModes.map((item) => item.id)
    },
    isSettingsMode () {
      return this.currentMode === 'settings'
    },
    topBarTitle () {
      return `QUARCS ${this.modeLabel}`
    },
    modeLabel () {
      const map = {
        mount: 'Sky + Mount',
        capture: 'Capture',
        guiding: 'Guiding',
        focus: 'Focusing',
        settings: 'Settings'
      }
      return map[this.currentMode] || 'Control'
    },
    topBarPrimaryActions () {
      return []
    },
    topBarSecondaryActions () {
      return []
    },
    activeTopActionIds () {
      const active = []
      if (this.$store.state.showNavigationDrawer) active.push('top-devices')
      if (this.$store.state.showViewSettingsDialog) active.push('top-settings')
      if (this.showSchedulePanel) active.push('top-schedule')
      if (this.showImageManagerPanel) active.push('top-files')
      if (this.showDeviceAllocationPanel) active.push('top-allocate')
      if (this.showINDIDebugDialog) active.push('top-debug')
      if (this.showDateTimePicker) active.push('top-time')
      if (this.showRPIHotspotDialog) active.push('top-hotspot')
      if (this.$store.state.showLocationDialog) active.push('top-location')
      return active
    },
    activeSettingActionIds () {
      const active = this.activeTopActionIds.slice()
      if (this.polarAlignmentVisible) active.push('settings-polar-align')
      return active
    },
    showCompactSearch () {
      return !this.isSettingsMode && !this.legacyOverlayOpen
    },
    legacyOverlayOpen () {
      const state = this.$store && this.$store.state ? this.$store.state : {}
      return !!(
        state.showNavigationDrawer ||
        state.showViewSettingsDialog ||
        state.showLocationDialog ||
        state.showDeviceSettingsDialog_CFW ||
        state.showDeviceSettingsDialog_Focuser ||
        state.showDeviceSettingsDialog_Guider ||
        state.showDeviceSettingsDialog_MainCamera ||
        state.showDeviceSettingsDialog_Mount ||
        state.showDeviceSettingsDialog_PoleCamera ||
        state.showUSBFilesDialog
      )
    },
    leftHeroTitle () {
      return this.modeLabel
    },
    leftHeroEyebrow () {
      return 'Mode'
    },
    rightHeroTitle () {
      if (this.currentMode === 'capture') {
        return this.captureInProgress ? 'Abort' : 'Capture'
      }
      if (this.currentMode === 'guiding') {
        return this.guiderActive ? 'Stop Guide' : 'Start Guide'
      }
      if (this.currentMode === 'focus') {
        return this.focuserAutoActive ? 'Stop Focus' : 'Auto Focus'
      }
      if (this.currentMode === 'settings') {
        return this.polarAlignmentVisible ? 'Polar Open' : 'Polar Align'
      }
      return 'Mount Stop'
    },
    rightHeroEyebrow () {
      if (this.currentMode === 'mount') return 'Mount'
      if (this.currentMode === 'capture') return 'Shoot'
      if (this.currentMode === 'guiding') return 'Guide'
      if (this.currentMode === 'settings') return 'System'
      return 'Focus'
    },
    leftActions () {
      if (this.currentMode === 'settings') {
        return [
          { id: 'settings-device-main-camera', icon: 'mdi-camera-outline', title: this.$t('Main Camera'), tag: 'L-MainCam' },
          { id: 'settings-device-guider', icon: 'mdi-crosshairs-gps', title: this.$t('Guider'), tag: 'L-Guider' },
          { id: 'settings-device-mount', icon: 'mdi-satellite-variant', title: this.$t('Mount'), tag: 'L-Mount' }
        ]
      }
      if (this.currentMode === 'capture') {
        return [
          { id: 'capture-sync', icon: '◎', title: 'Sync', tag: 'L-Sync' },
          { id: 'capture-fwhm', icon: '◔', title: 'FWHM', tag: 'L-Fwhm' },
          { id: 'capture-focus', icon: '⊙', title: 'Focus', tag: 'L-Focus' }
        ]
      }
      if (this.currentMode === 'guiding') {
        return [
          { id: 'guiding-loop', icon: '↻', title: 'Loop', tag: 'L-Loop' },
          { id: 'guiding-range', icon: '↔', title: 'Range', tag: 'L-Range' },
          { id: 'guiding-clear', icon: '⌫', title: 'Clear', tag: 'L-Clear' }
        ]
      }
      if (this.currentMode === 'focus') {
        return [
          { id: 'focus-roi', icon: '▣', title: 'ROI', tag: 'L-ROI' },
          { id: 'focus-loop', icon: '↻', title: 'Loop', tag: 'L-Loop' },
          { id: 'focus-calibration', icon: '◎', title: 'Calib', tag: 'L-Calib' }
        ]
      }
      return [
        { id: 'mount-grid', icon: '#', title: 'Grid', tag: 'L-Grid' },
        { id: 'mount-dso', icon: '✦', title: 'DSO', tag: 'L-DSO' },
        { id: 'mount-constellation', icon: '☆', title: 'Const', tag: 'L-Const' }
      ]
    },
    rightActions () {
      if (this.currentMode === 'settings') {
        return [
          { id: 'settings-device-telescope', icon: 'mdi-telescope', label: 'SCOPE', tag: 'R-Scope' },
          { id: 'settings-device-focuser', icon: 'mdi-focus-field', label: 'FOC', tag: 'R-Foc' },
          { id: 'settings-device-cfw', icon: 'mdi-image-filter-center-focus-strong', label: 'CFW', tag: 'R-CFW' }
        ]
      }
      if (this.currentMode === 'capture') {
        return [
          { id: 'capture-exp', icon: 'mdi-progress-clock', label: 'EXP', tag: 'R-EXP' },
          { id: 'capture-filter', icon: 'mdi-image-filter-center-focus-strong', label: this.currentFilterLabel, tag: 'R-CFW' },
          { id: 'capture-save', icon: 'mdi-content-save-outline', label: 'SAVE', tag: 'R-Save' }
        ]
      }
      if (this.currentMode === 'guiding') {
        return [
          { id: 'guiding-loop', icon: 'mdi-refresh', label: this.guiderLoopActive ? 'Loop On' : 'Loop', tag: 'R-Loop' },
          { id: 'guiding-exp', icon: 'mdi-progress-clock', label: `${this.guiderExpTimeMs}ms`, tag: 'R-EXP' },
          { id: 'guiding-recalibrate', icon: 'mdi-radar', label: 'Recal', tag: 'R-Recal' }
        ]
      }
      if (this.currentMode === 'focus') {
        return [
          { id: 'focus-speed', icon: 'mdi-speedometer', label: `SPD ${this.focuserSpeedText}`, tag: 'R-Speed' },
          { id: 'focus-roi', icon: 'mdi-select-drag', label: `ROI ${this.focuserRoiText}`, tag: 'R-ROI' },
          { id: 'focus-calibration', icon: 'mdi-chart-bell-curve', label: 'Calib', tag: 'R-Calib' }
        ]
      }
      return [
        { id: 'mount-sync', icon: 'mdi-crosshairs-gps', label: 'SYNC', tag: 'R-Sync' },
        { id: 'mount-track', icon: 'mdi-axis-arrow', label: this.mountTracking ? 'Track On' : 'Track', tag: 'R-Track' },
        { id: 'mount-home', icon: 'mdi-home-map-marker', label: 'HOME', tag: 'R-Home' }
      ]
    },
    rightTools () {
      return []
    },
    rightStatusItems () {
      return [
        {
          id: 'main-camera',
          tag: 'R-Status-Cam',
          title: this.$t('Main Camera'),
          value: this.captureInProgress ? this.$t('Capturing') : (this.mainCameraConnected ? this.$t('Ready') : this.$t('Offline')),
          tone: this.captureInProgress ? 'busy' : (this.mainCameraConnected ? 'connected' : 'offline'),
          iconSrc: this.resolveMainCameraStatusIcon(),
          pillClass: ''
        },
        {
          id: 'mount',
          tag: 'R-Status-Mount',
          title: this.$t('Mount'),
          value: this.mountMoving ? this.$t('Slewing') : (this.mountTracking ? this.$t('Tracking') : (this.mountConnected ? this.$t('Ready') : this.$t('Offline'))),
          tone: this.mountMoving ? 'busy' : (this.mountConnected ? 'connected' : 'offline'),
          iconSrc: this.resolveMountStatusIcon(),
          pillClass: ''
        },
        {
          id: 'guider',
          tag: 'R-Status-Guide',
          title: this.$t('Guider'),
          value: this.guiderError ? this.$t('Alert') : this.guiderStatusLabel,
          tone: this.guiderError ? 'error' : this.guiderTone,
          iconSrc: this.resolveGuiderStatusIcon(),
          pillClass: ''
        },
        {
          id: 'focuser',
          tag: 'R-Status-Focus',
          title: this.$t('Focus'),
          value: this.focuserAutoActive ? this.$t('Auto') : (this.focuserBusy ? this.$t('Moving') : (this.focuserConnected ? this.$t('Ready') : this.$t('Offline'))),
          tone: (this.focuserBusy || this.focuserAutoActive) ? 'busy' : (this.focuserConnected ? 'connected' : 'offline'),
          iconSrc: this.resolveFocuserStatusIcon(),
          pillClass: ''
        },
        {
          id: 'wifi',
          tag: 'R-Status-WiFi',
          title: 'WiFi',
          value: this.networkConnected ? this.$t('Online') : this.$t('Offline'),
          tone: this.networkConnected ? 'connected' : 'offline',
          iconSrc: this.networkConnected
            ? require('@/assets/images/svg/ui/wifi.svg')
            : require('@/assets/images/svg/ui/wifi_off.svg'),
          pillClass: 'status-pill--clickable',
          actionId: 'top-hotspot'
        },
        {
          id: 'battery',
          tag: 'R-Status-Battery',
          title: this.$t('Battery'),
          value: this.batteryLabel,
          tone: this.batteryTone,
          icon: this.batteryIcon,
          iconClass: this.batteryIconClass,
          pillClass: ''
        }
      ]
    },
    leftFooterButtons () {
      if (this.currentMode === 'focus') {
        return {
          left: { id: 'focus-left-hold', label: 'F-', tag: 'L-Focus-' },
          right: { id: 'focus-left-step', label: 'S-', tag: 'L-Step-' },
          action: { id: 'focus-loop', label: 'Loop', tag: 'L-Loop' }
        }
      }
      return {
        left: { id: 'mount-ra-minus', label: 'RA-', tag: 'L-RA-' },
        right: { id: 'mount-dec-minus', label: 'DEC-', tag: 'L-DEC-' },
        action: { id: 'open-devices', label: 'Devices', tag: 'L-Devices' }
      }
    },
    rightFooterButtons () {
      if (this.currentMode === 'focus') {
        return {
          left: { id: 'focus-right-hold', label: 'F+', tag: 'R-Focus+' },
          right: { id: 'focus-right-step', label: 'S+', tag: 'R-Step+' },
          action: { id: 'focus-calibration', label: 'Calib', tag: 'R-Calib' }
        }
      }
      return {
        left: { id: 'mount-ra-plus', label: 'RA+', tag: 'R-RA+' },
        right: { id: 'mount-dec-plus', label: 'DEC+', tag: 'R-DEC+' },
        action: { id: 'switch-settings', label: 'Settings', tag: 'R-Settings' }
      }
    },
    selectedObject () {
      return this.$store && this.$store.state ? this.$store.state.selectedObject : undefined
    },
    selectedObjectTitle () {
      const object = this.selectedObject
      if (!object) return this.selectedObjectFallback
      if (object.names && object.names.length) return object.names[0]
      if (object.model_data && object.model_data.names && object.model_data.names.length) return object.model_data.names[0]
      if (object.designation) return object.designation
      if (object.name) return object.name
      return this.selectedObjectFallback
    },
    selectedObjectLine1 () {
      return `Mount: ${this.mountConnected ? 'Online' : 'Offline'} · Cam: ${this.mainCameraConnected ? 'Online' : 'Offline'}`
    },
    selectedObjectLine2 () {
      return `Mode: ${this.modeLabel} · Filter: ${this.currentFilterLabel}`
    },
    connectionSummary () {
      const labels = []
      if (this.mountConnected) labels.push('Mount')
      if (this.mainCameraConnected) labels.push('Cam')
      if (this.guiderConnected) labels.push('Guider')
      if (this.focuserConnected) labels.push('Focuser')
      if (this.cfwConnected) labels.push('CFW')
      return labels.length ? labels.join(' / ') : 'Offline'
    },
    centerTopline () {
      return this.currentMode === 'mount' ? 'QUARCS ASTRONOMY' : `QUARCS ${this.modeLabel.toUpperCase()}`
    },
    guideTitle () {
      if (this.currentMode === 'focus') return 'Focus Status'
      if (this.currentMode === 'settings') return 'System Status'
      return 'Guide Status'
    },
    guideLine1 () {
      if (this.currentMode === 'focus') return `Position: ${this.focuserPositionText}`
      if (this.currentMode === 'settings') return `Mount: ${this.mountConnected ? 'Online' : 'Offline'}`
      return `Guide: ${this.guiderStatusText}`
    },
    guideLine2 () {
      if (this.currentMode === 'focus') return `FWHM: ${this.focuserFwhmText}`
      if (this.currentMode === 'settings') return `Main Cam: ${this.mainCameraConnected ? 'Online' : 'Offline'}`
      return `Loop: ${this.guiderLoopActive ? 'On' : 'Off'}`
    },
    guideLine3 () {
      if (this.currentMode === 'focus') return `Speed: ${this.focuserSpeedText}`
      if (this.currentMode === 'settings') return `Location: ${this.mountLocationText}`
      return `Exp: ${this.guiderExpTimeMs} ms`
    },
    guideLine4 () {
      if (this.currentMode === 'focus') return `ROI: ${this.focuserRoiText}`
      if (this.currentMode === 'settings') return this.polarAlignmentVisible ? 'Polar: Running' : 'Polar: Ready'
      return `Track: ${this.mountTracking ? 'On' : 'Off'}`
    },
    settingsSummaryItems () {
      return [
        { label: this.$t('ShellSettingsConnection'), value: this.connectionSummary },
        { label: this.$t('ShellSettingsLocation'), value: this.mountLocationText },
        { label: this.$t('ShellSettingsFilter'), value: this.currentFilterLabel },
        { label: this.$t('ShellSettingsPolar'), value: this.polarAlignmentVisible ? this.$t('ShellOpen') : this.$t('ShellClosed') }
      ]
    },
    settingsDeviceActions () {
      return [
        {
          id: 'settings-connect-all',
          icon: 'mdi-link-variant',
          title: this.$t('Connect All'),
          description: this.$t('ShellSettingsConnectAllDescription')
        },
        {
          id: 'settings-disconnect-all',
          icon: 'mdi-link-off',
          title: this.$t('Disconnect All'),
          description: this.$t('ShellSettingsDisconnectAllDescription')
        },
        {
          id: 'top-allocate',
          icon: 'mdi-source-branch',
          title: this.$t('Device Allocation'),
          description: this.$t('ShellSettingsDeviceAllocationDescription')
        }
      ]
    },
    settingsQuickActions () {
      return [
        { id: 'top-settings', icon: 'mdi-cog-outline', title: this.$t('ShellSettingsGeneralSettings'), description: this.$t('ShellSettingsGeneralSettingsDescription') },
        { id: 'top-schedule', icon: 'mdi-calendar-clock-outline', title: this.$t('Schedule'), description: this.$t('ShellSettingsScheduleDescription') },
        { id: 'top-files', icon: 'mdi-folder-image', title: this.$t('Files'), description: this.$t('ShellSettingsFilesDescription') },
        { id: 'top-debug', icon: 'mdi-bug-outline', title: this.$t('ShellSettingsDebug'), description: this.$t('ShellSettingsDebugDescription') },
        { id: 'top-time', icon: 'mdi-clock-outline', title: this.$t('ShellSettingsTime'), description: this.$t('ShellSettingsTimeDescription') },
        { id: 'top-hotspot', icon: 'mdi-wifi', title: this.$t('ShellSettingsWifi'), description: this.$t('ShellSettingsWifiDescription') },
        { id: 'top-location', icon: 'mdi-map-marker-outline', title: this.$t('ShellSettingsLocationTitle'), description: this.$t('ShellSettingsLocationDescription') }
      ]
    },
    settingsAdvancedActions () {
      return [
        { id: 'settings-pole-camera', icon: 'mdi-camera-wireless-outline', title: this.$t('PoleCamera'), description: this.$t('ShellSettingsPoleCameraDescription') },
        { id: 'settings-polar-align', icon: 'mdi-compass-outline', title: this.$t('ShellSettingsPolarAlign'), description: this.$t('ShellSettingsPolarAlignDescription') }
      ]
    },
    shellLanguageOptions () {
      return [
        { text: 'English', value: 'en' },
        { text: '中文', value: 'cn' }
      ]
    },
    guidingPanelVisible () {
      return this.currentMode === 'guiding'
    },
    histogramPanelVisible () {
      return this.currentMode === 'capture'
    },
    focuserPanelVisible () {
      return this.currentMode === 'focus'
    },
    batteryIcon () {
      if (this.batteryLevel == null) return 'mdi-battery-unknown'
      const level = Math.round(this.batteryLevel * 100)
      if (this.batteryCharging) {
        if (level >= 90) return 'mdi-battery-charging-100'
        if (level >= 70) return 'mdi-battery-charging-80'
        if (level >= 50) return 'mdi-battery-charging-60'
        if (level >= 30) return 'mdi-battery-charging-40'
        return 'mdi-battery-charging-20'
      }
      if (level >= 95) return 'mdi-battery'
      if (level >= 85) return 'mdi-battery-90'
      if (level >= 75) return 'mdi-battery-80'
      if (level >= 65) return 'mdi-battery-70'
      if (level >= 55) return 'mdi-battery-60'
      if (level >= 45) return 'mdi-battery-50'
      if (level >= 35) return 'mdi-battery-40'
      if (level >= 25) return 'mdi-battery-30'
      if (level >= 15) return 'mdi-battery-20'
      if (level >= 5) return 'mdi-battery-10'
      return 'mdi-battery-alert-variant-outline'
    },
    batteryIconClass () {
      if (this.batteryLevel == null) return 'status-pill__icon--offline'
      const level = Math.round(this.batteryLevel * 100)
      if (level <= 15) return 'status-pill__icon--error'
      if (this.batteryCharging || level <= 35) return 'status-pill__icon--busy'
      return 'status-pill__icon--connected'
    },
    batteryLabel () {
      if (this.batteryLevel == null) return this.$t('Unknown')
      const level = Math.round(this.batteryLevel * 100)
      return this.batteryCharging ? `${level}% · ${this.$t('Charging')}` : `${level}%`
    },
    batteryTone () {
      if (this.batteryLevel == null) return 'offline'
      const level = Math.round(this.batteryLevel * 100)
      if (level <= 15) return 'error'
      if (this.batteryCharging || level <= 35) return 'busy'
      return 'connected'
    },
    guiderStatusLabel () {
      if (!this.guiderConnected) return this.$t('Offline')
      if (this.guiderActive) return this.$t('Guiding')
      if (this.guiderLoopActive) return this.$t('Looping')
      const status = String(this.guiderStatusText || '').trim()
      const map = {
        InGuiding: this.$t('Guiding'),
        InSelecting: this.$t('Selecting'),
        InCalibration: this.$t('Calibrating'),
        InDirectionDetection: this.$t('Detecting'),
        StarLostAlert: this.$t('Star Lost'),
        Connected: this.$t('Ready'),
        null: this.$t('Idle'),
        Idle: this.$t('Idle')
      }
      return map[status] || status || this.$t('Idle')
    },
    guiderTone () {
      if (!this.guiderConnected) return 'offline'
      if (this.guiderError) return 'error'
      if (this.guiderActive || this.guiderLoopActive) return 'busy'
      return 'connected'
    }
  },
  watch: {
    polarAlignmentVisible (value) {
      if (!value) this.$bus.$emit('PolarAxisMode', false)
    }
  },
  components: {
    CenterConsole,
    LeftControlWing,
    RightControlWing,
    SettingsWorkspace,
    ShellDeviceDialog,
    TopBar,
    AutomaticPolarAlignmentCalibration,
    CapturePanel,
    ChartComponent,
    DateTimePicker,
    DeviceAllocationPanel,
    FocuserPanel,
    HistogramPanel,
    ImageManagerPanel,
    INDIDebugDialog,
    MountControlPanel,
    RPIHotspotDialog,
    SchedulePanel,
    TargetSearch
  },
  mounted () {
    this.updateShellScale()
    window.addEventListener('resize', this.updateShellScale, { passive: true })
    window.addEventListener('online', this.handleBrowserNetworkChange, { passive: true })
    window.addEventListener('offline', this.handleBrowserNetworkChange, { passive: true })
    this.registerBusListeners()
    this.initBatteryMonitoring()
    this.$nextTick(() => {
      this.syncCaptureStateFromAdapter()
      this.syncMountStateFromAdapter()
      this.syncGuiderStateFromAdapter()
      this.syncFocuserStateFromAdapter()
      this.setMode('mount')
    })
  },
  beforeDestroy () {
    window.removeEventListener('resize', this.updateShellScale)
    window.removeEventListener('online', this.handleBrowserNetworkChange)
    window.removeEventListener('offline', this.handleBrowserNetworkChange)
    this.busListeners.forEach(({ eventName, handler }) => {
      this.$bus.$off(eventName, handler)
    })
    this.destroyBatteryMonitoring()
  },
  methods: {
    resolveMainCameraStatusIcon () {
      if (!this.mainCameraConnected) return require('@/assets/images/svg/ui/MainCamera-white.svg')
      if (this.captureInProgress) return require('@/assets/images/svg/ui/MainCamera-yellow.svg')
      return require('@/assets/images/svg/ui/MainCamera-green.svg')
    },
    resolveMountStatusIcon () {
      if (!this.mountConnected) return require('@/assets/images/svg/ui/Mount-white.svg')
      if (this.mountMoving) return require('@/assets/images/svg/ui/Mount-yellow.svg')
      return require('@/assets/images/svg/ui/Mount-green.svg')
    },
    resolveGuiderStatusIcon () {
      if (!this.guiderConnected) return require('@/assets/images/svg/ui/Guider-white.svg')
      if (this.guiderError) return require('@/assets/images/svg/ui/Guider-red.svg')
      if (this.guiderActive || this.guiderLoopActive) return require('@/assets/images/svg/ui/Guider-yellow.svg')
      return require('@/assets/images/svg/ui/Guider-green.svg')
    },
    resolveFocuserStatusIcon () {
      if (!this.focuserConnected) return require('@/assets/images/svg/ui/Focuser-white.svg')
      if (this.focuserBusy || this.focuserAutoActive) return require('@/assets/images/svg/ui/Focuser-yellow.svg')
      return require('@/assets/images/svg/ui/Focuser-green.svg')
    },
    handleBrowserNetworkChange () {
      this.networkConnected = navigator.onLine !== false
    },
    async initBatteryMonitoring () {
      this.handleBrowserNetworkChange()
      if (!navigator || typeof navigator.getBattery !== 'function') return
      try {
        const battery = await navigator.getBattery()
        this.batteryManager = battery
        this.updateBatteryState()
        battery.addEventListener('levelchange', this.updateBatteryState)
        battery.addEventListener('chargingchange', this.updateBatteryState)
      } catch (error) {
        this.batteryLevel = null
        this.batteryCharging = false
      }
    },
    destroyBatteryMonitoring () {
      const battery = this.batteryManager
      if (!battery) return
      battery.removeEventListener('levelchange', this.updateBatteryState)
      battery.removeEventListener('chargingchange', this.updateBatteryState)
      this.batteryManager = null
    },
    updateBatteryState () {
      const battery = this.batteryManager
      if (!battery) return
      this.batteryLevel = typeof battery.level === 'number' ? battery.level : null
      this.batteryCharging = !!battery.charging
    },
    getFocuserLoopLabel () {
      const focuserPanel = this.$refs.focuserPanel
      return focuserPanel && focuserPanel.isLoopActive ? 'On' : 'Off'
    },
    registerBusListeners () {
      const listeners = [
        ['MainCameraConnected', (value) => { this.mainCameraConnected = Number(value) !== 0 }],
        ['MountConnected', (value) => { this.mountConnected = Number(value) !== 0 }],
        ['FocuserConnected', (value) => { this.focuserConnected = Number(value) !== 0 }],
        ['GuiderConnected', (value) => { this.guiderConnected = Number(value) !== 0 }],
        ['CFWConnected', (value) => { this.cfwConnected = Number(value) !== 0 }],
        ['CameraInExposuring', (value) => { this.captureInProgress = String(value) === 'True' }],
        ['MountStatus', (value) => { this.mountMoving = String(value) === 'Moving' }],
        ['ShowNetStatus', (value) => {
          if (String(value) === 'true') this.networkConnected = true
          else if (String(value) === 'false' || String(value) === 'abnormal') this.networkConnected = false
        }],
        ['SetExpTime', (value) => { this.captureExpTimeLabel = this.formatExposureLabel(value) }],
        ['GuiderStatus', (value) => { this.guiderStatusText = String(value || 'Idle') }],
        ['GuiderSwitchStatus', (value) => { this.guiderActive = String(value) === 'true' }],
        ['GuiderLoopExpStatus', (value) => { this.guiderLoopActive = String(value) === 'true' }],
        ['GuiderUpdateStatus', (value) => {
          const numeric = Number(value)
          this.guiderError = numeric === 2
          this.guiderActive = numeric === 1 || numeric === 2
        }],
        ['GuiderStop', () => {
          this.guiderActive = false
          this.guiderError = false
        }],
        ['FocusInProgress', (value) => { this.focuserBusy = !!value }],
        ['FocusChangeSpeedSuccess', (value) => { this.focuserSpeedText = String(value) }],
        ['setRedBoxSideLength', (value) => { this.focuserRoiText = String(value) }],
        ['FocusPosition', (current) => { this.focuserPositionText = String(current) }],
        ['UpdateFWHM', (_current, fwhm) => { this.focuserFwhmText = String(fwhm) }],
        ['updateAutoFocuserState', (value) => { this.focuserAutoActive = !!value }],
        ['MountTrackSwitch', (value) => { this.mountTracking = String(value) === 'true' || value === true }],
        ['MountParkSwitch', (value) => { this.mountParked = String(value) === 'true' || value === true }],
        ['newMountSlewRate', (value) => { this.mountSpeed = value }],
        ['updateCurrentLocation', (latitude, longitude) => { this.mountLocationText = `${latitude} / ${longitude}` }],
        ['SetCFWPositionSuccess', () => { this.syncCaptureStateFromAdapter() }],
        ['SetCFWPositionFailed', () => { this.syncCaptureStateFromAdapter() }],
        ['clearChartData', () => { this.syncGuiderStateFromAdapter() }],
        ['toggleDockerChartParams', () => { this.dockExpanded = !this.dockExpanded }],
        ['toggleSchedulePanel', () => { this.toggleAuxModule('schedule') }],
        ['ImageManagerPanelOpen', () => { this.openAuxModule('imageManager') }],
        ['ImageManagerPanelClose', () => { this.closeAuxModule('imageManager') }],
        ['toggleDeviceAllocationPanel', () => { this.toggleAuxModule('deviceAllocation') }],
        ['toggleINDIDebugDialog', () => { this.toggleAuxModule('indiDebug') }],
        ['toggleRPIHotspotDialog', () => { this.toggleAuxModule('hotspot') }],
        ['toggleDateTimePicker', () => { this.toggleAuxModule('dateTime') }],
        ['ShellDeviceDialogState', (payload) => { this.applyShellDeviceDialogState(payload) }],
        ['PolarAxisMode', (value) => {
          const active = String(value) === 'true' || value === true
          this.polarAlignmentVisible = active
          if (active) this.currentMode = 'settings'
        }]
      ]
      this.busListeners = listeners.map(([eventName, handler]) => ({ eventName, handler }))
      this.busListeners.forEach(({ eventName, handler }) => {
        this.$bus.$on(eventName, handler)
      })
    },
    updateShellScale () {
      // Keep the original 1600px layout as the baseline, but let the stage
      // grow wider on extra-wide displays so the side panels can sit on the
      // actual window edges instead of staying inside a centered 16:9 frame.
      const viewportWidth = Math.max(window.innerWidth, 1)
      const viewportHeight = Math.max(window.innerHeight, 1)
      if (viewportWidth <= 960) {
        this.stageWidth = this.designMinWidth
      } else {
        this.stageWidth = Math.max(
          this.designMinWidth,
          (viewportWidth * this.designHeight) / viewportHeight
        )
      }
      const widthScale = viewportWidth / this.stageWidth
      const heightScale = viewportHeight / this.designHeight
      this.shellScale = Math.min(widthScale, heightScale)
    },
    formatExposureLabel (value) {
      const time = Number(value)
      if (!Number.isFinite(time)) return String(value || '--')
      if (time >= 1000) return `${(time / 1000)}s`
      return `${time}ms`
    },
    syncCaptureStateFromAdapter () {
      const capturePanel = this.$refs.capturePanel
      if (!capturePanel) return
      this.captureExpTimeLabel = capturePanel.ExpTimes[capturePanel.currentExpTimeIndex] || this.captureExpTimeLabel
      this.currentFilterLabel = capturePanel.CFWs[capturePanel.currentCFWIndex] || this.currentFilterLabel
    },
    syncGuiderStateFromAdapter () {
      const guiderPanel = this.$refs.guidingPanel
      if (!guiderPanel) return
      this.guiderExpTimeMs = guiderPanel.ExpTime
      this.guiderLoopActive = guiderPanel.isLoopping
      this.guiderActive = guiderPanel.isGuiding
      this.guiderError = !!guiderPanel.hasError
      this.guiderStatusText = guiderPanel.CurrentGuiderStatus || this.guiderStatusText
    },
    syncFocuserStateFromAdapter () {
      const focuserPanel = this.$refs.focuserPanel
      if (!focuserPanel) return
      this.focuserSpeedText = String(focuserPanel.MoveSpeed_)
      this.focuserRoiText = String(focuserPanel.ROI_length)
      this.focuserPositionText = String(focuserPanel.CurrentPosition)
      this.focuserFwhmText = String(focuserPanel.FWHM)
      this.focuserAutoActive = !!focuserPanel.inAutoFocus
      this.focuserBusy = !!focuserPanel.isMoveInProgress || !!focuserPanel.inAutoFocus
    },
    syncMountStateFromAdapter () {
      const mountPanel = this.$refs.mountPanel
      if (!mountPanel) return
      this.mountSpeed = mountPanel.MountSpeed
      this.mountTracking = !!mountPanel.TrackSwitch
      this.mountParked = !!mountPanel.ParkSwitch
      this.mountMoving = !!mountPanel.isMoving
    },
    closeAllAuxModules () {
      this.showSchedulePanel = false
      this.showImageManagerPanel = false
      this.showDeviceAllocationPanel = false
      this.showINDIDebugDialog = false
      this.showRPIHotspotDialog = false
      this.showDateTimePicker = false
    },
    openAuxModule (moduleId) {
      this.closeAllAuxModules()
      if (moduleId === 'schedule') this.showSchedulePanel = true
      else if (moduleId === 'imageManager') this.showImageManagerPanel = true
      else if (moduleId === 'deviceAllocation') this.showDeviceAllocationPanel = true
      else if (moduleId === 'indiDebug') this.showINDIDebugDialog = true
      else if (moduleId === 'hotspot') this.showRPIHotspotDialog = true
      else if (moduleId === 'dateTime') this.showDateTimePicker = true
      if (moduleId === 'schedule') {
        this.$nextTick(() => {
          this.safeInvoke(this.$refs.schedulePanel, 'recomputeLayout')
        })
      } else if (moduleId === 'imageManager') {
        this.$bus.$emit('calculateTotalPage')
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'ShowAllImageFolder')
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'USBCheck')
      } else if (moduleId === 'deviceAllocation') {
        this.$bus.$emit('GetConnectedDevices')
      } else if (moduleId === 'hotspot') {
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'getHotspotName')
      }
    },
    closeAuxModule (moduleId) {
      if (moduleId === 'schedule') this.showSchedulePanel = false
      else if (moduleId === 'imageManager') this.showImageManagerPanel = false
      else if (moduleId === 'deviceAllocation') this.showDeviceAllocationPanel = false
      else if (moduleId === 'indiDebug') this.showINDIDebugDialog = false
      else if (moduleId === 'hotspot') this.showRPIHotspotDialog = false
      else if (moduleId === 'dateTime') this.showDateTimePicker = false
    },
    isAuxModuleOpen (moduleId) {
      if (moduleId === 'schedule') return this.showSchedulePanel
      if (moduleId === 'imageManager') return this.showImageManagerPanel
      if (moduleId === 'deviceAllocation') return this.showDeviceAllocationPanel
      if (moduleId === 'indiDebug') return this.showINDIDebugDialog
      if (moduleId === 'hotspot') return this.showRPIHotspotDialog
      if (moduleId === 'dateTime') return this.showDateTimePicker
      return false
    },
    toggleAuxModule (moduleId) {
      if (this.isAuxModuleOpen(moduleId)) {
        this.closeAuxModule(moduleId)
      } else {
        this.openAuxModule(moduleId)
      }
    },
    closeLegacyOverlays () {
      this.$store.commit('setValue', { varName: 'showNavigationDrawer', newValue: false })
      this.$store.commit('setValue', { varName: 'showViewSettingsDialog', newValue: false })
      this.$store.commit('setValue', { varName: 'showLocationDialog', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_CFW', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_Focuser', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_Guider', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_MainCamera', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_Mount', newValue: false })
      this.$store.commit('setValue', { varName: 'showDeviceSettingsDialog_PoleCamera', newValue: false })
      this.$store.commit('setValue', { varName: 'showUSBFilesDialog', newValue: false })
    },
    handleTopAction (actionId) {
      if (actionId === 'top-devices') {
        this.closeAllAuxModules()
        this.$store.commit('toggleBool', 'showNavigationDrawer')
      } else if (actionId === 'top-settings') {
        this.closeAllAuxModules()
        this.$store.commit('toggleBool', 'showViewSettingsDialog')
      } else if (actionId === 'top-schedule') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('schedule')
      } else if (actionId === 'top-files') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('imageManager')
      } else if (actionId === 'top-allocate') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('deviceAllocation')
      } else if (actionId === 'top-debug') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('indiDebug')
      } else if (actionId === 'top-time') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('dateTime')
      } else if (actionId === 'top-hotspot') {
        this.closeLegacyOverlays()
        this.toggleAuxModule('hotspot')
      } else if (actionId === 'top-location') {
        this.closeAllAuxModules()
        this.$store.commit('toggleBool', 'showLocationDialog')
      }
    },
    handleSettingsQuickAction (actionId) {
      if (actionId === 'settings-connect-all') {
        this.closeLegacyOverlays()
        this.closeAllAuxModules()
        this.$bus.$emit('ShellConnectAllDevices')
        return
      }
      if (actionId === 'settings-disconnect-all') {
        this.closeLegacyOverlays()
        this.closeAllAuxModules()
        this.$bus.$emit('ShellDisconnectAllDevices')
        return
      }
      if (actionId === 'settings-pole-camera') {
        this.openDeviceSelection('PoleCamera', { preferConfig: true })
        return
      }
      if (actionId === 'settings-polar-align') {
        this.openPolarWorkflow()
        return
      }
      this.handleTopAction(actionId)
    },
    openPolarWorkflow () {
      this.closeAllAuxModules()
      this.closeLegacyOverlays()
      this.currentMode = 'settings'
      this.$bus.$emit('showCanvas', 'MainCamera')
      this.polarAlignmentVisible = true
      this.$bus.$emit('CalibratePolarAxisMode')
      this.$bus.$emit('PolarAxisMode', true)
    },
    openDeviceSelection (driverType, options = {}) {
      this.closeAllAuxModules()
      this.closeLegacyOverlays()
      this.deviceDialog = {
        ...this.deviceDialog,
        visible: true,
        driverType,
        displayName: '',
        drivers: [],
        configItems: []
      }
      this.$bus.$emit('ShellOpenDeviceDialog', {
        driverType,
        preferConfig: !!options.preferConfig
      })
    },
    closeShellDeviceDialog () {
      this.deviceDialog = {
        ...this.deviceDialog,
        visible: false
      }
      this.$bus.$emit('ShellCloseDeviceDialog')
    },
    applyShellDeviceDialogState (payload) {
      if (!payload || typeof payload !== 'object') return
      this.deviceDialog = {
        ...this.deviceDialog,
        ...payload,
        visible: true
      }
    },
    handleShellDeviceDialogAction (payload) {
      if (!payload || typeof payload !== 'object') return
      this.$bus.$emit('ShellDeviceDialogAction', payload)
    },
    switchShellLanguage (lang) {
      if (!lang || !this.$setLanguageWithSource) return
      this.$setLanguageWithSource('user', lang)
      this.$bus.$emit('AppSendMessage', 'Vue_Command', `saveToConfigFile:ClientLanguage:${lang}`)
    },
    handleLeftHeroAction () {
      const order = this.modeOrder
      const currentIndex = order.indexOf(this.currentMode)
      const nextIndex = currentIndex === -1 ? 0 : ((currentIndex + 1) % order.length)
      this.setMode(order[nextIndex])
    },
    setMode (mode) {
      if (mode !== 'settings') {
        this.polarAlignmentVisible = false
        this.$bus.$emit('PolarAxisMode', false)
      }
      this.currentMode = mode
      if (mode === 'mount') {
        this.$bus.$emit('showCanvas', 'Stel')
      } else if (mode === 'capture') {
        this.$bus.$emit('showCanvas', 'MainCamera')
      } else if (mode === 'guiding') {
        this.$bus.$emit('showCanvas', 'GuiderCamera')
      } else if (mode === 'focus') {
        this.$bus.$emit('showCanvas', 'MainCamera')
      } else if (mode === 'settings') {
        this.$bus.$emit('showCanvas', 'Stel')
      }
    },
    handleHeroAction () {
      if (this.currentMode === 'settings') {
        this.openPolarWorkflow()
        return
      }
      if (this.currentMode === 'capture') {
        if (this.captureInProgress) {
          this.$refs.capturePanel && this.$refs.capturePanel.triggerCaptureAbort()
        } else {
          this.$refs.capturePanel && this.$refs.capturePanel.triggerCapturePrimaryAction()
        }
        return
      }
      if (this.currentMode === 'guiding') {
        this.safeInvoke(this.$refs.guidingPanel, 'GuiderSwitch')
        this.syncGuiderStateFromAdapter()
        return
      }
      if (this.currentMode === 'focus') {
        this.handleAutoFocusPrimaryAction()
        return
      }
      this.safeInvoke(this.$refs.mountPanel, 'stop')
    },
    handleAutoFocusPrimaryAction () {
      const focuserPanel = this.$refs.focuserPanel
      if (!focuserPanel) return
      const check = this.$canUseDevice('Focuser', 'AutoFocus')
      if (!check.allowed) return
      if (!this.focuserConnected) {
        this.$bus.$emit('showMsgBox', 'Focuser is not connected!', 'warning')
        return
      }
      if (focuserPanel.isMoveInProgress) {
        this.$bus.$emit('showMsgBox', 'Focuser is moving!', 'warning')
        return
      }
      if (focuserPanel.inAutoFocus) {
        focuserPanel.inAutoFocus = false
        this.$bus.$emit('SendConsoleLogMsg', 'StopAutoFocus', 'info')
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'StopAutoFocus')
        this.$stopFeature(['Focuser'], 'AutoFocus')
        this.focuserAutoActive = false
        return
      }
      if (!this.$store.getters['device/isDeviceBound']('MainCamera')) {
        this.$bus.$emit(
          'showMsgBox',
          this.$t('MainCameraNotBoundAction', { action: this.$t('Feature_AutoFocus') }),
          'error'
        )
        return
      }
      focuserPanel.inAutoFocus = true
      this.focuserAutoActive = true
      this.$startFeature(['Focuser'], 'AutoFocus')
      this.$bus.$emit('AppSendMessage', 'Vue_Command', 'AutoFocusConfirm:Coarse')
      this.$bus.$emit('AppSendMessage', 'Vue_Command', 'ClearDataPoints')
      this.$bus.$emit('ClearAllData')
    },
    handleLeftAction (actionId) {
      if (actionId === 'settings-device-main-camera') {
        this.openDeviceSelection('MainCamera', { preferConfig: true })
      } else if (actionId === 'settings-device-guider') {
        this.openDeviceSelection('Guider', { preferConfig: true })
      } else if (actionId === 'settings-device-mount') {
        this.openDeviceSelection('Mount', { preferConfig: true })
      } else if (actionId === 'mount-grid') {
        this.cycleGridMode()
      } else if (actionId === 'mount-dso') {
        this.toggleStelProperty('dsos.visible')
      } else if (actionId === 'mount-constellation') {
        const next = !this.$store.state.stel.constellations.lines_visible
        this.$stel.core.constellations.lines_visible = next
        this.$stel.core.constellations.labels_visible = next
      } else if (actionId === 'capture-sync') {
        this.triggerSolveSync()
      } else if (actionId === 'capture-fwhm' || actionId === 'capture-focus') {
        this.setMode('focus')
      } else if (actionId === 'guiding-loop') {
        this.safeInvoke(this.$refs.guidingPanel, 'LoopExpSwitch')
        this.syncGuiderStateFromAdapter()
      } else if (actionId === 'guiding-range') {
        this.safeInvoke(this.$refs.guidingPanel, 'RangeSwitch')
      } else if (actionId === 'guiding-clear') {
        this.safeInvoke(this.$refs.guidingPanel, 'DataClear')
      } else if (actionId === 'focus-roi') {
        this.safeInvoke(this.$refs.focuserPanel, 'ROIChange')
        this.syncFocuserStateFromAdapter()
      } else if (actionId === 'focus-loop') {
        this.safeInvoke(this.$refs.focuserPanel, 'toggleLoopShooting')
      } else if (actionId === 'focus-calibration') {
        this.safeInvoke(this.$refs.focuserPanel, 'startCalibrationProcess')
      }
    },
    handleRightAction (actionId) {
      if (actionId === 'settings-device-telescope') {
        this.openDeviceSelection('Telescopes', { preferConfig: true })
      } else if (actionId === 'settings-device-focuser') {
        this.openDeviceSelection('Focuser', { preferConfig: true })
      } else if (actionId === 'settings-device-cfw') {
        this.openDeviceSelection('CFW', { preferConfig: true })
      } else if (actionId === 'mount-sync') {
        this.safeInvoke(this.$refs.mountPanel, 'handleMountSYNC')
      } else if (actionId === 'mount-track') {
        this.safeInvoke(this.$refs.mountPanel, 'handleMountTrack')
      } else if (actionId === 'mount-home') {
        this.safeInvoke(this.$refs.mountPanel, 'handleMountHome')
      } else if (actionId === 'capture-exp') {
        this.safeInvoke(this.$refs.capturePanel, 'handleExpTimeButtonClick', 'plus')
        this.syncCaptureStateFromAdapter()
      } else if (actionId === 'capture-filter') {
        this.safeInvoke(this.$refs.capturePanel, 'handleCFWButtonClick', 'plus')
        this.syncCaptureStateFromAdapter()
      } else if (actionId === 'capture-save') {
        this.safeInvoke(this.$refs.capturePanel, 'CaptureImageSave')
      } else if (actionId === 'guiding-loop') {
        this.safeInvoke(this.$refs.guidingPanel, 'LoopExpSwitch')
        this.syncGuiderStateFromAdapter()
      } else if (actionId === 'guiding-exp') {
        this.safeInvoke(this.$refs.guidingPanel, 'ExpTimeSwitch')
        this.syncGuiderStateFromAdapter()
      } else if (actionId === 'guiding-recalibrate') {
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'PHD2Recalibrate')
        this.$bus.$emit('SendConsoleLogMsg', 'PHD2 Recalibrate', 'info')
      } else if (actionId === 'focus-speed') {
        this.safeInvoke(this.$refs.focuserPanel, 'SpeedChange')
        this.syncFocuserStateFromAdapter()
      } else if (actionId === 'focus-roi') {
        this.safeInvoke(this.$refs.focuserPanel, 'ROIChange')
        this.syncFocuserStateFromAdapter()
      } else if (actionId === 'focus-calibration') {
        this.safeInvoke(this.$refs.focuserPanel, 'startCalibrationProcess')
      }
    },
    handleToolAction (actionId) {
      if (actionId === 'top-hotspot') {
        this.handleTopAction('top-hotspot')
        return
      }
      if (actionId === 'mount-solve') {
        this.safeInvoke(this.$refs.mountPanel, 'handleSolveSYNC')
      } else if (actionId === 'mount-park') {
        this.safeInvoke(this.$refs.mountPanel, 'handleMountPark')
      } else if (actionId === 'mount-atmosphere') {
        this.toggleStelProperty('atmosphere.visible')
      } else if (actionId === 'mount-landscape') {
        this.toggleStelProperty('landscapes.visible')
      } else if (actionId === 'capture-solve-sync') {
        this.triggerSolveSync()
      } else if (actionId === 'capture-focus') {
        this.setMode('focus')
      } else if (actionId === 'capture-files') {
        this.$bus.$emit('ImageManagerPanelOpen')
      } else if (actionId === 'capture-settings') {
        this.setMode('settings')
      } else if (actionId === 'guiding-clear') {
        this.safeInvoke(this.$refs.guidingPanel, 'DataClear')
      } else if (actionId === 'guiding-range') {
        this.safeInvoke(this.$refs.guidingPanel, 'RangeSwitch')
      } else if (actionId === 'guiding-loop') {
        this.safeInvoke(this.$refs.guidingPanel, 'LoopExpSwitch')
        this.syncGuiderStateFromAdapter()
      } else if (actionId === 'guiding-exp') {
        this.safeInvoke(this.$refs.guidingPanel, 'ExpTimeSwitch')
        this.syncGuiderStateFromAdapter()
      } else if (actionId === 'guiding-settings') {
        this.setMode('settings')
      } else if (actionId === 'focus-step-left') {
        this.runFocuserStep('left')
      } else if (actionId === 'focus-stop') {
        this.$bus.$emit('AppSendMessage', 'Vue_Command', 'focusMoveStop:false')
      } else if (actionId === 'focus-step-right') {
        this.runFocuserStep('right')
      } else if (actionId === 'focus-loop') {
        this.safeInvoke(this.$refs.focuserPanel, 'toggleLoopShooting')
      }
    },
    handleFooterPress (actionId) {
      if (actionId === 'mount-ra-minus') this.safeInvoke(this.$refs.mountPanel, 'handleMouseDownRA', 'minus')
      else if (actionId === 'mount-dec-minus') this.safeInvoke(this.$refs.mountPanel, 'handleMouseDownDEC', 'minus')
      else if (actionId === 'mount-ra-plus') this.safeInvoke(this.$refs.mountPanel, 'handleMouseDownRA', 'plus')
      else if (actionId === 'mount-dec-plus') this.safeInvoke(this.$refs.mountPanel, 'handleMouseDownDEC', 'plus')
      else if (actionId === 'focus-left-hold') this.safeInvoke(this.$refs.focuserPanel, 'FocusMove', 'left')
      else if (actionId === 'focus-right-hold') this.safeInvoke(this.$refs.focuserPanel, 'FocusMove', 'right')
      else if (actionId === 'focus-left-step') this.runFocuserStep('left')
      else if (actionId === 'focus-right-step') this.runFocuserStep('right')
    },
    handleFooterRelease (actionId) {
      if (actionId === 'mount-ra-minus') this.safeInvoke(this.$refs.mountPanel, 'stopRA', 'minus')
      else if (actionId === 'mount-dec-minus') this.safeInvoke(this.$refs.mountPanel, 'stopDEC', 'minus')
      else if (actionId === 'mount-ra-plus') this.safeInvoke(this.$refs.mountPanel, 'stopRA', 'plus')
      else if (actionId === 'mount-dec-plus') this.safeInvoke(this.$refs.mountPanel, 'stopDEC', 'plus')
      else if (actionId === 'focus-left-hold' || actionId === 'focus-right-hold') this.safeInvoke(this.$refs.focuserPanel, 'FocusAbort')
    },
    handleFooterAction (actionId) {
      if (actionId === 'open-devices') {
        this.handleTopAction('top-devices')
      } else if (actionId === 'switch-settings') {
        this.setMode('settings')
      } else if (actionId === 'focus-loop') {
        this.safeInvoke(this.$refs.focuserPanel, 'toggleLoopShooting')
      } else if (actionId === 'focus-calibration') {
        this.safeInvoke(this.$refs.focuserPanel, 'startCalibrationProcess')
      }
    },
    triggerSolveSync () {
      if (!this.$store.getters['device/isDeviceBound']('MainCamera')) {
        this.$bus.$emit(
          'showMsgBox',
          this.$t('MainCameraNotBoundAction', { action: this.$t('Feature_SolveSync') }),
          'error'
        )
        return
      }
      this.$bus.$emit('AppSendMessage', 'Vue_Command', 'EndCaptureAndSolve')
      this.$bus.$emit('SendConsoleLogMsg', 'End Capture And Solve', 'info')
      this.$stopFeature(['MainCamera'], 'SolveSync')
    },
    cycleGridMode () {
      if (!this.$store.state.stel || !this.$stel || !this.$stel.core) return
      const az = !!this.$store.state.stel.lines.azimuthal.visible
      const eq = !!this.$store.state.stel.lines.equatorial_jnow.visible
      if (!az && !eq) {
        this.$stel.core.lines.azimuthal.visible = true
        this.$stel.core.lines.equatorial_jnow.visible = false
      } else if (az && !eq) {
        this.$stel.core.lines.azimuthal.visible = false
        this.$stel.core.lines.equatorial_jnow.visible = true
      } else {
        this.$stel.core.lines.azimuthal.visible = false
        this.$stel.core.lines.equatorial_jnow.visible = false
      }
    },
    toggleStelProperty (path) {
      if (!this.$store.state.stel || !this.$stel || !this.$stel.core) return
      const segments = String(path).split('.')
      let stateCursor = this.$store.state.stel
      let stelCursor = this.$stel.core
      for (let i = 0; i < segments.length - 1; i += 1) {
        stateCursor = stateCursor[segments[i]]
        stelCursor = stelCursor[segments[i]]
      }
      const leaf = segments[segments.length - 1]
      stelCursor[leaf] = !stateCursor[leaf]
    },
    runFocuserStep (direction) {
      const focuserPanel = this.$refs.focuserPanel
      if (!focuserPanel) return
      focuserPanel.FocusMove(direction)
      window.setTimeout(() => {
        focuserPanel.FocusAbort()
      }, 50)
    },
    safeInvoke (target, methodName, ...args) {
      if (!target || typeof target[methodName] !== 'function') return
      target[methodName](...args)
    }
  }
}
</script>

<style scoped>
.app-shell {
  position: absolute;
  inset: 0;
  pointer-events: none;
  color: #f4f7fb;
  font-family: "Avenir Next", "PingFang SC", "Noto Sans SC", sans-serif;
  z-index: 20;
}

.app-shell__viewport {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.app-shell__stage {
  position: relative;
  flex: 0 0 auto;
  transform-origin: center center;
}

.app-shell__top,
.app-shell__search,
.app-shell__left,
.app-shell__right,
.app-shell__bottom {
  pointer-events: auto;
}

.app-shell__search {
  position: absolute;
  top: 54px;
  left: 50%;
  z-index: 255;
  width: min(390px, calc(100% - 660px));
  min-width: 220px;
  transform: translateX(-50%);
}

.app-shell__stage-frame {
  pointer-events: none;
  position: absolute;
  inset: 18px 10px 12px;
  border-radius: 56px;
  border: 1px solid var(--qs-border-soft);
  background:
    radial-gradient(circle at 50% -4%, rgba(170, 210, 255, 0.12), transparent 22%),
    radial-gradient(circle at 12% 50%, rgba(91, 134, 219, 0.11), transparent 18%),
    radial-gradient(circle at 88% 50%, rgba(91, 134, 219, 0.11), transparent 18%),
    linear-gradient(180deg, rgba(255, 255, 255, 0.05), transparent 12%, transparent 84%, rgba(255, 255, 255, 0.03)),
    linear-gradient(180deg, rgba(8, 14, 25, 0.18), rgba(2, 6, 12, 0.4));
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 0 0 1px rgba(255, 255, 255, 0.04),
    inset 0 -52px 120px rgba(2, 7, 16, 0.36),
    inset 0 32px 80px rgba(115, 161, 238, 0.06),
    0 30px 80px var(--qs-panel-shadow);
}

.app-shell__stage-frame--hidden {
  opacity: 0;
}

.app-shell__stage-frame::before {
  content: "";
  position: absolute;
  inset: 10px;
  border-radius: 46px;
}

.app-shell__stage-frame::before {
  border: 1px solid rgba(255, 255, 255, 0.05);
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.08),
    inset 0 -20px 50px rgba(4, 10, 18, 0.3);
}

/* ── Van Gogh Starry Night art background (capture / guiding / focus modes) ── */
.app-shell__art-bg {
  position: absolute;
  inset: 18px 10px 12px;
  border-radius: 56px;
  background-image: url('./starry_night_for_cursor.png');
  background-size: cover;
  background-position: center 20%;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}

/* ── QUARCS branding overlay — on top of art-bg ── */
.app-shell__quarcs-brand {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 18px;
  z-index: 1;
  pointer-events: none;
}

.app-shell__quarcs-brand-logo {
  width: 120px;
  height: 120px;
  opacity: 0.92;
  filter: drop-shadow(0 2px 16px rgba(0, 0, 0, 0.5));
}

.app-shell__quarcs-brand-text {
  font-size: 86px;
  font-weight: 700;
  letter-spacing: 0.14em;
  color: rgba(255, 255, 255, 0.92);
  text-shadow:
    0 2px 20px rgba(0, 0, 0, 0.6),
    0 0 60px rgba(0, 0, 0, 0.3);
  line-height: 1;
}

.art-bg-fade-enter-active,
.art-bg-fade-leave-active {
  transition: opacity 0.7s ease;
}
.art-bg-fade-enter,
.art-bg-fade-leave-to {
  opacity: 0;
}

.app-shell__settings-backdrop {
  position: absolute;
  inset: 18px 10px 12px;
  border-radius: 56px;
  background:
    radial-gradient(circle at 50% 0%, rgba(200, 220, 255, 0.22), transparent 28%),
    linear-gradient(180deg, rgba(198, 212, 238, 0.96) 0%, rgba(178, 195, 228, 0.98) 100%);
  box-shadow:
    inset 0 0 0 1px rgba(165, 192, 238, 0.40),
    inset 0 1px 0 rgba(255, 255, 255, 0.52),
    0 30px 80px rgba(60, 85, 140, 0.22);
}

.control-tag {
  display: none !important;
}

.app-shell__body {
  position: absolute;
  inset: 22px 18px 14px 18px;
  display: flex;
  justify-content: space-between;
  align-items: stretch;
  gap: 8px;
}

.app-shell__body--hidden {
  opacity: 0;
  pointer-events: none;
}

.app-shell__center {
  pointer-events: none;
}

.app-shell__center--settings {
  pointer-events: auto;
}

.app-shell__overlay-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
  z-index: 2;
}

.app-shell__overlay-layer--hidden {
  opacity: 0;
  pointer-events: none;
}

.app-shell__overlay-panel {
  pointer-events: auto;
  z-index: 3;
}

.app-shell__overlay-panel--guiding {
  transform: translateY(0px);
}

.app-shell__overlay-panel--capture {
  transform: translateY(0px);
}

.app-shell__overlay-panel--focus {
  transform: translateY(0px);
}

/* Mount mode QUARCS watermark — center of bottom bridge, above metallic surface */
.app-shell__mount-brand {
  position: absolute;
  bottom: 42px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 5px;
  pointer-events: none;
  z-index: 1;
  white-space: nowrap;
}

.app-shell__mount-brand-text {
  font-size: 36px;
  font-weight: 800;
  letter-spacing: 0.28em;
  /* Visible on silver metallic: dark blue-gray at 45% opacity */
  color: rgba(88, 115, 175, 0.45);
  text-transform: uppercase;
  line-height: 1;
}

.app-shell__mount-brand-sub {
  font-size: 9.5px;
  letter-spacing: 0.40em;
  text-transform: uppercase;
  color: rgba(100, 130, 188, 0.36);
  font-weight: 600;
}

.app-shell__aux-layer {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.app-shell__aux {
  pointer-events: auto;
}

.app-shell__aux--datetime {
  position: absolute;
  top: 68px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 210;
}

.app-shell__aux--schedule {
  position: absolute;
  inset: 0;
  z-index: 205;
}

.app-shell__legacy-adapters {
  position: absolute;
  width: 0;
  height: 0;
  overflow: hidden;
  opacity: 0;
  pointer-events: none;
}

.app-shell__bottom--hidden {
  opacity: 0;
  pointer-events: none;
}

.app-shell__search::v-deep(.tsearch) {
  width: 100%;
}

.app-shell__search::v-deep([data-testid="ui-skysource-search-root"]) {
  width: 100%;
}

.app-shell__search::v-deep(.v-input) {
  margin-top: 0;
}

.app-shell__search::v-deep(.v-input__slot) {
  min-height: 44px !important;
  padding: 0 16px !important;
  border-radius: 20px !important;
  background: linear-gradient(180deg, rgba(212, 224, 248, 0.94), rgba(190, 206, 236, 0.96)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.56),
    inset 0 0 0 1px rgba(155, 190, 248, 0.40),
    0 14px 28px rgba(60, 85, 140, 0.16) !important;
  backdrop-filter: blur(16px);
}

.app-shell__search::v-deep(.v-text-field__slot input),
.app-shell__search::v-deep(.v-label),
.app-shell__search::v-deep(.v-input__prepend-inner .v-icon) {
  color: rgba(22, 42, 82, 0.90) !important;
}

.app-shell__search::v-deep(.v-list) {
  margin-top: 8px;
  border-radius: 20px;
  background: linear-gradient(180deg, rgba(205, 218, 244, 0.97), rgba(185, 200, 230, 0.98)) !important;
  box-shadow:
    inset 0 1px 0 rgba(255, 255, 255, 0.52),
    inset 0 0 0 1px rgba(155, 188, 245, 0.36),
    0 18px 36px rgba(60, 85, 140, 0.20);
  backdrop-filter: blur(16px);
}

.app-shell__search::v-deep(.v-list-item) {
  min-height: 56px;
  color: rgba(22, 42, 82, 0.90) !important;
}

.app-shell__search::v-deep(.v-list-item__title),
.app-shell__search::v-deep(.v-list-item__subtitle) {
  color: rgba(22, 42, 82, 0.90) !important;
}

@media (max-width: 960px) {
  .app-shell__stage-frame,
  .app-shell__settings-backdrop {
    inset: 10px;
    border-radius: 28px;
  }

  .app-shell__body {
    inset: 10px;
    gap: 8px;
  }

  .app-shell__search {
    top: 52px;
    width: min(320px, calc(100% - 80px));
    min-width: 0;
  }
}
</style>

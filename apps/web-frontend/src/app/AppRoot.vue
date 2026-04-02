<template>
  <div class="app-root">
    <ViewportHost class="app-root__viewport" />
    <AppShell class="app-root__shell" />
  </div>
</template>

<script>
import AppShell from './shell/AppShell.vue'
import ViewportHost from './viewport/ViewportHost.vue'

export default {
  name: 'AppRoot',
  components: {
    AppShell,
    ViewportHost
  }
}
</script>

<style>
.app-root {
  position: relative;
  width: 100%;
  height: 100vh;
  min-height: 100dvh;
  overflow: hidden;
  background:
    radial-gradient(circle at top, rgba(22, 40, 68, 0.45), transparent 42%),
    linear-gradient(180deg, #07111f 0%, #03070d 100%);
}

.app-root__viewport,
.app-root__shell {
  position: absolute;
  inset: 0;
}

.app-root__viewport {
  z-index: 0;
}

.app-root__shell {
  z-index: 20;
}

/*
 * 过渡期策略：
 * 旧 App 继续承担星图/相机/通信宿主，
 * 但默认隐藏旧控制界面，只保留底层视口。
 */
.legacy-app-host {
  position: relative;
  width: 100%;
  height: 100%;
  overflow: hidden;
}

.legacy-app-host .v-application {
  position: absolute !important;
  inset: 0;
  width: 100% !important;
  min-width: 0;
  max-width: 100%;
  height: 100% !important;
  min-height: 100% !important;
  max-height: 100%;
  overflow: hidden;
}

.legacy-app-host #app {
  position: absolute !important;
  inset: 0 !important;
  width: 100% !important;
  height: 100% !important;
  min-height: 100% !important;
  max-width: 100% !important;
  max-height: 100% !important;
  overflow: hidden !important;
}

.legacy-app-host [data-testid="gui-root"],
.legacy-app-host .menu-button-above-overlay,
.legacy-app-host .calibration-info-box,
.legacy-app-host .auto-focus-info-box {
  display: none !important;
}

.legacy-app-host .v-application--wrap,
.legacy-app-host .v-main__wrap,
.legacy-app-host .v-main,
.legacy-app-host .container.fill-height,
.legacy-app-host #stel {
  min-height: 100%;
  height: 100%;
  width: 100%;
  overflow: hidden;
}

.legacy-app-host canvas {
  display: block;
}
</style>

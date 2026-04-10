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
  --qs-bg-top: #08111f;
  --qs-bg-bottom: #02060d;
  --qs-surface-0: rgba(235, 242, 255, 0.98);
  --qs-surface-1: rgba(222, 232, 252, 0.97);
  --qs-surface-2: rgba(205, 218, 244, 0.96);
  --qs-surface-3: rgba(188, 204, 234, 0.97);
  --qs-surface-4: rgba(168, 185, 218, 0.98);
  --qs-panel-shadow: rgba(45, 65, 115, 0.36);
  --qs-panel-shadow-soft: rgba(55, 78, 128, 0.20);
  --qs-border-soft: rgba(168, 192, 235, 0.46);
  --qs-border-strong: rgba(138, 170, 228, 0.68);
  --qs-highlight-soft: rgba(255, 255, 255, 0.68);
  --qs-highlight-strong: rgba(255, 255, 255, 0.90);
  --qs-glow-blue: rgba(80, 120, 195, 0.18);
  --qs-glow-cyan: rgba(100, 162, 228, 0.14);
  --qs-text-primary: rgba(22, 38, 65, 0.94);
  --qs-text-secondary: rgba(50, 72, 110, 0.86);
  --qs-text-muted: rgba(88, 115, 158, 0.78);
  --qs-radius-xl: 44px;
  --qs-radius-lg: 28px;
  --qs-radius-md: 20px;
  --qs-radius-pill: 999px;
  position: relative;
  width: 100%;
  height: 100vh;
  min-height: 100dvh;
  overflow: hidden;
  background:
    radial-gradient(circle at 50% -8%, rgba(121, 172, 255, 0.28), transparent 28%),
    radial-gradient(circle at 14% 50%, rgba(60, 108, 198, 0.18), transparent 20%),
    radial-gradient(circle at 86% 52%, rgba(60, 108, 198, 0.18), transparent 20%),
    linear-gradient(180deg, var(--qs-bg-top) 0%, var(--qs-bg-bottom) 100%);
}

.app-root::before,
.app-root::after {
  content: "";
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.app-root::before {
  background:
    linear-gradient(180deg, rgba(255, 255, 255, 0.04), transparent 16%, transparent 82%, rgba(255, 255, 255, 0.02)),
    radial-gradient(circle at 50% 10%, rgba(171, 209, 255, 0.12), transparent 24%),
    radial-gradient(circle at 50% 88%, rgba(10, 18, 32, 0.72), transparent 36%);
  z-index: 1;
}

.app-root::after {
  background:
    linear-gradient(90deg, rgba(2, 6, 12, 0.84), transparent 11%, transparent 89%, rgba(2, 6, 12, 0.84)),
    linear-gradient(180deg, rgba(2, 6, 12, 0.8), transparent 12%, transparent 88%, rgba(2, 6, 12, 0.82));
  z-index: 1;
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

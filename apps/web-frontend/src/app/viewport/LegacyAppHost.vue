<template>
  <div class="legacy-app-host">
    <LegacyApp />
  </div>
</template>

<script>
import LegacyApp from '../../App.vue'

export default {
  name: 'LegacyAppHost',
  components: {
    LegacyApp
  }
}
</script>

<style scoped>
.legacy-app-host {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  border-radius: inherit;
}
</style>

<template>
  <header class="top-bar">
    <div class="top-bar__brand">
      <span class="control-tag">Top-Brand</span>
      <span class="top-bar__dot"></span>
      <div class="top-bar__title">QUARCS Device Shell Prototype</div>
    </div>
  </header>
</template>

<script>
export default {
  name: 'TopBar'
}
</script>

<style scoped>
.top-bar {
  position: absolute;
  top: 14px;
  left: 24px;
  right: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  pointer-events: none;
}

.top-bar__brand {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 14px;
  border-radius: 999px;
  background: rgba(7, 16, 30, 0.18);
  backdrop-filter: blur(10px);
}

.top-bar__title {
  font-size: 13px;
  font-weight: 500;
  letter-spacing: 0.24em;
  text-transform: uppercase;
  color: rgba(244, 247, 251, 0.58);
}

.top-bar__dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(135, 181, 255, 0.84);
  box-shadow: 0 0 10px rgba(135, 181, 255, 0.72);
}

.control-tag {
  position: absolute;
  left: 50%;
  top: -10px;
  transform: translateX(-50%);
  z-index: 2;
  padding: 1px 4px;
  border-radius: 999px;
  background: rgba(123, 74, 226, 0.14);
  color: rgba(193, 150, 255, 0.98);
  font-size: 7px;
  line-height: 1.2;
  letter-spacing: 0.04em;
  white-space: nowrap;
  pointer-events: none;
  border: 1px solid rgba(170, 111, 255, 0.34);
}

@media (max-width: 960px) {
  .top-bar {
    left: 12px;
    right: 12px;
  }
}
</style>

# QUARCS Stellarium Web Engine 新 UI 目录迁移方案

## 目标

本方案用于明确新的前端重构代码应放置的位置，以及新旧代码在过渡期如何共存。

当前仓库已经具备比较清晰的顶层边界：

- 根目录 `src/`：C/C++ 与 wasm 引擎层
- `data/`：引擎资源
- `apps/web-frontend/`：现有前端应用
- `doc/`：项目文档

因此，新的控制界面应继续放在 `apps/web-frontend/` 内，而不是在仓库根目录再建立另一套独立前端工程。

## 结论

新的前端代码建议放在：

- `apps/web-frontend/src/app/`

这是新的 UI 主线目录。

旧前端代码暂时保留在现有位置，作为过渡期宿主和业务逻辑来源。

## 为什么选择 `src/app/`

### 1. 保持与现有前端工程同一构建链路

当前前端构建、wasm 资源拷贝与部署链路都已经围绕 `apps/web-frontend/` 建立完成。

将新 UI 放在该目录下，可以：

- 继续复用现有 `package.json`
- 继续复用现有构建命令
- 继续复用现有资源路径
- 避免额外维护第二套前端工程

### 2. 与旧 `components/` 明确分层

当前 `apps/web-frontend/src/components/` 目录承担了大量旧 UI 组件，命名方式和职责边界已经比较混杂。

如果把新 UI 继续塞进 `components/`：

- 会与旧组件快速混杂
- 难以建立新架构边界
- 后续迁移时很难辨认“哪些是新主线，哪些是旧遗留”

因此需要单独开辟新的主线目录。

### 3. 方便新旧并行迁移

新 UI 不会一次性替换所有旧代码，而是需要经历一段并行期：

- 新入口逐步建立
- 旧宿主逐步剥离
- 面板和控制逻辑逐步迁移

将新代码集中在 `src/app/`，可以让过渡过程更可控。

## 不建议的放置方式

### 不建议直接继续堆到 `src/App.vue`

原因：

- 该文件体量已经非常大
- 继续叠加会进一步提高耦合度
- 不利于新旧边界切分

### 不建议直接放进 `src/components/`

原因：

- 会和旧组件库混在一起
- 无法体现“新架构主线”

### 不建议仓库根目录新建第二个前端应用

除非未来准备彻底拆分成独立部署产品，否则不建议这样做。

原因：

- 会打断当前资源引用与构建流程
- 会引入额外部署和维护成本

## 推荐目录结构

建议将新的前端架构逐步组织为：

```text
apps/web-frontend/src/
  app/
    AppRoot.vue

    shell/
      AppShell.vue
      TopBar.vue
      LeftSidebar.vue
      RightSidebar.vue
      BottomDock.vue
      GlobalModalHost.vue

    viewport/
      ViewportHost.vue
      LegacyAppHost.vue
      SkyViewport.vue
      MainCameraViewport.vue
      GuiderViewport.vue

    panels/
      target/
      mount/
      camera/
      guider/
      focuser/
      schedule/
      settings/

    services/
    utils/

  components/
    ...旧组件

  store/
    index.js
    deviceManager.js
    modules/
      ui-shell.js
      viewport.js
      session.js
```

## 新旧代码共存原则

过渡期建议遵循以下原则。

### 1. 旧 `App.vue` 先作为宿主保留

旧 `App.vue` 中仍然包含：

- 画布初始化
- 引擎挂载
- 大量事件桥接
- 设备通信逻辑

在重构初期，不应立即拆散这些逻辑。

更合理的方式是：

- 让新的 `AppRoot.vue` 成为前端入口
- 将旧 `App.vue` 包在新的视口宿主中
- 在其上叠加新的 UI Shell

### 2. 新 UI 从 `src/app/` 向外扩展

新设计相关代码统一进入 `src/app/`，不再回流到旧入口。

### 3. 旧 `components/` 暂不大规模搬迁

短期内不需要为了“目录整洁”而一次性移动大量旧组件文件。

更稳妥的做法是：

- 先建立新目录边界
- 后续在迁移某个模块时，再决定是否移动对应旧组件

### 4. 需要时可逐步引入 `legacy/` 过渡目录

如果后续要主动整理旧代码，可考虑增加：

- `src/components/legacy/`

但现阶段不是必须。

## 初始落地建议

### 第一步

新增：

- `src/app/AppRoot.vue`
- `src/app/shell/`
- `src/app/viewport/`

并将 `main.js` 的入口切换为 `AppRoot.vue`。

### 第二步

由 `AppRoot.vue` 完成两件事：

- 挂载旧宿主作为背景层
- 挂载新的控制壳层作为前景层

### 第三步

逐步把新面板落到：

- `src/app/panels/`

而不是继续写进旧 `components/`。

## 中期演进建议

当新壳层稳定后，可继续做以下整理：

- 将新的壳层状态迁入 `store/modules/ui-shell.js`
- 将视口相关状态迁入 `store/modules/viewport.js`
- 将新面板中的设备逻辑逐步从旧组件中剥离

## 长期目标

长期希望达到的结构是：

- `src/app/` 成为新前端主线
- 旧 `App.vue` 缩减为纯宿主或被替换
- `components/` 中的旧控制层逐步退场
- 前端整体形成“视口层 + 交互层 + 壳层”的清晰边界

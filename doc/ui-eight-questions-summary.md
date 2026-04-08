# UI 八个问题整理

## 范围

本文基于以下两个仓库的前端代码整理：

- 旧 UI 仓库：`/home/quarcs/workspace/QUARCS/QUARCS_stellarium-web-engine`
- 新 UI 仓库：`/home/quarcs/workspace/QUARCS/QUARCS_stellarium-web-engine-new`

说明：

- 本文结论以当前代码状态为准。
- 新 UI 目前仍处于“新壳包旧业务”的过渡阶段，部分图稿按钮在代码里仍是占位。
- 对无法仅凭静态代码 100% 确认的点，文末会单列说明。

## 1. 项目技术栈是什么

这两个前端仓库都不是 `Qt/QML`、`Flutter`、`React/Electron`。

当前前端主技术栈是：

- `Vue 2`
- `Vue Router 3`
- `Vuex 3`
- `Vuetify 2`
- `Vue CLI 4`
- `ECharts`
- `Leaflet`
- `fitsjs`
- `Stellarium Web Engine` 的 `WASM/JS`

补充说明：

- Qt 更像设备服务端或宿主程序，不在这两个前端仓库的主技术栈内。
- 前端通过 `WebSocket` 与后端通信。

## 2. 旧 UI 和新 UI 是否在同一个仓库里

不在同一个仓库里。

目录分别是：

- 旧 UI：`/home/quarcs/workspace/QUARCS/QUARCS_stellarium-web-engine/apps/web-frontend`
- 新 UI 壳层：`/home/quarcs/workspace/QUARCS/QUARCS_stellarium-web-engine-new/apps/web-frontend/src/app`

但需要特别注意：

- 新仓库里仍然保留了一套旧业务宿主。
- 新 UI 不是完全独立重写，而是通过新壳层包住旧的 `App.vue` 和原有业务组件运行。

也就是说，新仓库当前是：

- 新壳：`src/app/*`
- 旧业务宿主：`src/App.vue`、`src/components/*`

## 3. 旧 UI 里哪些按钮已经接了真实设备命令，哪些只是前端交互或半成品

### 已接真实设备命令的按钮或面板

主要通过 `$bus.$emit('AppSendMessage', 'Vue_Command', '...')` 发给 `App.vue`，再由 `WebSocket` 发到后端。

已经接真实设备命令的主要部分包括：

- 赤道仪控制
  - `MountMoveWest`
  - `MountMoveEast`
  - `MountMoveNorth`
  - `MountMoveSouth`
  - `MountGoto`
  - `MountPark`
- 主相机拍摄
  - `takeExposure`
  - `takeExposureBurst`
  - `abortExposure`
- 导星
  - `GuiderLoopExpSwitch`
  - `GuiderSwitch`
  - `getGuiderStatus`
- 调焦
  - `focusSpeed`
  - `focusMove`
  - `focusMoveStep`
  - `focusMoveStop`
  - `StopAutoFocus`
  - `FocusLoopShooting`
  - 行程校准相关命令
- 设备连接与参数设置
  - `SetConnectionMode`
  - 主相机 / 导星参数设置
  - 电源切换
  - 部分系统命令

### 主要是前端交互或星图引擎交互的部分

- 星图显示相关按钮
  - 星座线
  - 网格
  - 大气
  - 地景
  - 这些主要直接操作 `$stel.core`，不属于设备命令
- 主页面切换
  - `Stel`
  - `MainCamera`
  - `GuiderCamera`
  - 这类切换主要是前端状态和画布切换，不直接发停机命令
- 部分图表操作
  - 清空图表
  - 缩放范围
  - 主要是前端图表行为

### 半成品或未完全挂载的部分

- `FocuserPanel.vue` 中有多处旧按钮已注释
- `gui.vue` 中有一部分极轴、图像管理相关 UI 被注释
- 有日志、调试、系统相关能力，但不全是完整的独立主模式

## 4. 左上角模式切换最终是否就是 4 个模式

按当前真实代码，不是 4 个主模式，而是 3 个主页面加若干叠加面板。

当前真正的主页面切换是：

- `Stel`
- `MainCamera`
- `GuiderCamera`

其中：

- “星图 + 赤道仪”基本对应 `Stel`
- “相机拍摄”基本对应 `MainCamera`
- “导星”基本对应 `GuiderCamera`
- “调焦”不是主页面，而是叠加面板 `showFocuserPanel`

因此，当前代码结构不是：

- 星图 + 赤道仪
- 相机拍摄
- 导星
- 调焦

而更接近：

- 星图页面
- 主相机页面
- 导星页面
- 调焦作为独立弹出面板

另外还存在：

- 设置相关抽屉和对话框
- 系统操作相关对话框
- 日志 / 调试面板

但这些不是左上角主模式的一部分。

## 5. 第三张图里几个看不清的点确认

这里需要区分“图稿原型层”和“代码里真实业务层”。

### 5.1 星图 + 赤道仪模式左侧最下面那个“??”是什么

如果指的是新壳左侧竖排四个模式小按钮里的最下面一个：

- 当前代码里仍是占位
- 只有内部标记：`L-Mode-4`
- 没有正式业务名称

如果指的是左侧三颗较大的功能按钮中的最下面一个：

- 对应的是 `Focus`

### 5.2 相机拍摄模式左侧第 3 个按钮“?? 待定”是什么

按当前代码，对应的是：

- `Focus`

### 5.3 导星模式右侧中间那个是不是“导星相机增益”

按当前代码，不应直接认定为“导星相机增益”。

当前代码里写的是：

- `ISO`

并且这一按钮目前仍未绑定真实业务逻辑，所以更像：

- 原型占位文案

而不是已经定稿的：

- `Guider Gain`

### 5.4 调焦模式右侧两个参数按钮到底是“速度 / 步长”还是别的

按真实调焦面板代码，不是“速度 / 步长”这对。

当前调焦逻辑里更明确的是：

- `SpeedChange` 对应调焦速度
- `ROIChange` 对应 ROI / 红框尺寸

`MoveSteps` 虽然存在于调焦逻辑中，但不是图稿里那两个参数按钮所直接对应的这一对。

因此当前更准确的说法是：

- 右侧两个参数按钮更接近“速度 + ROI”

## 6. 新 UI 里现在哪些按钮已经有控件但没绑定逻辑，哪些控件还没做

### 已有控件但没有绑定真实业务逻辑的部分

新壳层 `src/app/shell/*` 中，大量按钮已经画出来，但还没有接业务。

主要包括：

- 左侧 4 个模式按钮
- 左侧 3 个功能按钮
  - `Guiding`
  - `Tracking`
  - `Focus`
- 左下角
  - `RA-`
  - `DEC-`
- 右侧 3 个圆按钮
  - 其中中间显示为 `ISO`
- 右侧 4 个工具按钮
- 右下角
  - `RA+`
  - `DEC+`
- 底栏 4 个标签
  - `Guiding`
  - `Focus`
  - `Histogram`
  - `Diagonal`

### 已有少量交互但仍不属于完整业务逻辑的部分

- 左右两侧的 `D-Chart`
  - 目前只是切换 `toggleDockerChartParams`
- 底栏 `Expand / Compact`
  - 目前只是切换高度

### 还没做完整的部分

新壳中尚未完成完整联动的包括：

- 模式切换联动
- 赤道仪控制联动
- 相机参数联动
- 导星参数联动
- 调焦参数联动
- 设置 / 系统 / 日志在新壳中的完整入口

### 当前新 UI 的真实状态

当前新 UI 更像是：

- 新视觉外壳已搭好
- 旧业务逻辑仍在底层运行
- 新壳上的很多按钮还只是视觉原型

## 7. 设备通信层现在怎么调用

当前前端侧主路径不是直接串口，不是直接 SDK，也不是单纯 store dispatch。

更准确的调用链是：

`Vue 组件 -> 事件总线 $bus -> App.vue -> WebSocket -> Qt/后端 -> 后端再调 INDI / SDK / 设备驱动`

具体分层如下：

- 前端组件触发
  - `this.$bus.$emit('AppSendMessage', 'Vue_Command', '...')`
- `App.vue` 统一监听并封装消息
- 通过浏览器原生 `WebSocket` 发送 JSON 给后端
- 后端再决定调用哪类设备层

辅助机制：

- `Vuex deviceManager`
  - 主要负责设备是否繁忙
  - 控制前端功能互斥
  - 不是底层通信通道

因此，如果在“串口 / socket / sdk / 命令总线 / store dispatch”里选一个最接近当前前端实现的说法，应当是：

- 前端主通道是 `WebSocket`
- 前端内部通过事件总线分发
- SDK / INDI / 驱动调用发生在后端

## 8. 模式切换时的安全规则是什么

### 8.1 页面模式切换

当前代码里，页面模式切换本身偏向 UI 切换，不够严格。

也就是说：

- `Stel -> MainCamera -> GuiderCamera` 切换时
- 没有看到统一的“正在导星 / 拍摄 / 调焦时禁止切模式”
- 也没有看到统一的“切模式前必须先停机”
- 也没有统一的模式切换确认框

当前更像是：

- 改前端状态
- 切换显示面板
- 触发 `showCanvas`

### 8.2 连接模式切换

连接模式切换的规则要严格得多。

当前规则包括：

- 设备已连接时，不允许直接切换连接模式
- 必须先断开，再切换
- 如果主相机和导星共用同一驱动，不允许一边 `SDK` 一边 `INDI`
- 若违反规则，会回滚 UI 并弹警告

### 8.3 功能互斥

通过 `deviceManager`，系统会对一些相机类功能做互斥约束，例如：

- 拍摄
- 自动对焦
- 极轴相关流程
- 其它相机占用型任务

当设备正忙时，会阻止新的操作并弹提示。

### 8.4 危险动作确认

对于一些高风险动作，代码里有确认框，例如：

- 断开全部设备
- 某些自动对焦流程
- 导星重校准
- 关机

### 当前可归纳为

当前安全规则不是“一套统一的模式切换安全状态机”，而是：

- 页面切换较松
- 连接模式切换较严
- 具体危险操作单独确认
- 相机类功能通过互斥机制拦截

## 当前仍不完全确定的点

以下内容仅凭静态代码无法 100% 确认：

- 新图稿中某些占位按钮的最终产品命名
- 新壳里 `ISO` 最终是否会改成导星增益或其它参数
- 页面切换时后端是否还有隐藏监听做了自动停机
- 某些被注释或未挂载控件是否仍计划恢复

## 简短结论

当前项目并不是“新 UI 已完整替代旧 UI”，而是：

- 旧 UI 业务逻辑仍然是主干
- 新 UI 主要完成了视觉外壳和布局雏形
- 很多新壳按钮还没有真正接到设备命令
- 真正可靠的设备控制逻辑，当前仍主要在旧业务组件和 `App.vue` 里

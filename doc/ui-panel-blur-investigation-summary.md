# UI Panel Blur Investigation Summary

## 背景

本轮工作目标是让 `L-Panel` / `R-Panel` 呈现接近设计稿的磨砂玻璃效果，尤其是：

- 面板内部应有明显的背景模糊
- 面板材质应为半透明磨砂，而不是单纯变暗
- 左右异形轮廓应保持当前 SVG 对齐关系

相关核心文件：

- `apps/web-frontend/src/app/shell/LeftControlWing.vue`
- `apps/web-frontend/src/app/shell/RightControlWing.vue`
- `apps/web-frontend/src/app/shell/BottomDock.vue`
- `apps/web-frontend/src/assets/images/panel_trace_simplified.svg`
- `apps/web-frontend/src/assets/images/panel_fill_mask.svg`

## 已确认的事实

### 1. 底部 Dock 的模糊是正常可见的

`BottomDock.vue` 使用的是普通矩形 DOM：

- `background: linear-gradient(...)`
- `backdrop-filter: blur(20px)`
- `overflow: hidden`

该面板的背景模糊效果是明显可见的。

这说明：

- 当前浏览器/运行环境并非完全不支持 `backdrop-filter`
- 问题更可能出在左右异形 panel 的实现路径，而不是 blur 参数本身

### 2. 左右 panel 下方是 canvas / WebGL 视口

项目底层视口来自：

- `#stel-canvas`
- `#mainCamera-canvas`
- `#guiderCamera-canvas`

这些 canvas 在 `App.vue` 中管理，属于 legacy viewport。

这意味着：

- 左右 panel 的“背景”并不是普通 DOM 背景图层
- 对 canvas / WebGL 内容做异形磨砂，浏览器兼容性和图层行为都更敏感

## 本轮尝试过的方法

### A. 直接使用线稿 SVG 作为 mask

做法：

- 左右 panel 最初直接引用 `panel_trace_simplified.svg`
- 在伪元素上叠加半透明背景和 `backdrop-filter`

结果：

- 只能表现轮廓线区域
- 面板内部因为线稿是空的，基本没有完整磨砂填充

结论：

- 线稿 SVG 适合做几何参考
- 不适合直接做整块材质遮罩

### B. 改为实心 SVG mask

做法：

- 新增 `panel_fill_mask.svg`
- 将左右 panel 的材质层切换为实心轮廓遮罩

结果：

- 面板可完整填充材质
- 但模糊感仍然不明显

结论：

- “无填充”问题解决了
- 但 `mask + backdrop-filter` 这条链路在当前页面里没有得到理想模糊效果

### C. 调整 glassmorphism 参数

做法：

- 参考用户提供的 glassmorphism DEMO
- 调整过多轮：
  - `rgba(255,255,255,0.06)` 风格基底
  - `blur(20px)` 到 `blur(34px)`
  - 不同高光层、内阴影、边缘描边
  - 去除斜纹层

结果：

- 面板视觉材质会变化
- 但用户反馈核心问题始终未解决：
  - “斜线已消失”
  - “模糊感还是一点都没有”

结论：

- 问题不在材质参数微调
- 问题在模糊实现路径本身

### D. 改为真实 DOM glass layer

做法：

- 在 panel 内部增加真实 DOM `glass` / `gloss` 图层
- 将 `backdrop-filter` 从伪元素迁移到真实节点

结果：

- 左右 panel 一度消失

结论：

- 当前环境下，`external SVG mask + real DOM layer` 这条链路不稳定
- 已回退，未继续采用

### E. 从 `mask-image` 改为 `clip-path`

做法：

- 将左右 panel 的异形裁切从 `mask-image` 改为 CSS `clip-path: path(...)`
- 保留半透明材质和 `backdrop-filter`

结果：

- 面板可见
- 但用户确认：`可见没有模糊`

结论：

- `clip-path + backdrop-filter` 在当前页面中也未解决问题
- 问题仍然不是 panel 形状本身，而是背景内容未真正参与异形 blur

### F. 改为“真实采样模糊”

做法：

- 在左右 panel 中加入各自的 `blurCanvas`
- 定时从当前可见 viewport canvas 中采样对应区域
- 对采样结果使用 canvas `filter = 'blur(...)'`
- 再把结果作为 panel 底图显示

结果：

- 当前用户反馈：左右 panel 只是变暗，模糊仍然不明显

结论：

- 这条路径理论上不依赖浏览器 `backdrop-filter`
- 但目前实现中的采样/缩放/模糊强度/绘制方式还没有把 blur 拉出来
- 后续仍可继续在这条路上优化，因为它比 CSS `backdrop-filter` 更可控

## 当前判断

到目前为止，最可能的根因有两个：

### 1. 异形面板上的 `backdrop-filter` 无法稳定作用于底层 canvas 视口

证据：

- 底部矩形 Dock 的 blur 正常
- 左右异形 panel 无论是 `mask-image` 还是 `clip-path` 都没有稳定 blur

推断：

- 问题更像是“异形 blur + canvas 背景 + 当前图层结构”的组合限制

### 2. “真实采样模糊”方案还有实现强度不足的问题

证据：

- 当前已经能抓取底层 canvas
- 但实际视觉结果更像加暗层，而不是模糊层

可能原因：

- 采样缩放比例过高，导致模糊不明显
- `ctx.filter` 强度不足
- 目标 canvas 分辨率与面板显示分辨率关系不理想
- 当前取到的 source canvas 并不是视觉上最接近用户所见的最终层

## 当前建议的后续方向

建议下一轮优先走 `F. 真实采样模糊` 方案继续深入，而不是再回去调 `backdrop-filter`。

理由：

- CSS 异形 blur 路线已经验证过多次，稳定性不足
- 真实采样方案虽然当前效果不够，但理论上最可控
- 该方案不依赖浏览器对 `mask/clip-path/backdrop-filter` 与 canvas 的兼容实现

建议下一步具体尝试：

1. 显著提高采样模糊强度
   - 增大 canvas `filter: blur(...)`
   - 调整采样缩放策略，先缩小再放大

2. 明确采样源
   - 验证当前实际显示的是哪一层 canvas
   - 避免只按 `z-index` 选 canvas，必要时结合 `currentcanvas` 状态

3. 临时输出调试图层
   - 在 panel 内直接显示未裁切采样图
   - 确认采样内容是否与用户实际所见一致

4. 如真实采样仍不理想，再考虑“伪磨砂”
   - 不追求物理正确模糊
   - 直接使用低清缩放背景、局部噪声、亮暗层和半透明叠色模拟磨砂

## 验证状态

本轮所有代码修改均通过：

- `npm run build`

仍存在项目原有 warning：

- SVG 文件大小写重复
- 打包体积较大

本轮未引入新的构建错误。

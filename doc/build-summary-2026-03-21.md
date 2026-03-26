# QUARCS_stellarium-web-engine 编译总结

日期：2026-03-21

环境：

- 主机类型：VMware 虚拟机
- 系统：Ubuntu 24.04.4 LTS
- 架构：x86_64
- 内核：6.17.0-19-generic

## 目标

本次工作的目标是：

1. 在当前 Linux 虚拟机上成功编译 `QUARCS_stellarium-web-engine` 的 WebAssembly 引擎。
2. 成功编译 `apps/web-frontend` 前端页面。
3. 参考 README 启动本地服务，确认页面可访问。

## 最终结果

已经完成以下事项：

- 成功生成引擎产物：
  - `build/stellarium-web-engine.js`
  - `build/stellarium-web-engine.wasm`
- 成功编译前端产物：
  - `apps/web-frontend/dist/`
- 成功启动本地服务：
  - `http://127.0.0.1:8080`

## 本次实际使用的关键工具

- `scons`
- `emscripten 3.1.6`（Ubuntu 系统包）
- `node v18.19.1`（使用 `/usr/bin/node`）
- `npm`
- `python3-flask`

## 编译过程总结

### 1. 引擎编译

仓库 README 原本建议使用较老版本的 emsdk，例如 `1.40.1`。实际操作中，直接下载老版 emsdk 速度较慢，因此改为使用 Ubuntu 软件源中的系统包：

```bash
sudo apt-get install -y scons emscripten
```

之后在仓库根目录执行：

```bash
make js
```

首次编译没有直接通过，主要是因为该项目的构建脚本更偏向旧版 Emscripten，而当前系统提供的是较新的 `emscripten 3.1.6`。

### 2. 前端编译

前端位于：

```bash
apps/web-frontend
```

在前端构建前，先将最新编译出的引擎产物复制到前端静态资源目录：

```bash
cp build/stellarium-web-engine.js apps/web-frontend/src/assets/js/
cp build/stellarium-web-engine.wasm apps/web-frontend/src/assets/js/
```

之后在前端目录内安装依赖并构建：

```bash
cd apps/web-frontend
export PATH=/usr/bin:$PATH
npm ci || npm install
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

### 3. 启动服务

README 中的启动方式依赖 Flask 提供静态文件服务，因此额外安装：

```bash
sudo apt-get install -y python3-flask
```

然后执行：

```bash
cd apps/web-frontend
make start
```

服务成功启动后可通过以下地址访问：

```text
http://127.0.0.1:8080
```

## 遇到的问题与解决方法

### 问题 1：本机缺少 `emcc` 和 `scons`

现象：

- 执行构建前检查时发现系统中没有 `emcc`
- 同时也没有 `scons`

原因：

- 虚拟机环境未预装 WebAssembly 编译链

解决方法：

```bash
sudo apt-get install -y scons emscripten
```

结果：

- `make js` 可以开始真正进入编译流程

### 问题 2：新版 Emscripten 不接受旧构建脚本把链接参数传给编译阶段

现象：

- `make js` 报错
- 典型信息为：

```text
emcc: error: linker setting ignored during compilation: 'MODULARIZE' [-Wunused-command-line-argument] [-Werror]
```

原因：

- 原始 [SConstruct](../SConstruct) 将大量 Emscripten 参数同时放入 `CCFLAGS` 和 `LINKFLAGS`
- 旧版本工具链对此更宽松，新版本工具链会把链接专用参数出现在编译阶段视为错误

解决方法：

- 修改 [SConstruct](../SConstruct)
- 将参数拆为两类：
  - `compile_flags`
  - `link_flags`
- 仅把链接相关参数传给 `LINKFLAGS`

同时顺手修正：

- `-DGLES2 1` 改为 `-DGLES2=1`

结果：

- 编译流程可以继续推进，不再在第一批对象文件阶段失败

### 问题 3：内置旧版 zlib 在新 Clang 下因 K&R 风格函数定义触发 `-Werror`

现象：

- 在 `ext_src/zlib/*.c` 编译时失败
- 典型报错为：

```text
error: a function definition without a prototype is deprecated in all versions of C and is not supported in C2x [-Werror,-Wdeprecated-non-prototype]
```

原因：

- 项目内置的 zlib 代码风格较老
- 新版 clang 对这类旧式函数定义更严格
- 工程启用了 `-Werror`

解决方法：

- 在 [SConstruct](../SConstruct) 中对 C 编译参数增加：

```text
-Wno-error=deprecated-non-prototype
```

结果：

- 该类告警不再阻塞构建
- zlib 相关目标文件可以继续编译

### 问题 4：多个源文件存在“赋值后未使用变量”，在 `-Werror` 下导致失败

现象：

- 在 `src/modules/comets.c`
- 在 `src/modules/minorplanets.c`
- 在 `src/../ext_src/sgp4/SGP4.cpp`

均遇到类似错误：

```text
variable 'xxx' set but not used [-Werror,-Wunused-but-set-variable]
```

原因：

- 新编译器对未使用变量检查更严格
- 工程全局启用 `-Werror`

解决方法：

采取了两类处理：

1. 对明显无用的变量做源码级修复
2. 对旧三方/历史代码引发的同类问题做定向降级处理

具体修改如下：

- 在 [src/modules/comets.c](../src/modules/comets.c) 中移除了未被使用的 `line_idx`
- 在 [SConstruct](../SConstruct) 中增加：

```text
-Wno-error=unused-but-set-variable
```

并同时对 C++ 编译参数也加入了同样的兼容项。

结果：

- 编译继续推进至最终链接阶段

### 问题 5：前端使用 webpack 4，在 Node 18/OpenSSL 3 下构建报错

现象：

- 执行 `npm run build` 失败
- 典型错误：

```text
Error: error:0308010C:digital envelope routines::unsupported
```

原因：

- Vue 2 / Vue CLI 4 / webpack 4 老项目
- 在 Node 17+ 以及 OpenSSL 3 环境下，默认 hash 算法兼容性会出问题

解决方法：

构建时增加环境变量：

```bash
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

结果：

- 前端生产构建成功完成
- `dist/` 目录生成正常

### 问题 6：README 启动服务时报缺少 Flask

现象：

- 执行 `make start` 时失败
- 报错：

```text
ModuleNotFoundError: No module named 'flask'
```

原因：

- [apps/web-frontend/server.py](../apps/web-frontend/server.py) 依赖 Flask
- 当前系统中未安装该模块

解决方法：

由于 Ubuntu 24.04 对 `pip install --user` 有 PEP 668 限制，因此没有直接用 `pip`，而是使用系统包方式安装：

```bash
sudo apt-get install -y python3-flask
```

结果：

- `make start` 启动成功
- 本地 `8080` 端口可正常访问

### 问题 7：`make clean-all` 后全量重编时出现 `emscripten_longjmp_jmpbuf` 未定义

现象：

- 在执行 `make clean-all` 之后，再执行 `make build-all`
- 引擎链接阶段失败
- 典型报错包括：

```text
error: undefined symbol: emscripten_longjmp_jmpbuf
error: undefined symbol: __invoke_void_i8*_i8*
```

原因：

- 项目中的 `libtess2` 使用了 `setjmp/longjmp`
- 新版 Emscripten 在 clean 后的完整重编路径中，需要显式开启 longjmp 支持
- 之前仅修正了编译/链接参数分离，但没有把 `SUPPORT_LONGJMP` 明确补回

解决方法：

- 在 [SConstruct](../SConstruct) 中为编译和链接同时增加：

```text
-s SUPPORT_LONGJMP=emscripten
```

结果：

- `make clean-all` 后再次执行 `make build-all` 可以成功通过引擎链接阶段

### 问题 8：`npm ci` 因 lockfile 与当前 npm/workspace 解析结果不完全一致而失败

现象：

- `make build-all` 中的前端依赖安装阶段失败
- 典型报错为：

```text
npm ci can only install packages when your package.json and package-lock.json are in sync
```

原因：

- 当前仓库含有 workspace 配置
- 在当前 npm 版本下，`package-lock.json` 与解析结果并非完全一致
- `npm ci` 属于严格模式，因此直接中断

解决方法：

- 修改根目录 [Makefile](../Makefile)
- 将前端依赖安装从：

```bash
npm ci
```

改为：

```bash
npm ci || npm install
```

结果：

- 在 lockfile 完全匹配时仍优先使用 `npm ci`
- 当 `npm ci` 无法继续时，会自动回退到 `npm install`
- `make build-all` 在当前 Ubuntu 24.04 虚拟机环境下可以完整跑通

## 本次修改的文件

本次为了适配当前构建环境，修改了以下源码文件：

- [SConstruct](../SConstruct)
- [src/modules/comets.c](../src/modules/comets.c)

此外产生了新的编译输出文件，例如：

- `build/stellarium-web-engine.js`
- `build/stellarium-web-engine.wasm`
- `apps/web-frontend/dist/*`

## 构建成功后的验证结果

### 引擎产物

已生成：

- `build/stellarium-web-engine.js`
- `build/stellarium-web-engine.wasm`

### 前端产物

已生成：

- `apps/web-frontend/dist/index.html`
- `apps/web-frontend/dist/js/*`
- `apps/web-frontend/dist/css/*`
- `apps/web-frontend/dist/opencv.js`

### 服务验证

启动命令：

```bash
cd apps/web-frontend
make start
```

验证结果：

- `ss -ltnp` 确认 `0.0.0.0:8080` 正在监听
- `curl -I http://127.0.0.1:8080` 返回 `HTTP/1.1 200 OK`

## 仍然存在但不阻塞本次工作的事项

以下项目目前不影响编译和运行，但建议后续整理：

- 前端构建有 3 个 SVG 文件大小写冲突警告
- 前端构建有若干大体积资源告警
- Emscripten 链接阶段仍会提示：

```text
EXTRA_EXPORTED_RUNTIME_METHODS is deprecated
```

这不会阻塞当前构建，但后续升级 Emscripten 时建议改为新的配置方式。

## 推荐的后续优化

建议后续考虑以下优化：

1. 在前端 `package.json` 或 `Makefile` 中固化 `NODE_OPTIONS=--openssl-legacy-provider`
2. 清理前端 SVG 文件名大小写不一致问题
3. 将 `EXTRA_EXPORTED_RUNTIME_METHODS` 迁移到新版 Emscripten 推荐写法
4. 如果后续长期在 Ubuntu 24.04 上构建，可将当前适配方式作为 Linux 默认构建方案保留

## Fork 仓库后续同步官方更新的方法

本仓库当前采用的是典型 fork 工作流：

- `origin` 指向个人 fork
- `upstream` 指向官方仓库

### 一次性配置 upstream

如果本地仓库还没有配置官方远程，可执行：

```bash
git remote add upstream https://github.com/QHYCCD-QUARCS/QUARCS_stellarium-web-engine.git
git fetch upstream
```

### 推荐同步流程

后续每次同步官方更新，建议使用下面的顺序：

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

说明：

- `git fetch upstream`
  - 获取官方仓库最新提交，但不直接改动本地分支
- `git merge upstream/master`
  - 将官方最新改动合并到本地 `master`
- `git push origin master`
  - 将合并后的结果推送到自己的 fork

### 为什么推荐先 merge 再 push

如果本地已经有自己的提交，而官方仓库又新增了提交，直接 `push origin master` 很可能失败，典型报错是：

```text
! [rejected] master -> master (non-fast-forward)
```

这时说明本地分支和远端分支已经发生分叉，需要先把官方更新合并到本地，再重新推送。

### 如果出现冲突怎么办

若执行：

```bash
git merge upstream/master
```

时出现冲突，处理步骤如下：

1. 打开冲突文件，手动合并内容
2. 保存后执行：

```bash
git add <冲突文件>
git commit
```

3. 最后再执行：

```bash
git push origin master
```

### 本次实践中的结论

本次已经验证：

- 可以成功为 fork 增加 `upstream`
- 可以成功执行 `git fetch upstream`
- 可以成功将 `upstream/master` 合并到本地 `master`
- 可以成功将结果重新推送到 `origin/master`

因此后续可直接按本节流程持续同步官方仓库更新。

## 可复用命令清单

### 一次性构建

现在仓库根目录已经增加了本地一键构建入口，可直接执行：

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine
make build-all
```

这个目标会自动完成以下工作：

1. 检查本机构建依赖是否齐全
2. 编译 WebAssembly 引擎
3. 将引擎产物同步到前端目录
4. 安装前端依赖
5. 执行前端生产构建

如果依赖缺失，会在开始阶段直接报出缺少的组件，避免构建进行到一半才失败。

### 一次性构建前的前置依赖

在当前 Ubuntu 24.04 虚拟机环境中，需要保证以下依赖已安装：

```bash
sudo apt-get install -y scons emscripten python3-flask
```

同时需要系统存在：

- `/usr/bin/node`
- `/usr/bin/npm`

本次验证通过的 Node 版本为：

```text
node v18.19.1
```

### 一次性构建完成后启动服务

构建完成后，可在仓库根目录直接执行：

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine
make start-web
```

该目标会进入前端目录并调用已有的 `make start`，最终启动本地服务。

### 新增 Make 目标说明

根目录 [Makefile](../Makefile) 中新增了以下目标：

- `check-local-deps`
  - 检查 `emcc`、`scons`、`python3`、`python3-flask`、`/usr/bin/node`、`/usr/bin/npm`
- `frontend-sync-engine`
  - 先执行引擎编译，再把 `js/wasm` 拷贝到前端资源目录
- `frontend-install`
  - 在前端目录执行 `npm ci`
- `frontend-build`
  - 完成引擎同步后执行前端生产构建
- `build-all`
  - 一次性完成完整本地构建
- `start-web`
  - 启动前端静态服务

### 编译引擎

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine
make js
```

### 同步引擎到前端

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine
cp build/stellarium-web-engine.js apps/web-frontend/src/assets/js/
cp build/stellarium-web-engine.wasm apps/web-frontend/src/assets/js/
```

### 安装前端依赖

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine/apps/web-frontend
export PATH=/usr/bin:$PATH
npm ci
```

### 构建前端

```bash
cd /home/q/workspace/QUARCS_stellarium-web-engine/apps/web-frontend
export PATH=/usr/bin:$PATH
NODE_OPTIONS=--openssl-legacy-provider npm run build
```

### 启动服务

```bash
sudo apt-get install -y python3-flask
cd /home/q/workspace/QUARCS_stellarium-web-engine/apps/web-frontend
make start
```

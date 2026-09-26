# Barextender

<img src="Ice/Assets.xcassets/AppIcon.appiconset/icon_128x128.png" width="96" height="96" alt="Barextender 图标">

中文 macOS 菜单栏管理工具，主要用于隐藏不常用的图标，需要时再展开。

基于 [Ice](https://github.com/jordanbaird/Ice) 开发，采用 GPL-3.0 许可。Barextender 使用独立名称和图标，是一个独立衍生项目。

## 当前范围

- 显示、隐藏和始终隐藏三个分区。
- 点击菜单栏图标展开或收起隐藏项目，也可选择下方工具栏。
- 在设置页排列项目，设置新出现项目的插入位置。
- 中文设置和权限提示，支持登录时启动及自动收起。
- 保留 Ice 的菜单栏样式、搜索等现有能力，以及开发中的间隔符和分组。

已移除预设、条件触发器和自定义全局快捷键。原有触发器与快捷键配置不再加载或运行。

## 开发状态

当前为 **0.1.0 开发版**，提供源码，尚未发布经过公证的安装包。

本机开发环境为 Apple Silicon、macOS 15.7.3。编译、签名检查和模型测试有本地记录；模型断言不等于实际菜单栏交互验收。顶部图标点击、工具栏内点击原应用、多屏幕、缺口屏和拖拽等场景仍需要完整回归，不能据此宣称能够完全替代其他菜单栏工具。

## 本地构建

要求 macOS 14 或更高版本，以及能打开此工程的 Xcode 16 或更高版本。

```sh
git clone https://github.com/prefect12/barextender.git
cd barextender
open Barextender.xcodeproj
```

选择 `Barextender` scheme，在 Xcode 的 Signing & Capabilities 中设置自己的签名身份，然后构建。Swift Package Manager 会获取工程中固定版本的依赖。

为在多次构建间保留 macOS 权限，可使用同一个代码签名证书运行：

```sh
BAREXTENDER_SIGNING_IDENTITY="你的代码签名证书名称或 SHA-1" ./Tools/build-local.sh
```

也可以把证书选择写入本机的 `build/signing-identity.txt`；该目录已被 Git 忽略。不要提交证书、私钥或本机签名配置。

输出位置为：

```text
build/BarextenderDerivedData/Build/Products/Debug/Barextender.app
```

构建脚本检查应用签名，不安装或启动应用。重建前请退出正在运行的测试版，始终使用同一路径、bundle ID 和证书；换证书或使用临时签名可能需要重新授权。

## 使用

1. 启动自己的构建。
2. 按应用提示授予「辅助功能」权限。图标预览及下方工具栏还需要「屏幕录制」权限。
3. 打开「菜单栏项目」，把不常用的项目放入隐藏区。macOS 菜单栏也支持按住 Command 拖动图标。
4. 点击 Barextender 菜单栏图标展开或收起；右键图标可打开设置。

为了避免两个管理器同时调整项目位置，验收时请只运行一个菜单栏管理器。系统固定项目、全屏模式、显示器布局和 macOS 接口变化可能影响可隐藏项目及其位置。

## 模型测试

```sh
./Tools/Tests/run-model-tests.sh
```

现有 64 项断言覆盖权限判断、点击动作解析、工具栏请求取消、屏幕策略、图标位置恢复、新项目身份与插入位置、间隔符及分组配置保存。实际菜单栏交互需要在已授权的 Mac 上另行验收。

## 许可与归属

遵守 [GNU GPL v3](LICENSE)。上游 Ice 由 Jordan Baird 及贡献者开发；源码保留其历史、作者信息与第三方许可说明。源目录仍名为 `Ice/`，以便追踪上游变更。

应用没有配置自动更新源，不会从上游下载并替换为 Ice。问题与建议请提交至 [本项目 Issues](https://github.com/prefect12/barextender/issues)。

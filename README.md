# EyeBreather 👁️

<p align="center">
  <img src="EyeBreather/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="EyeBreather Icon">
</p>

<p align="center">
  <strong>优雅守护你的眼睛</strong><br>
  一款精美的 macOS 护眼提醒应用，基于 20-20-20 法则
</p>

<p align="center">
  <a href="https://github.com/Arkycher/EyeBreather/releases">
    <img src="https://img.shields.io/github/v/release/Arkycher/EyeBreather?style=flat-square" alt="Release">
  </a>
  <a href="https://github.com/Arkycher/EyeBreather/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/Arkycher/EyeBreather?style=flat-square" alt="License">
  </a>
  <img src="https://img.shields.io/badge/platform-macOS%2014%2B-blue?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?style=flat-square" alt="Swift">
</p>

---

## 预览

<!-- 
  请将应用截图放到 docs/images/ 目录下，然后取消下面的注释
  建议图片：菜单栏、休息界面（毛玻璃）、设置界面
-->

<!--
<p align="center">
  <img src="docs/images/menubar.png" width="300" alt="菜单栏">
  <img src="docs/images/break-blur.png" width="300" alt="休息界面">
</p>
-->

> 🎨 精美的毛玻璃休息界面 · 🧠 智能检测自动暂停 · 🔒 完全离线运行

## 什么是 20-20-20 法则？

每隔 **20 分钟**，休息 **20 秒**，看向 **20 英尺**（约 6 米）外的地方。

这是眼科医生推荐的简单有效的护眼方法，能够有效缓解长时间用眼带来的疲劳。

## 功能特性

### 🎯 智能休息提醒

- **20-20-20 法则**：科学的护眼周期设置
- **可自定义时长**：灵活调整工作和休息时间
- **休息预警**：休息前 60 秒提前通知，不打断思路

### 🔄 三种提醒模式

| 模式 | 特点 | 适合人群 |
|:---:|:---|:---|
| **温和** | 可跳过或延迟 | 需要灵活控制的用户 |
| **强制** | 必须完成休息 | 需要严格执行的用户 |
| **渐进** | 跳过多次后自动强制 | 想逐步养成习惯的用户 |

### 🧠 智能检测

- **活动检测**：检测鼠标/键盘，空闲时自动暂停计时
- **会议检测**：检测摄像头/麦克风使用，会议中自动暂停
- **专注应用**：Zoom、腾讯会议等运行时自动暂停

### 💎 精美休息界面

| 毛玻璃 | 液态玻璃 | 桌面壁纸 | 深色模式 | 自定义 |
|:---:|:---:|:---:|:---:|:---:|
| 柔和模糊效果 | macOS 26 特效 | 使用你的壁纸 | 纯黑背景 | 你喜欢的图片 |

### ✨ 更多特性

- 📊 休息统计数据与可视化
- 🌙 勿扰时段设置
- 🚀 开机自启动
- 🎨 深色/浅色/跟随系统主题
- 🖥️ 多显示器支持

## 系统要求

- macOS 14.0 (Sonoma) 或更高版本
- Apple Silicon 或 Intel 处理器

## 安装

### 方式一：下载安装包（推荐）

1. 前往 [Releases](https://github.com/Arkycher/EyeBreather/releases) 页面
2. 下载最新版本的 `.dmg` 文件
3. 打开 DMG，将 EyeBreather 拖入 Applications 文件夹
4. 首次打开时，右键点击应用 → 打开 → 点击「打开」

### 方式二：从源码构建

```bash
# 克隆仓库
git clone https://github.com/Arkycher/EyeBreather.git
cd EyeBreather

# 使用构建脚本（需要先安装 create-dmg）
brew install create-dmg
./scripts/build.sh
```

构建产物位于 `dist/` 目录。

## 使用说明

1. 启动应用后，菜单栏会显示眼睛图标 👁️
2. 点击图标可查看当前计时状态和今日统计
3. 点击「设置」进入偏好设置
4. 根据个人习惯调整工作时长、休息时长和提醒模式

## 隐私说明

EyeBreather 完全离线运行，**不会收集或上传任何用户数据**。

- 🔒 活动检测仅用于判断是否暂停计时
- 🔒 摄像头/麦克风检测仅用于判断是否在会议中
- 🔒 所有设置和统计数据仅存储在本地

## 开发

```bash
# 使用 Xcode 打开项目
open EyeBreather.xcodeproj
```

技术栈：
- Swift 5.9 + SwiftUI
- SwiftData 数据持久化
- 纯原生实现，无第三方依赖

## 许可证

[MIT License](LICENSE)

## 致谢

- 💡 灵感来源：20-20-20 护眼法则
- 🎨 设计参考：macOS 原生应用设计规范

---

<p align="center">
  如果这个项目对你有帮助，欢迎 ⭐️ Star 支持！
</p>

# EyeBreather 设计文档

> macOS 原生护眼应用，帮助用户养成健康的用眼习惯

## 概述

EyeBreather 是一款 macOS 原生护眼应用，采用 Swift + SwiftUI 开发，核心功能包括：

1. **定时休息提醒** - 基于 20-20-20 法则，可配置强制/温和/渐进模式
2. **屏幕时间管理** - 基于活动检测的精准使用时长统计

## 核心功能

### 定时休息提醒

- 默认采用 **20-20-20 法则**：每工作 20 分钟，提醒休息 20 秒，看向 20 英尺（约 6 米）外
- 工作时长和休息时长均可自定义
- 提醒模式三选一：
  - **强制模式**：全屏遮罩，必须完成休息
  - **温和模式**：弹出通知，可选择稍后提醒
  - **渐进模式**：先温和，多次跳过后变强制
- **休息预警**：提前提醒用户即将休息，不打断思路
- **延迟选项**：温和模式下提供 5 分钟/15 分钟/完成当前任务后等选项

### 屏幕时间管理

- 基于鼠标/键盘活动检测，空闲时不计入使用时长
- 统计每日总使用时长、休息次数、完成率
- 保存休息历史记录
- 支持数据导出（CSV/JSON）

### 智能检测

- **全屏应用检测**：自动检测全屏应用（视频、游戏、PPT 演示）暂停提醒
- **应用白名单**：指定某些应用运行时不打扰（如 Zoom、腾讯会议）

### 休息界面

可配置的休息遮罩样式：
- 纯黑/深色遮罩 + 倒计时
- 护眼提示界面（眼部放松技巧）
- 动画/视觉引导（眼球运动）
- 自然风景/远景图片
- 自定义背景图片

### 应用呈现

- 默认菜单栏常驻，可切换是否显示 Dock 图标
- 完整独立窗口展示设置和统计
- 外观跟随系统（深色/浅色模式）
- 支持多显示器（休息时所有屏幕同时遮罩）

### 其他功能

- 开机自启动
- 勿扰模式（手动暂停）
- 休息历史记录
- 数据导出

## 应用架构

```
EyeBreather/
├── App/                     # 应用入口
│   ├── EyeBreatherApp.swift # @main 入口
│   └── AppDelegate.swift    # 菜单栏、全局事件等
├── Features/                # 功能模块
│   ├── Timer/               # 计时与休息提醒
│   ├── Statistics/          # 屏幕时间统计
│   ├── Settings/            # 设置管理
│   └── Break/               # 休息界面
├── Core/                    # 核心服务
│   ├── ActivityMonitor/     # 用户活动检测（鼠标/键盘）
│   ├── AppDetector/         # 全屏应用检测
│   ├── NotificationManager/ # 通知管理
│   └── DataStore/           # 数据持久化
├── Shared/                  # 共享组件
│   ├── Models/              # 数据模型
│   ├── Extensions/          # 扩展
│   └── Utils/               # 工具类
└── Resources/               # 资源文件
    ├── Assets/              # 图片、图标
    └── Sounds/              # 音效（可选）
```

### 核心模块职责

| 模块 | 职责 |
|-----|------|
| **TimerManager** | 管理工作/休息计时，处理暂停、延迟、重置逻辑 |
| **ActivityMonitor** | 监听系统事件，判断用户是否活跃 |
| **AppDetector** | 检测当前前台应用，判断是否全屏、是否在白名单 |
| **BreakWindowController** | 管理休息界面窗口，支持多显示器 |
| **StatisticsStore** | 记录和聚合使用统计数据 |

## 界面设计

### 菜单栏弹出界面

```
┌─────────────────────────────┐
│  👁️ EyeBreather             │
├─────────────────────────────┤
│  下次休息：12:35 (8 分钟后)   │
│  ━━━━━━━━━━━━░░░░  60%      │
├─────────────────────────────┤
│  📊 今日统计                 │
│  使用时长：3h 24m            │
│  休息次数：8/10              │
│  完成率：80%                 │
├─────────────────────────────┤
│  ⏸️ 暂停 15 分钟             │
│  ▶️ 立即休息                 │
├─────────────────────────────┤
│  ⚙️ 设置...    📊 统计...    │
│  ❌ 退出                     │
└─────────────────────────────┘
```

### 主窗口 - 统计页面

- **今日概览**：使用时长、休息完成率、活跃时段分布
- **历史记录**：日历视图 + 列表视图切换，显示每次休息记录
- **数据导出**：支持导出为 CSV/JSON

### 主窗口 - 设置页面

| 分类 | 设置项 |
|-----|-------|
| **休息规则** | 工作时长、休息时长、提醒模式（强制/温和/渐进）、休息预警时间 |
| **智能检测** | 启用活动检测、空闲重置阈值、全屏暂停、应用白名单管理 |
| **休息界面** | 样式选择（黑屏/提示/动画/风景/自定义）、自定义背景图片 |
| **通用** | 开机自启、显示 Dock 图标、外观模式、延迟选项设置 |
| **数据** | 查看存储位置、清除数据、导出数据 |

### 休息遮罩界面

- 全屏覆盖所有显示器
- 居中显示倒计时 + 当前休息样式内容
- 强制模式：无跳过按钮（或需长按解锁）
- 温和模式：显示"跳过"和"延迟 X 分钟"按钮

## 数据模型

### 核心模型

```swift
// 提醒模式
enum ReminderMode {
    case forced      // 强制
    case gentle      // 温和
    case progressive // 渐进
}

// 休息界面样式
enum BreakStyle {
    case dark           // 纯黑
    case tips           // 护眼提示
    case animation      // 动画引导
    case scenery        // 自然风景
    case custom         // 自定义背景
}

// 外观模式
enum AppearanceMode {
    case system  // 跟随系统
    case light   // 浅色
    case dark    // 深色
}

// 用户设置
struct AppSettings {
    var workDuration: Int          // 工作时长（分钟），默认 20
    var breakDuration: Int         // 休息时长（秒），默认 20
    var reminderMode: ReminderMode // 强制/温和/渐进
    var preBreakWarning: Int       // 休息预警（秒），默认 60
    var delayOptions: [Int]        // 延迟选项（分钟），如 [5, 15, 30]
    
    var enableActivityDetection: Bool  // 活动检测
    var idleResetThreshold: Int        // 空闲重置阈值（分钟），默认 5
    var enableFullscreenPause: Bool    // 全屏暂停
    var whitelistApps: [String]        // 白名单应用 Bundle ID
    
    var breakStyle: BreakStyle         // 休息界面样式
    var customBackgroundPath: String?  // 自定义背景路径
    
    var launchAtLogin: Bool            // 开机自启
    var showInDock: Bool               // 显示 Dock 图标
    var appearance: AppearanceMode     // 外观模式
}

// 休息记录
struct BreakRecord {
    let id: UUID
    let startTime: Date
    let duration: Int           // 实际休息时长（秒）
    let expectedDuration: Int   // 预期时长
    let completed: Bool         // 是否完成
    let skipped: Bool           // 是否跳过
}

// 每日统计
struct DailyStatistics {
    let date: Date
    var totalActiveTime: Int    // 活跃时长（秒）
    var breakRecords: [BreakRecord]
    var completedBreaks: Int
    var skippedBreaks: Int
}
```

### 存储方案

| 数据类型 | 存储方式 | 说明 |
|---------|---------|------|
| **设置** | UserDefaults | 轻量、系统原生支持 |
| **休息记录** | SwiftData | 苹果官方方案，与 SwiftUI 深度集成 |
| **自定义背景** | Application Support 目录 | 用户文件存储 |

### 数据保留策略

- 详细记录保留 **90 天**
- 每日聚合统计 **永久保留**
- 用户可手动清除历史数据

## 技术要点

### macOS 系统 API 使用

| 功能 | 技术方案 |
|-----|---------|
| **菜单栏应用** | `NSStatusItem` + `NSPopover` |
| **多显示器遮罩** | `NSScreen.screens` 遍历，每个屏幕创建全屏 `NSWindow` |
| **显示器热插拔** | 监听 `NSApplication.didChangeScreenParametersNotification` |
| **活动检测** | `CGEventTap` 监听鼠标/键盘事件，或 `NSEvent.addGlobalMonitorForEvents` |
| **全屏应用检测** | `NSWorkspace` 监听应用切换 + 检查窗口 `styleMask` |
| **系统睡眠/唤醒** | 监听 `NSWorkspace.willSleepNotification` / `didWakeNotification` |
| **开机自启动** | `SMAppService` (macOS 13+) |
| **系统通知** | `UserNotifications` 框架 |
| **外观跟随** | 监听 `AppleInterfaceThemeChangedNotification` |
| **数据持久化** | SwiftData + `@Model` 宏 |

### 权限需求

| 权限 | 用途 | 申请时机 |
|-----|------|---------|
| **辅助功能** | 全局监听键盘/鼠标事件用于活动检测 | 首次启用活动检测时 |
| **通知** | 发送休息提醒通知 | 首次启动时 |

### 最低系统要求

- **macOS 14.0 (Sonoma)** 或更高
- 使用 SwiftUI 5+ 和 SwiftData 特性

## 边界情况处理

### 长时间离开电脑

当用户长时间不操作电脑时：

| 场景 | 处理策略 |
|-----|---------|
| 空闲时间 < 工作周期 | 暂停计时，回来后继续 |
| 空闲时间 >= 空闲重置阈值 | 自动重置计时器，视为新的工作周期 |

- **空闲重置阈值**：默认 5 分钟，可在设置中调整
- 实现方式：`ActivityMonitor` 记录最后活动时间，检测到活动恢复时计算空闲时长

### 系统睡眠/唤醒

当电脑从睡眠中唤醒时：

```
唤醒时检查：
├── 计算睡眠时长 = 当前时间 - 睡眠前时间
├── 如果睡眠时长 >= 空闲重置阈值
│   └── 重置计时器，开始新的工作周期
└── 如果睡眠时长 < 空闲重置阈值
    └── 继续之前的计时（补偿睡眠时间）
```

- 监听 `NSWorkspace.willSleepNotification` 记录睡眠时间
- 监听 `NSWorkspace.didWakeNotification` 处理唤醒逻辑

### 显示器热插拔

休息遮罩需要覆盖所有显示器，当显示器配置变化时：

| 事件 | 处理策略 |
|-----|---------|
| 新显示器接入 | 立即为新显示器创建遮罩窗口 |
| 显示器断开 | 销毁对应的遮罩窗口 |
| 分辨率/排列变化 | 调整遮罩窗口尺寸和位置 |

- 监听 `NSApplication.didChangeScreenParametersNotification`
- `BreakWindowController` 维护 `[NSScreen: NSWindow]` 映射，动态增删

## 测试策略

| 测试类型 | 覆盖范围 |
|---------|---------|
| **单元测试** | 计时逻辑、数据模型、统计计算、空闲重置逻辑 |
| **集成测试** | SwiftData 存储读写、设置同步 |
| **UI 测试** | 关键流程（休息触发、设置修改） |
| **手动测试** | 多显示器热插拔、全屏应用检测、系统睡眠唤醒、系统权限 |

## 下一步

1. 创建 Xcode 项目
2. 制定详细实施计划
3. 按 TDD 方式逐步实现各模块

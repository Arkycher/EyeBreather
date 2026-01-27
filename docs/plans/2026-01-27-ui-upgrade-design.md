# EyeBreather UI 升级设计

## 概述

本次升级包含三个主要部分：
1. 智能暂停系统（取代全屏检测）
2. 菜单栏 UI 重设计（圆环式 + 磨砂玻璃）
3. 设置界面改进（侧边栏式）

---

## 一、智能暂停系统

### 1.1 会议检测（自动）

监听系统摄像头/麦克风使用状态：
- 检测到使用时：自动暂停，状态显示"会议中"
- 结束使用后：自动恢复计时

**实现方式**：
- 使用 `AVCaptureDevice.authorizationStatus` 检查权限
- 使用 `CMIOObjectPropertySelector` 检测摄像头活动状态
- 定时轮询（每 5 秒）检查状态

### 1.2 专注模式应用列表

**预设应用**（可删除）：
- 会议：Zoom、腾讯会议、飞书、钉钉、Teams
- 视频：VLC、IINA、爱奇艺、Netflix、腾讯视频、哔哩哔哩
- 游戏：Steam、Epic Games Launcher

**智能推荐**：
- 检测到新的全屏应用时，发送通知询问"是否添加到专注列表？"

**手动添加**：
- 从运行中应用列表选择

### 1.3 数据结构

```swift
struct FocusApp: Codable, Identifiable, Equatable {
    var id: String { bundleId }
    let bundleId: String
    let name: String
    let isPreset: Bool
}
```

---

## 二、菜单栏 UI 重设计

### 2.1 视觉风格

- **磨砂玻璃背景**：使用 `.regularMaterial`，自动跟随系统深浅色
- **圆角设计**：统一使用 12pt 圆角
- **阴影效果**：柔和阴影提升层次感

### 2.2 布局设计（极简圆环式）

```
┌──────────────────────────────┐
│                              │
│        ╭─────────╮           │
│       ╱   18:32   ╲          │  ← 圆环进度 + 居中倒计时
│      │             │         │
│       ╲  下次休息  ╱          │
│        ╰─────────╯           │
│                              │
│    工作中 ● ─────────────     │  ← 状态 + 细线进度条
│                              │
│  ┌──────┐      ┌──────────┐  │
│  │ 暂停 │      │ 立即休息  │  │  ← 胶囊按钮
│  └──────┘      └──────────┘  │
│                              │
│  今日 2h 15m  ·  休息 6/8    │  ← 底部小字统计
│                              │
│  ⚙️        📊        ✕       │  ← 图标按钮
└──────────────────────────────┘
```

### 2.3 状态颜色

- 🟢 绿色：工作中
- 🟠 橙色：已暂停 / 会议中
- 🔵 蓝色：休息中
- 🟡 黄色：即将休息

### 2.4 圆环组件

```swift
struct CircularProgressView: View {
    let progress: Double  // 0.0 - 1.0
    let timeText: String
    let subtitle: String
    let color: Color
}
```

---

## 三、设置界面改进

### 3.1 布局结构

改为侧边栏式（类似系统设置）：

```
┌─────────────────────────────────────────────────┐
│  EyeBreather 设置                          ✕    │
├─────────────┬───────────────────────────────────┤
│             │                                   │
│  ⏱️ 休息规则  │   （右侧内容区）                   │
│             │                                   │
│  🎯 智能暂停  │                                   │
│             │                                   │
│  🎨 外观     │                                   │
│             │                                   │
│  ⚙️ 通用     │                                   │
│             │                                   │
└─────────────┴───────────────────────────────────┘
```

### 3.2 各设置页内容

**休息规则**：
- 工作时长滑块
- 休息时长滑块
- 提醒模式选择
- 休息预警开关

**智能暂停**：
- 会议检测开关
- 专注模式应用列表
- 智能推荐开关

**外观**：
- 外观模式（跟随系统/浅色/深色）
- 休息界面样式
- 自定义背景

**通用**：
- 开机自启
- 显示 Dock 图标
- 延迟选项配置

---

## 四、技术实现要点

### 4.1 摄像头/麦克风检测

```swift
class MediaDeviceMonitor: ObservableObject {
    @Published var isCameraInUse: Bool = false
    @Published var isMicrophoneInUse: Bool = false
    
    // 使用 CoreMediaIO 检测摄像头状态
    // 使用 AVAudioSession 或类似 API 检测麦克风
}
```

### 4.2 磨砂玻璃效果

```swift
.background(.regularMaterial)
.clipShape(RoundedRectangle(cornerRadius: 12))
```

### 4.3 预设应用 Bundle ID

```swift
static let presetFocusApps: [FocusApp] = [
    // 会议
    FocusApp(bundleId: "us.zoom.xos", name: "Zoom", isPreset: true),
    FocusApp(bundleId: "com.tencent.meeting", name: "腾讯会议", isPreset: true),
    FocusApp(bundleId: "com.bytedance.lark", name: "飞书", isPreset: true),
    FocusApp(bundleId: "com.alibaba.DingTalkMac", name: "钉钉", isPreset: true),
    FocusApp(bundleId: "com.microsoft.teams", name: "Teams", isPreset: true),
    
    // 视频
    FocusApp(bundleId: "org.videolan.vlc", name: "VLC", isPreset: true),
    FocusApp(bundleId: "com.colliderli.iina", name: "IINA", isPreset: true),
    FocusApp(bundleId: "com.bilibili.bili", name: "哔哩哔哩", isPreset: true),
    
    // 游戏
    FocusApp(bundleId: "com.valvesoftware.steam", name: "Steam", isPreset: true),
    FocusApp(bundleId: "com.epicgames.EpicGamesLauncher", name: "Epic Games", isPreset: true),
]
```

---

## 五、实施优先级

1. **P0 - 核心功能**
   - 移除全屏检测逻辑
   - 实现专注模式应用列表
   - 实现会议检测

2. **P1 - UI 改进**
   - 菜单栏圆环式布局
   - 磨砂玻璃效果

3. **P2 - 设置改进**
   - 侧边栏式设置界面
   - 智能暂停设置页

4. **P3 - 智能推荐**
   - 全屏应用检测提示

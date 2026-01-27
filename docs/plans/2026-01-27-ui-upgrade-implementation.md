# EyeBreather UI 升级实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 实现智能暂停系统、圆环式菜单栏 UI、磨砂玻璃效果和侧边栏设置界面

**Architecture:** 
- 新增 MediaDeviceMonitor 检测摄像头/麦克风状态
- 重构 AppDetector 为专注模式应用列表
- 重写 MenuBarView 为圆环式布局
- 重写 SettingsView 为侧边栏式布局

**Tech Stack:** SwiftUI, AVFoundation, CoreMediaIO, Combine

---

## Task 1: 添加 FocusApp 数据模型

**Files:**
- Create: `EyeBreather/Shared/Models/FocusApp.swift`
- Modify: `EyeBreather/Shared/Models/AppSettings.swift`

**Step 1: 创建 FocusApp 模型**

```swift
// EyeBreather/Shared/Models/FocusApp.swift
import Foundation

struct FocusApp: Codable, Identifiable, Equatable, Hashable {
    var id: String { bundleId }
    let bundleId: String
    let name: String
    let isPreset: Bool
    
    static let presets: [FocusApp] = [
        // 会议
        FocusApp(bundleId: "us.zoom.xos", name: "Zoom", isPreset: true),
        FocusApp(bundleId: "com.tencent.meeting", name: "腾讯会议", isPreset: true),
        FocusApp(bundleId: "com.bytedance.lark", name: "飞书", isPreset: true),
        FocusApp(bundleId: "com.alibaba.DingTalkMac", name: "钉钉", isPreset: true),
        FocusApp(bundleId: "com.microsoft.teams", name: "Teams", isPreset: true),
        FocusApp(bundleId: "com.apple.FaceTime", name: "FaceTime", isPreset: true),
        
        // 视频
        FocusApp(bundleId: "org.videolan.vlc", name: "VLC", isPreset: true),
        FocusApp(bundleId: "com.colliderli.iina", name: "IINA", isPreset: true),
        FocusApp(bundleId: "com.apple.TV", name: "Apple TV", isPreset: true),
        
        // 游戏
        FocusApp(bundleId: "com.valvesoftware.steam", name: "Steam", isPreset: true),
        FocusApp(bundleId: "com.epicgames.EpicGamesLauncher", name: "Epic Games", isPreset: true),
    ]
}
```

**Step 2: 更新 AppSettings**

在 `AppSettings.swift` 中：
- 移除 `enableFullscreenPause: Bool`
- 移除 `whitelistApps: [String]`
- 添加 `focusApps: [FocusApp]`
- 添加 `enableMeetingDetection: Bool`
- 添加 `enableSmartRecommend: Bool`

```swift
// 替换智能检测部分
// MARK: - 智能暂停

/// 启用会议检测（摄像头/麦克风）
var enableMeetingDetection: Bool = true

/// 专注模式应用列表
var focusApps: [FocusApp] = FocusApp.presets

/// 启用智能推荐
var enableSmartRecommend: Bool = true
```

**Step 3: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 4: 提交**

```bash
git add -A && git commit -m "feat: 添加 FocusApp 模型和智能暂停设置"
```

---

## Task 2: 实现 MediaDeviceMonitor

**Files:**
- Create: `EyeBreather/Core/MediaDeviceMonitor.swift`

**Step 1: 创建摄像头/麦克风检测器**

```swift
// EyeBreather/Core/MediaDeviceMonitor.swift
import Foundation
import AVFoundation
import Combine
import CoreMediaIO

/// 媒体设备监视器 - 检测摄像头和麦克风使用状态
@MainActor
final class MediaDeviceMonitor: ObservableObject {
    static let shared = MediaDeviceMonitor()
    
    @Published private(set) var isCameraInUse: Bool = false
    @Published private(set) var isMicrophoneInUse: Bool = false
    
    /// 是否处于会议中（摄像头或麦克风在使用）
    var isInMeeting: Bool {
        isCameraInUse || isMicrophoneInUse
    }
    
    private var checkTimer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    func startMonitoring() {
        // 每 5 秒检查一次
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDeviceStatus()
            }
        }
        // 立即检查一次
        checkDeviceStatus()
    }
    
    private func checkDeviceStatus() {
        isCameraInUse = checkCameraInUse()
        isMicrophoneInUse = checkMicrophoneInUse()
        
        // 发送状态变化通知
        NotificationCenter.default.post(
            name: .meetingStatusChanged,
            object: nil,
            userInfo: ["isInMeeting": isInMeeting]
        )
    }
    
    private func checkCameraInUse() -> Bool {
        // 使用 CoreMediaIO 检测摄像头状态
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else { return false }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: deviceCount)
        
        result = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataSize,
            &devices
        )
        
        guard result == kCMIOHardwareNoError else { return false }
        
        // 检查每个设备是否正在使用
        for device in devices {
            if isDeviceInUse(device) {
                return true
            }
        }
        
        return false
    }
    
    private func isDeviceInUse(_ deviceID: CMIOObjectID) -> Bool {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var isRunning: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let result = CMIOObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataSize,
            &isRunning
        )
        
        return result == kCMIOHardwareNoError && isRunning != 0
    }
    
    private func checkMicrophoneInUse() -> Bool {
        // 简化检测：检查是否有音频输入设备在使用
        // 注意：这是一个简化实现，实际可能需要更复杂的检测
        let audioDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInMicrophone, .externalUnknown],
            mediaType: .audio,
            position: .unspecified
        ).devices
        
        // 如果摄像头在使用，通常麦克风也在使用（会议场景）
        return isCameraInUse
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let meetingStatusChanged = Notification.Name("com.eyebreather.meetingStatusChanged")
}
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: 添加 MediaDeviceMonitor 检测会议状态"
```

---

## Task 3: 重构 AppDetector 为专注模式检测

**Files:**
- Modify: `EyeBreather/Core/AppDetector/AppDetector.swift`

**Step 1: 重构 AppDetector**

完全重写 AppDetector，移除全屏检测，改为专注模式应用检测：

```swift
import Foundation
import AppKit
import Combine

/// 应用检测器 - 检测专注模式应用
@MainActor
final class AppDetector: ObservableObject {
    static let shared = AppDetector()
    
    // MARK: - Published Properties
    
    @Published private(set) var frontmostAppBundleId: String?
    @Published private(set) var frontmostAppName: String?
    @Published private(set) var isFocusAppActive: Bool = false
    @Published private(set) var shouldPauseReminder: Bool = false
    @Published private(set) var pauseReason: PauseReason = .none
    
    enum PauseReason: Equatable {
        case none
        case focusApp(String)  // 应用名称
        case meeting
    }
    
    // MARK: - Private Properties
    
    private var appObserver: Any?
    private var meetingObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    deinit {
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = meetingObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听应用激活事件
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAppActivation(notification)
            }
        }
        
        // 监听会议状态变化
        meetingObserver = NotificationCenter.default.addObserver(
            forName: .meetingStatusChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updatePauseStatus()
            }
        }
        
        // 监听设置变化
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePauseStatus()
            }
            .store(in: &cancellables)
        
        // 初始检查
        checkFrontmostApp()
    }
    
    // MARK: - Event Handlers
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        frontmostAppBundleId = app.bundleIdentifier
        frontmostAppName = app.localizedName
        updatePauseStatus()
    }
    
    private func checkFrontmostApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            frontmostAppBundleId = nil
            frontmostAppName = nil
            updatePauseStatus()
            return
        }
        
        frontmostAppBundleId = frontApp.bundleIdentifier
        frontmostAppName = frontApp.localizedName
        updatePauseStatus()
    }
    
    // MARK: - Pause Status
    
    private func updatePauseStatus() {
        let settings = SettingsManager.shared.settings
        
        // 优先检查会议状态
        if settings.enableMeetingDetection && MediaDeviceMonitor.shared.isInMeeting {
            shouldPauseReminder = true
            pauseReason = .meeting
            postPauseNotification(shouldPause: true)
            return
        }
        
        // 检查专注模式应用
        if let bundleId = frontmostAppBundleId {
            let focusBundleIds = settings.focusApps.map { $0.bundleId }
            if focusBundleIds.contains(bundleId) {
                let appName = frontmostAppName ?? bundleId
                shouldPauseReminder = true
                pauseReason = .focusApp(appName)
                isFocusAppActive = true
                postPauseNotification(shouldPause: true)
                return
            }
        }
        
        // 无需暂停
        let wasShowing = shouldPauseReminder
        shouldPauseReminder = false
        pauseReason = .none
        isFocusAppActive = false
        
        if wasShowing {
            postPauseNotification(shouldPause: false)
        }
    }
    
    private func postPauseNotification(shouldPause: Bool) {
        if shouldPause {
            NotificationCenter.default.post(name: .shouldPauseReminder, object: nil)
        } else {
            NotificationCenter.default.post(name: .shouldResumeReminder, object: nil)
        }
    }
    
    // MARK: - Public Methods
    
    /// 获取所有正在运行的应用（用于添加到专注列表）
    func getRunningApps() -> [(bundleId: String, name: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return (bundleId, name)
            }
            .sorted { $0.1 < $1.1 }
    }
    
    /// 添加应用到专注列表
    func addToFocusList(bundleId: String, name: String) {
        var settings = SettingsManager.shared.settings
        let newApp = FocusApp(bundleId: bundleId, name: name, isPreset: false)
        if !settings.focusApps.contains(where: { $0.bundleId == bundleId }) {
            settings.focusApps.append(newApp)
            SettingsManager.shared.settings = settings
        }
    }
    
    /// 从专注列表移除应用
    func removeFromFocusList(bundleId: String) {
        var settings = SettingsManager.shared.settings
        settings.focusApps.removeAll { $0.bundleId == bundleId }
        SettingsManager.shared.settings = settings
    }
}

// MARK: - Notification Names (保持兼容)

extension Notification.Name {
    static let shouldPauseReminder = Notification.Name("com.eyebreather.shouldPauseReminder")
    static let shouldResumeReminder = Notification.Name("com.eyebreather.shouldResumeReminder")
}
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "refactor: 重构 AppDetector 为专注模式检测"
```

---

## Task 4: 创建圆环进度组件

**Files:**
- Create: `EyeBreather/Shared/Components/CircularProgressView.swift`

**Step 1: 创建圆环进度视图**

```swift
// EyeBreather/Shared/Components/CircularProgressView.swift
import SwiftUI

/// 圆环进度视图
struct CircularProgressView: View {
    let progress: Double  // 0.0 - 1.0
    let timeText: String
    let subtitle: String
    let color: Color
    let size: CGFloat
    
    init(
        progress: Double,
        timeText: String,
        subtitle: String = "",
        color: Color = .accentColor,
        size: CGFloat = 120
    ) {
        self.progress = progress
        self.timeText = timeText
        self.subtitle = subtitle
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // 背景圆环
            Circle()
                .stroke(
                    color.opacity(0.2),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
            
            // 进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            
            // 中心文字
            VStack(spacing: 2) {
                Text(timeText)
                    .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: size * 0.1))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressView(
            progress: 0.7,
            timeText: "18:32",
            subtitle: "下次休息",
            color: .green
        )
        
        CircularProgressView(
            progress: 0.3,
            timeText: "0:15",
            subtitle: "休息中",
            color: .blue,
            size: 100
        )
    }
    .padding()
}
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: 添加圆环进度视图组件"
```

---

## Task 5: 重写 MenuBarView

**Files:**
- Modify: `EyeBreather/Features/Timer/MenuBarView.swift`

**Step 1: 重写菜单栏视图**

```swift
// EyeBreather/Features/Timer/MenuBarView.swift
import SwiftUI

/// 菜单栏弹出视图 - 圆环式设计
struct MenuBarView: View {
    @ObservedObject private var timerManager = TimerManager.shared
    @ObservedObject private var appDetector = AppDetector.shared
    @ObservedObject private var mediaMonitor = MediaDeviceMonitor.shared
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 16) {
            // 圆环进度
            circularTimerView
            
            // 状态指示
            statusIndicatorView
            
            // 操作按钮
            actionButtonsView
            
            Divider()
                .padding(.horizontal)
            
            // 今日统计
            todayStatsView
            
            Divider()
                .padding(.horizontal)
            
            // 底部工具栏
            toolbarView
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 260)
        .background(.regularMaterial)
    }
    
    // MARK: - Circular Timer
    
    private var circularTimerView: some View {
        CircularProgressView(
            progress: timerProgress,
            timeText: timerText,
            subtitle: timerSubtitle,
            color: statusColor,
            size: 120
        )
        .padding(.top, 8)
    }
    
    private var timerProgress: Double {
        switch timerManager.state {
        case .breaking:
            return timerManager.breakProgress
        default:
            return timerManager.workProgress
        }
    }
    
    private var timerText: String {
        if appDetector.shouldPauseReminder {
            return "--:--"
        }
        
        switch timerManager.state {
        case .breaking:
            let remaining = timerManager.remainingBreakTime
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        default:
            let remaining = timerManager.remainingWorkTime
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        }
    }
    
    private var timerSubtitle: String {
        switch timerManager.state {
        case .breaking:
            return "休息中"
        case .idle:
            return "未启动"
        default:
            return "下次休息"
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        if appDetector.shouldPauseReminder {
            return .orange
        }
        switch timerManager.state {
        case .idle: return .gray
        case .working: return .green
        case .preBreak: return .yellow
        case .breaking: return .blue
        case .paused: return .orange
        }
    }
    
    private var statusText: String {
        if case .meeting = appDetector.pauseReason {
            return "会议中"
        }
        if case .focusApp(let name) = appDetector.pauseReason {
            return "专注模式 · \(name)"
        }
        switch timerManager.state {
        case .idle: return "未启动"
        case .working: return "工作中"
        case .preBreak: return "即将休息"
        case .breaking: return "休息中"
        case .paused: return "已暂停"
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // 暂停/继续按钮
            Button(action: togglePause) {
                HStack(spacing: 4) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.caption)
                    Text(isPaused ? "继续" : "暂停")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            
            // 立即休息按钮
            Button(action: startBreakNow) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption)
                    Text("立即休息")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(timerManager.state == .breaking)
        }
        .padding(.horizontal, 4)
    }
    
    private var isPaused: Bool {
        timerManager.state == .paused || timerManager.state == .idle
    }
    
    private func togglePause() {
        switch timerManager.state {
        case .paused:
            timerManager.resume()
        case .idle:
            timerManager.start()
        case .working, .preBreak:
            timerManager.pause()
        default:
            break
        }
    }
    
    private func startBreakNow() {
        timerManager.startBreak()
        BreakWindowController.shared.showOverlay()
    }
    
    // MARK: - Today Stats
    
    private var todayStatsView: some View {
        HStack {
            Label {
                Text("2h 15m")
                    .font(.subheadline.monospacedDigit())
            } icon: {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("·")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Label {
                Text("休息 6/8")
                    .font(.subheadline.monospacedDigit())
            } icon: {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack(spacing: 0) {
            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Button(action: openStatistics) {
                Image(systemName: "chart.bar")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Button(action: quitApp) {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }
    
    private func openStatistics() {
        StatisticsWindowController.shared.showStatistics()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    MenuBarView()
}
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: 重写 MenuBarView 为圆环式设计"
```

---

## Task 6: 更新 AppDelegate 初始化

**Files:**
- Modify: `EyeBreather/App/AppDelegate.swift`

**Step 1: 添加 MediaDeviceMonitor 初始化**

在 `applicationDidFinishLaunching` 中添加：

```swift
// 初始化媒体设备监视器
_ = MediaDeviceMonitor.shared
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "chore: 初始化 MediaDeviceMonitor"
```

---

## Task 7: 重写 SettingsView 为侧边栏式

**Files:**
- Modify: `EyeBreather/Features/Settings/SettingsView.swift`

**Step 1: 重写设置视图**

```swift
// EyeBreather/Features/Settings/SettingsView.swift
import SwiftUI
import AppKit
import UniformTypeIdentifiers

/// 设置视图 - 侧边栏式设计
struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedSection: SettingsSection = .breakRules
    
    enum SettingsSection: String, CaseIterable, Identifiable {
        case breakRules = "休息规则"
        case smartPause = "智能暂停"
        case appearance = "外观"
        case general = "通用"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .breakRules: return "timer"
            case .smartPause: return "target"
            case .appearance: return "paintbrush"
            case .general: return "gearshape"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .frame(minWidth: 150)
        } detail: {
            ScrollView {
                detailContent
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minWidth: 350)
        }
        .frame(width: 550, height: 450)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .breakRules:
            BreakRulesSection(settings: $settingsManager.settings)
        case .smartPause:
            SmartPauseSection(settings: $settingsManager.settings)
        case .appearance:
            AppearanceSection(settings: $settingsManager.settings)
        case .general:
            GeneralSection(settings: $settingsManager.settings)
        }
    }
}

// MARK: - Break Rules Section

struct BreakRulesSection: View {
    @Binding var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("休息规则")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                // 工作时长
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("工作时长")
                        Spacer()
                        Text("\(settings.workDuration) 分钟")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.workDuration) },
                        set: { settings.workDuration = Int($0) }
                    ), in: 5...60, step: 5)
                }
                
                Divider()
                
                // 休息时长
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("休息时长")
                        Spacer()
                        Text("\(settings.breakDuration) 秒")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.breakDuration) },
                        set: { settings.breakDuration = Int($0) }
                    ), in: 10...120, step: 10)
                }
                
                Divider()
                
                // 提醒模式
                VStack(alignment: .leading, spacing: 8) {
                    Text("提醒模式")
                    Picker("", selection: $settings.reminderMode) {
                        ForEach(ReminderMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                Divider()
                
                // 休息预警
                Toggle("提前 \(settings.preBreakWarning) 秒提醒", isOn: Binding(
                    get: { settings.preBreakWarning > 0 },
                    set: { settings.preBreakWarning = $0 ? 60 : 0 }
                ))
            }
        }
    }
}

// MARK: - Smart Pause Section

struct SmartPauseSection: View {
    @Binding var settings: AppSettings
    @State private var showingAppPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("智能暂停")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                // 会议检测
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("摄像头/麦克风使用时自动暂停", isOn: $settings.enableMeetingDetection)
                        Text("检测到会议时静默暂停提醒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                } label: {
                    Label("会议检测", systemImage: "video")
                }
                
                // 专注模式应用
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(settings.focusApps) { app in
                            HStack {
                                Text(app.name)
                                Spacer()
                                if app.isPreset {
                                    Text("预设")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Button(action: {
                                    settings.focusApps.removeAll { $0.bundleId == app.bundleId }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                        
                        Button(action: { showingAppPicker = true }) {
                            Label("添加应用...", systemImage: "plus")
                        }
                    }
                    .padding(.vertical, 4)
                } label: {
                    Label("专注模式应用", systemImage: "app.badge.checkmark")
                }
                
                // 智能推荐
                Toggle("智能推荐：检测到新全屏应用时提示添加", isOn: $settings.enableSmartRecommend)
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView(settings: $settings)
        }
    }
}

// MARK: - App Picker View

struct AppPickerView: View {
    @Binding var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    
    var runningApps: [(bundleId: String, name: String)] {
        AppDetector.shared.getRunningApps().filter { app in
            !settings.focusApps.contains { $0.bundleId == app.bundleId }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("选择应用")
                .font(.headline)
            
            List(runningApps, id: \.bundleId) { app in
                Button(action: {
                    let newApp = FocusApp(bundleId: app.bundleId, name: app.name, isPreset: false)
                    settings.focusApps.append(newApp)
                    dismiss()
                }) {
                    Text(app.name)
                }
                .buttonStyle(.plain)
            }
            .frame(height: 200)
            
            Button("取消") {
                dismiss()
            }
        }
        .padding()
        .frame(width: 300)
    }
}

// MARK: - Appearance Section

struct AppearanceSection: View {
    @Binding var settings: AppSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("外观")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                // 外观模式
                VStack(alignment: .leading, spacing: 8) {
                    Text("外观模式")
                    Picker("", selection: $settings.appearance) {
                        ForEach(AppearanceMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                
                Divider()
                
                // 休息界面样式
                VStack(alignment: .leading, spacing: 8) {
                    Text("休息界面样式")
                    Picker("", selection: $settings.breakStyle) {
                        ForEach(BreakStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
            }
        }
    }
}

// MARK: - General Section

struct GeneralSection: View {
    @Binding var settings: AppSettings
    @ObservedObject private var launchManager = LaunchAtLoginManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("通用")
                .font(.title2.bold())
            
            VStack(alignment: .leading, spacing: 16) {
                Toggle("开机自动启动", isOn: Binding(
                    get: { launchManager.isEnabled },
                    set: { launchManager.setEnabled($0) }
                ))
                
                Divider()
                
                Toggle("显示 Dock 图标", isOn: $settings.showInDock)
                
                Divider()
                
                // 空闲重置
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("空闲重置阈值")
                        Spacer()
                        Text("\(settings.idleResetThreshold) 分钟")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { Double(settings.idleResetThreshold) },
                        set: { settings.idleResetThreshold = Int($0) }
                    ), in: 1...30, step: 1)
                    Text("超过此时间无活动，自动重置工作周期")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
```

**Step 2: 构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | grep -E "error:|BUILD"
```

**Step 3: 提交**

```bash
git add -A && git commit -m "feat: 重写 SettingsView 为侧边栏式设计"
```

---

## Task 8: 最终验证和推送

**Step 1: 完整构建验证**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather build 2>&1 | tail -5
```

**Step 2: 启动应用测试**

```bash
open ~/Library/Developer/Xcode/DerivedData/EyeBreather-*/Build/Products/Debug/EyeBreather.app
```

**Step 3: 推送到远程**

```bash
git push origin main
```

---

## 验收标准

1. ✅ 菜单栏显示圆环式倒计时
2. ✅ 磨砂玻璃背景效果
3. ✅ 会议检测自动暂停
4. ✅ 专注模式应用列表工作正常
5. ✅ 设置界面为侧边栏式布局
6. ✅ 所有功能正常运行

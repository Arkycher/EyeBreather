# EyeBreather 实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 构建一款 macOS 原生护眼应用，实现定时休息提醒和屏幕时间统计功能

**Architecture:** 采用 Swift + SwiftUI 构建菜单栏应用，使用 SwiftData 持久化数据，通过 AppKit 实现全屏遮罩和系统事件监听

**Tech Stack:** Swift 5.9+, SwiftUI 5, SwiftData, AppKit, macOS 14.0+

---

## 阶段 1：项目初始化

### Task 1.1: 创建 Xcode 项目

**Step 1: 使用 Xcode 创建项目**

打开 Xcode，选择 File > New > Project：
- 模板：macOS > App
- Product Name: `EyeBreather`
- Team: 选择你的开发者账号（或 None）
- Organization Identifier: `com.yourname`
- Interface: SwiftUI
- Language: Swift
- Storage: None（我们手动配置 SwiftData）
- 取消勾选 Include Tests（我们手动添加）

保存到 `/Users/lamther/apps/github/EyeBreather/`

**Step 2: 验证项目结构**

确认生成了以下文件：
```
EyeBreather/
├── EyeBreather.xcodeproj
└── EyeBreather/
    ├── EyeBreatherApp.swift
    ├── ContentView.swift
    ├── Assets.xcassets/
    └── EyeBreather.entitlements
```

**Step 3: 配置项目设置**

在 Xcode 中：
1. 选择项目 > TARGETS > EyeBreather > General
2. 设置 Minimum Deployments: macOS 14.0
3. 选择 Signing & Capabilities，添加 App Sandbox

**Step 4: 添加测试目标**

1. File > New > Target
2. 选择 macOS > Unit Testing Bundle
3. Product Name: `EyeBreatherTests`
4. 确保 Target to be Tested 选择 `EyeBreather`

**Step 5: 初始提交**

```bash
cd /Users/lamther/apps/github/EyeBreather
git init
git add .
git commit -m "feat: 初始化 EyeBreather Xcode 项目"
```

---

### Task 1.2: 创建项目目录结构

**Files:**
- Create: `EyeBreather/App/`
- Create: `EyeBreather/Features/`
- Create: `EyeBreather/Core/`
- Create: `EyeBreather/Shared/`

**Step 1: 在 Xcode 中创建 Group 结构**

在 Xcode 项目导航器中，右键 EyeBreather 文件夹：

1. New Group: `App`
2. New Group: `Features`
   - 在 Features 下创建: `Timer`, `Statistics`, `Settings`, `Break`
3. New Group: `Core`
   - 在 Core 下创建: `ActivityMonitor`, `AppDetector`, `DataStore`
4. New Group: `Shared`
   - 在 Shared 下创建: `Models`, `Extensions`, `Utils`

**Step 2: 移动现有文件**

- 将 `EyeBreatherApp.swift` 移动到 `App/` 组
- 将 `ContentView.swift` 移动到 `Features/` 组（临时）

**Step 3: 提交**

```bash
git add .
git commit -m "chore: 创建项目目录结构"
```

---

## 阶段 2：数据模型层

### Task 2.1: 定义枚举类型

**Files:**
- Create: `EyeBreather/Shared/Models/Enums.swift`
- Test: `EyeBreatherTests/Models/EnumsTests.swift`

**Step 1: 编写枚举定义**

创建 `EyeBreather/Shared/Models/Enums.swift`:

```swift
import Foundation

/// 提醒模式
enum ReminderMode: String, Codable, CaseIterable {
    case forced = "forced"           // 强制模式
    case gentle = "gentle"           // 温和模式
    case progressive = "progressive" // 渐进模式
    
    var displayName: String {
        switch self {
        case .forced: return "强制模式"
        case .gentle: return "温和模式"
        case .progressive: return "渐进模式"
        }
    }
    
    var description: String {
        switch self {
        case .forced: return "休息时全屏遮罩，必须完成"
        case .gentle: return "弹出通知提醒，可选择跳过"
        case .progressive: return "多次跳过后自动变为强制模式"
        }
    }
}

/// 休息界面样式
enum BreakStyle: String, Codable, CaseIterable {
    case dark = "dark"           // 纯黑
    case tips = "tips"           // 护眼提示
    case animation = "animation" // 动画引导
    case scenery = "scenery"     // 自然风景
    case custom = "custom"       // 自定义背景
    
    var displayName: String {
        switch self {
        case .dark: return "深色遮罩"
        case .tips: return "护眼提示"
        case .animation: return "动画引导"
        case .scenery: return "自然风景"
        case .custom: return "自定义背景"
        }
    }
}

/// 外观模式
enum AppearanceMode: String, Codable, CaseIterable {
    case system = "system" // 跟随系统
    case light = "light"   // 浅色
    case dark = "dark"     // 深色
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

/// 计时器状态
enum TimerState: String, Codable {
    case idle = "idle"         // 空闲（未开始）
    case working = "working"   // 工作中
    case preBreak = "preBreak" // 休息预警
    case breaking = "breaking" // 休息中
    case paused = "paused"     // 已暂停
}
```

**Step 2: 编写测试**

创建 `EyeBreatherTests/Models/EnumsTests.swift`:

```swift
import XCTest
@testable import EyeBreather

final class EnumsTests: XCTestCase {
    
    // MARK: - ReminderMode Tests
    
    func testReminderModeDisplayNames() {
        XCTAssertEqual(ReminderMode.forced.displayName, "强制模式")
        XCTAssertEqual(ReminderMode.gentle.displayName, "温和模式")
        XCTAssertEqual(ReminderMode.progressive.displayName, "渐进模式")
    }
    
    func testReminderModeCodable() throws {
        let mode = ReminderMode.forced
        let encoded = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(ReminderMode.self, from: encoded)
        XCTAssertEqual(mode, decoded)
    }
    
    // MARK: - BreakStyle Tests
    
    func testBreakStyleCaseIterable() {
        XCTAssertEqual(BreakStyle.allCases.count, 5)
    }
    
    // MARK: - TimerState Tests
    
    func testTimerStateRawValues() {
        XCTAssertEqual(TimerState.idle.rawValue, "idle")
        XCTAssertEqual(TimerState.working.rawValue, "working")
        XCTAssertEqual(TimerState.breaking.rawValue, "breaking")
    }
}
```

**Step 3: 运行测试验证**

在 Xcode 中：Product > Test (⌘U)

预期：所有测试通过

**Step 4: 提交**

```bash
git add .
git commit -m "feat: 添加枚举类型定义（ReminderMode, BreakStyle, AppearanceMode, TimerState）"
```

---

### Task 2.2: 定义 AppSettings 模型

**Files:**
- Create: `EyeBreather/Shared/Models/AppSettings.swift`
- Test: `EyeBreatherTests/Models/AppSettingsTests.swift`

**Step 1: 编写 AppSettings**

创建 `EyeBreather/Shared/Models/AppSettings.swift`:

```swift
import Foundation

/// 应用设置
struct AppSettings: Codable, Equatable {
    // MARK: - 休息规则
    
    /// 工作时长（分钟），默认 20
    var workDuration: Int = 20
    
    /// 休息时长（秒），默认 20
    var breakDuration: Int = 20
    
    /// 提醒模式
    var reminderMode: ReminderMode = .gentle
    
    /// 休息预警时间（秒），默认 60
    var preBreakWarning: Int = 60
    
    /// 延迟选项（分钟）
    var delayOptions: [Int] = [5, 15, 30]
    
    // MARK: - 智能检测
    
    /// 启用活动检测
    var enableActivityDetection: Bool = true
    
    /// 空闲重置阈值（分钟），默认 5
    var idleResetThreshold: Int = 5
    
    /// 全屏应用时暂停
    var enableFullscreenPause: Bool = true
    
    /// 白名单应用 Bundle ID
    var whitelistApps: [String] = []
    
    // MARK: - 休息界面
    
    /// 休息界面样式
    var breakStyle: BreakStyle = .dark
    
    /// 自定义背景图片路径
    var customBackgroundPath: String? = nil
    
    // MARK: - 通用
    
    /// 开机自启
    var launchAtLogin: Bool = false
    
    /// 显示 Dock 图标
    var showInDock: Bool = false
    
    /// 外观模式
    var appearance: AppearanceMode = .system
    
    // MARK: - 默认值
    
    static let `default` = AppSettings()
}

// MARK: - UserDefaults 存储

extension AppSettings {
    private static let storageKey = "com.eyebreather.settings"
    
    /// 从 UserDefaults 加载设置
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    /// 保存到 UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
```

**Step 2: 编写测试**

创建 `EyeBreatherTests/Models/AppSettingsTests.swift`:

```swift
import XCTest
@testable import EyeBreather

final class AppSettingsTests: XCTestCase {
    
    override func tearDown() {
        // 清理测试数据
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.settings")
        super.tearDown()
    }
    
    func testDefaultValues() {
        let settings = AppSettings.default
        
        XCTAssertEqual(settings.workDuration, 20)
        XCTAssertEqual(settings.breakDuration, 20)
        XCTAssertEqual(settings.reminderMode, .gentle)
        XCTAssertEqual(settings.preBreakWarning, 60)
        XCTAssertEqual(settings.delayOptions, [5, 15, 30])
        XCTAssertTrue(settings.enableActivityDetection)
        XCTAssertEqual(settings.idleResetThreshold, 5)
        XCTAssertTrue(settings.enableFullscreenPause)
        XCTAssertTrue(settings.whitelistApps.isEmpty)
        XCTAssertEqual(settings.breakStyle, .dark)
        XCTAssertNil(settings.customBackgroundPath)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.showInDock)
        XCTAssertEqual(settings.appearance, .system)
    }
    
    func testSaveAndLoad() {
        var settings = AppSettings()
        settings.workDuration = 25
        settings.reminderMode = .forced
        settings.breakStyle = .scenery
        
        settings.save()
        
        let loaded = AppSettings.load()
        XCTAssertEqual(loaded.workDuration, 25)
        XCTAssertEqual(loaded.reminderMode, .forced)
        XCTAssertEqual(loaded.breakStyle, .scenery)
    }
    
    func testLoadReturnsDefaultWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.settings")
        
        let loaded = AppSettings.load()
        XCTAssertEqual(loaded, AppSettings.default)
    }
    
    func testCodable() throws {
        var settings = AppSettings()
        settings.whitelistApps = ["com.apple.Safari", "us.zoom.xos"]
        
        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        
        XCTAssertEqual(settings, decoded)
    }
}
```

**Step 3: 运行测试**

在 Xcode 中：Product > Test (⌘U)

预期：所有测试通过

**Step 4: 提交**

```bash
git add .
git commit -m "feat: 添加 AppSettings 模型及 UserDefaults 持久化"
```

---

### Task 2.3: 定义 SwiftData 模型

**Files:**
- Create: `EyeBreather/Shared/Models/BreakRecord.swift`
- Create: `EyeBreather/Shared/Models/DailyStatistics.swift`
- Test: `EyeBreatherTests/Models/SwiftDataModelsTests.swift`

**Step 1: 创建 BreakRecord 模型**

创建 `EyeBreather/Shared/Models/BreakRecord.swift`:

```swift
import Foundation
import SwiftData

/// 休息记录
@Model
final class BreakRecord {
    /// 唯一标识
    var id: UUID
    
    /// 开始时间
    var startTime: Date
    
    /// 实际休息时长（秒）
    var duration: Int
    
    /// 预期休息时长（秒）
    var expectedDuration: Int
    
    /// 是否完成
    var completed: Bool
    
    /// 是否跳过
    var skipped: Bool
    
    /// 所属日期（用于关联 DailyStatistics）
    var dateKey: String
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        duration: Int = 0,
        expectedDuration: Int = 20,
        completed: Bool = false,
        skipped: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.expectedDuration = expectedDuration
        self.completed = completed
        self.skipped = skipped
        self.dateKey = Self.dateKeyFormatter.string(from: startTime)
    }
    
    /// 日期格式化器
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
```

**Step 2: 创建 DailyStatistics 模型**

创建 `EyeBreather/Shared/Models/DailyStatistics.swift`:

```swift
import Foundation
import SwiftData

/// 每日统计
@Model
final class DailyStatistics {
    /// 日期键（格式：yyyy-MM-dd）
    @Attribute(.unique) var dateKey: String
    
    /// 该日期
    var date: Date
    
    /// 总活跃时长（秒）
    var totalActiveTime: Int
    
    /// 完成的休息次数
    var completedBreaks: Int
    
    /// 跳过的休息次数
    var skippedBreaks: Int
    
    init(
        date: Date = Date(),
        totalActiveTime: Int = 0,
        completedBreaks: Int = 0,
        skippedBreaks: Int = 0
    ) {
        self.date = date
        self.totalActiveTime = totalActiveTime
        self.completedBreaks = completedBreaks
        self.skippedBreaks = skippedBreaks
        self.dateKey = Self.dateKeyFormatter.string(from: date)
    }
    
    /// 日期格式化器
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 总休息次数
    var totalBreaks: Int {
        completedBreaks + skippedBreaks
    }
    
    /// 完成率（0-1）
    var completionRate: Double {
        guard totalBreaks > 0 else { return 0 }
        return Double(completedBreaks) / Double(totalBreaks)
    }
    
    /// 格式化的活跃时长
    var formattedActiveTime: String {
        let hours = totalActiveTime / 3600
        let minutes = (totalActiveTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
```

**Step 3: 编写测试**

创建 `EyeBreatherTests/Models/SwiftDataModelsTests.swift`:

```swift
import XCTest
import SwiftData
@testable import EyeBreather

final class SwiftDataModelsTests: XCTestCase {
    
    // MARK: - BreakRecord Tests
    
    func testBreakRecordInit() {
        let record = BreakRecord(
            expectedDuration: 20,
            completed: true
        )
        
        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.expectedDuration, 20)
        XCTAssertTrue(record.completed)
        XCTAssertFalse(record.skipped)
        XCTAssertFalse(record.dateKey.isEmpty)
    }
    
    func testBreakRecordDateKey() {
        let date = Date()
        let record = BreakRecord(startTime: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expectedKey = formatter.string(from: date)
        
        XCTAssertEqual(record.dateKey, expectedKey)
    }
    
    // MARK: - DailyStatistics Tests
    
    func testDailyStatisticsInit() {
        let stats = DailyStatistics()
        
        XCTAssertEqual(stats.totalActiveTime, 0)
        XCTAssertEqual(stats.completedBreaks, 0)
        XCTAssertEqual(stats.skippedBreaks, 0)
        XCTAssertFalse(stats.dateKey.isEmpty)
    }
    
    func testCompletionRate() {
        let stats = DailyStatistics(
            completedBreaks: 8,
            skippedBreaks: 2
        )
        
        XCTAssertEqual(stats.totalBreaks, 10)
        XCTAssertEqual(stats.completionRate, 0.8, accuracy: 0.001)
    }
    
    func testCompletionRateWhenNoBreaks() {
        let stats = DailyStatistics()
        
        XCTAssertEqual(stats.completionRate, 0)
    }
    
    func testFormattedActiveTime() {
        let statsMinutes = DailyStatistics(totalActiveTime: 45 * 60) // 45 分钟
        XCTAssertEqual(statsMinutes.formattedActiveTime, "45m")
        
        let statsHours = DailyStatistics(totalActiveTime: 3 * 3600 + 24 * 60) // 3h 24m
        XCTAssertEqual(statsHours.formattedActiveTime, "3h 24m")
    }
}
```

**Step 4: 运行测试**

在 Xcode 中：Product > Test (⌘U)

预期：所有测试通过

**Step 5: 提交**

```bash
git add .
git commit -m "feat: 添加 SwiftData 模型（BreakRecord, DailyStatistics）"
```

---

### Task 2.4: 配置 SwiftData 容器

**Files:**
- Create: `EyeBreather/Core/DataStore/DataStoreManager.swift`
- Modify: `EyeBreather/App/EyeBreatherApp.swift`

**Step 1: 创建 DataStoreManager**

创建 `EyeBreather/Core/DataStore/DataStoreManager.swift`:

```swift
import Foundation
import SwiftData

/// 数据存储管理器
@MainActor
final class DataStoreManager {
    /// 共享实例
    static let shared = DataStoreManager()
    
    /// SwiftData 容器
    let container: ModelContainer
    
    /// 主上下文
    var mainContext: ModelContext {
        container.mainContext
    }
    
    private init() {
        let schema = Schema([
            BreakRecord.self,
            DailyStatistics.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化 SwiftData 容器: \(error)")
        }
    }
    
    /// 创建用于测试的内存容器
    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            BreakRecord.self,
            DailyStatistics.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}
```

**Step 2: 更新 App 入口**

修改 `EyeBreather/App/EyeBreatherApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct EyeBreatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStoreManager.shared.container)
    }
}
```

**Step 3: 运行应用验证**

在 Xcode 中：Product > Run (⌘R)

预期：应用正常启动，无崩溃

**Step 4: 提交**

```bash
git add .
git commit -m "feat: 配置 SwiftData 容器和 DataStoreManager"
```

---

## 阶段 3：菜单栏应用基础

### Task 3.1: 创建 AppDelegate 配置菜单栏

**Files:**
- Create: `EyeBreather/App/AppDelegate.swift`
- Modify: `EyeBreather/App/EyeBreatherApp.swift`

**Step 1: 创建 AppDelegate**

创建 `EyeBreather/App/AppDelegate.swift`:

```swift
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// 菜单栏状态项
    private var statusItem: NSStatusItem?
    
    /// 弹出窗口
    private var popover: NSPopover?
    
    /// 事件监听器（点击其他区域关闭 popover）
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupEventMonitor()
        
        // 隐藏 Dock 图标（根据设置）
        let settings = AppSettings.load()
        updateDockIconVisibility(show: settings.showInDock)
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreather")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .modelContainer(DataStoreManager.shared.container)
        )
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    // MARK: - Event Monitor
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.popover?.performClose(nil)
            }
        }
    }
    
    // MARK: - Dock Icon
    
    func updateDockIconVisibility(show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // MARK: - Cleanup
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}
```

**Step 2: 创建菜单栏视图占位**

创建 `EyeBreather/Features/Timer/MenuBarView.swift`:

```swift
import SwiftUI

/// 菜单栏弹出视图
struct MenuBarView: View {
    var body: some View {
        VStack(spacing: 16) {
            // 标题
            HStack {
                Image(systemName: "eye")
                    .font(.title2)
                Text("EyeBreather")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            Divider()
            
            // 占位内容
            Text("菜单栏视图开发中...")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("设置...") {
                    // TODO: 打开设置窗口
                }
                Spacer()
                Button("退出") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .frame(width: 280, height: 350)
    }
}

#Preview {
    MenuBarView()
}
```

**Step 3: 更新 App 入口使用 AppDelegate**

修改 `EyeBreather/App/EyeBreatherApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct EyeBreatherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings 场景作为主窗口（可选显示）
        Settings {
            ContentView()
                .modelContainer(DataStoreManager.shared.container)
        }
    }
}
```

**Step 4: 运行验证**

在 Xcode 中：Product > Run (⌘R)

预期：
- 应用启动后在菜单栏显示眼睛图标
- Dock 中不显示图标
- 点击菜单栏图标弹出 Popover
- 点击其他区域关闭 Popover

**Step 5: 提交**

```bash
git add .
git commit -m "feat: 实现菜单栏应用基础（StatusItem + Popover）"
```

---

### Task 3.2: 实现设置管理 ObservableObject

**Files:**
- Create: `EyeBreather/Core/DataStore/SettingsManager.swift`
- Test: `EyeBreatherTests/Core/SettingsManagerTests.swift`

**Step 1: 创建 SettingsManager**

创建 `EyeBreather/Core/DataStore/SettingsManager.swift`:

```swift
import Foundation
import Combine

/// 设置管理器（全局单例）
@MainActor
final class SettingsManager: ObservableObject {
    /// 共享实例
    static let shared = SettingsManager()
    
    /// 当前设置
    @Published var settings: AppSettings {
        didSet {
            settings.save()
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }
    
    private init() {
        self.settings = AppSettings.load()
    }
    
    /// 重置为默认设置
    func resetToDefaults() {
        settings = .default
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsDidChange = Notification.Name("com.eyebreather.settingsDidChange")
}
```

**Step 2: 编写测试**

创建 `EyeBreatherTests/Core/SettingsManagerTests.swift`:

```swift
import XCTest
@testable import EyeBreather

@MainActor
final class SettingsManagerTests: XCTestCase {
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.settings")
        super.tearDown()
    }
    
    func testSharedInstance() {
        let manager1 = SettingsManager.shared
        let manager2 = SettingsManager.shared
        
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testSettingsAutoSave() {
        let manager = SettingsManager.shared
        manager.settings.workDuration = 30
        
        // 重新加载验证
        let loaded = AppSettings.load()
        XCTAssertEqual(loaded.workDuration, 30)
    }
    
    func testResetToDefaults() {
        let manager = SettingsManager.shared
        manager.settings.workDuration = 99
        manager.settings.reminderMode = .forced
        
        manager.resetToDefaults()
        
        XCTAssertEqual(manager.settings.workDuration, 20)
        XCTAssertEqual(manager.settings.reminderMode, .gentle)
    }
    
    func testSettingsChangeNotification() {
        let manager = SettingsManager.shared
        let expectation = XCTestExpectation(description: "Settings change notification")
        
        let observer = NotificationCenter.default.addObserver(
            forName: .settingsDidChange,
            object: nil,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        manager.settings.workDuration = 25
        
        wait(for: [expectation], timeout: 1.0)
        NotificationCenter.default.removeObserver(observer)
    }
}
```

**Step 3: 运行测试**

在 Xcode 中：Product > Test (⌘U)

预期：所有测试通过

**Step 4: 提交**

```bash
git add .
git commit -m "feat: 添加 SettingsManager 单例和设置变更通知"
```

---

## 阶段 4：计时器核心

### Task 4.1: 实现 TimerManager

**Files:**
- Create: `EyeBreather/Core/Timer/TimerManager.swift`
- Test: `EyeBreatherTests/Core/TimerManagerTests.swift`

**Step 1: 创建 TimerManager**

创建 `EyeBreather/Core/Timer/TimerManager.swift`:

```swift
import Foundation
import Combine

/// 计时器管理器
@MainActor
final class TimerManager: ObservableObject {
    /// 共享实例
    static let shared = TimerManager()
    
    // MARK: - Published Properties
    
    /// 当前状态
    @Published private(set) var state: TimerState = .idle
    
    /// 当前周期已工作时间（秒）
    @Published private(set) var elapsedWorkTime: Int = 0
    
    /// 当前休息已用时间（秒）
    @Published private(set) var elapsedBreakTime: Int = 0
    
    /// 上次活动时间
    @Published private(set) var lastActivityTime: Date = Date()
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 工作时长设置（秒）
    var workDurationSeconds: Int {
        SettingsManager.shared.settings.workDuration * 60
    }
    
    /// 休息时长设置（秒）
    var breakDurationSeconds: Int {
        SettingsManager.shared.settings.breakDuration
    }
    
    /// 预警时间设置（秒）
    var preBreakWarningSeconds: Int {
        SettingsManager.shared.settings.preBreakWarning
    }
    
    /// 工作进度（0-1）
    var workProgress: Double {
        guard workDurationSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedWorkTime) / Double(workDurationSeconds))
    }
    
    /// 休息进度（0-1）
    var breakProgress: Double {
        guard breakDurationSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedBreakTime) / Double(breakDurationSeconds))
    }
    
    /// 距离下次休息的剩余时间（秒）
    var remainingWorkTime: Int {
        max(0, workDurationSeconds - elapsedWorkTime)
    }
    
    /// 剩余休息时间（秒）
    var remainingBreakTime: Int {
        max(0, breakDurationSeconds - elapsedBreakTime)
    }
    
    /// 是否处于预警阶段
    var isInPreBreakWarning: Bool {
        remainingWorkTime <= preBreakWarningSeconds && remainingWorkTime > 0
    }
    
    // MARK: - Initialization
    
    private init() {
        observeSettingsChanges()
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // 设置变更时可能需要重新计算
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 开始工作计时
    func start() {
        guard state == .idle || state == .paused else { return }
        
        state = .working
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 暂停计时
    func pause() {
        guard state == .working || state == .preBreak else { return }
        
        state = .paused
        stopTimer()
    }
    
    /// 继续计时
    func resume() {
        guard state == .paused else { return }
        
        state = .working
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 开始休息
    func startBreak() {
        state = .breaking
        elapsedBreakTime = 0
        stopTimer()
        startTimer()
    }
    
    /// 跳过休息
    func skipBreak() {
        resetWorkCycle()
    }
    
    /// 延迟休息
    func delayBreak(minutes: Int) {
        // 减少已工作时间，相当于延迟
        elapsedWorkTime = max(0, workDurationSeconds - minutes * 60)
        state = .working
    }
    
    /// 完成休息
    func completeBreak() {
        resetWorkCycle()
    }
    
    /// 重置工作周期
    func resetWorkCycle() {
        stopTimer()
        state = .working
        elapsedWorkTime = 0
        elapsedBreakTime = 0
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 记录用户活动
    func recordActivity() {
        lastActivityTime = Date()
    }
    
    /// 检查空闲重置
    func checkIdleReset() {
        let idleThreshold = SettingsManager.shared.settings.idleResetThreshold * 60
        let idleTime = Int(Date().timeIntervalSince(lastActivityTime))
        
        if idleTime >= idleThreshold {
            resetWorkCycle()
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        switch state {
        case .working, .preBreak:
            elapsedWorkTime += 1
            
            // 检查是否进入预警
            if isInPreBreakWarning && state == .working {
                state = .preBreak
                NotificationCenter.default.post(name: .preBreakWarning, object: nil)
            }
            
            // 检查是否需要休息
            if elapsedWorkTime >= workDurationSeconds {
                NotificationCenter.default.post(name: .breakTimeReached, object: nil)
            }
            
        case .breaking:
            elapsedBreakTime += 1
            
            // 检查休息是否完成
            if elapsedBreakTime >= breakDurationSeconds {
                NotificationCenter.default.post(name: .breakCompleted, object: nil)
            }
            
        case .idle, .paused:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let preBreakWarning = Notification.Name("com.eyebreather.preBreakWarning")
    static let breakTimeReached = Notification.Name("com.eyebreather.breakTimeReached")
    static let breakCompleted = Notification.Name("com.eyebreather.breakCompleted")
}
```

**Step 2: 编写测试**

创建 `EyeBreatherTests/Core/TimerManagerTests.swift`:

```swift
import XCTest
@testable import EyeBreather

@MainActor
final class TimerManagerTests: XCTestCase {
    
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager.shared
        // 重置状态
        timerManager.resetWorkCycle()
        timerManager.pause()
    }
    
    func testInitialState() {
        XCTAssertEqual(timerManager.elapsedWorkTime, 0)
        XCTAssertEqual(timerManager.elapsedBreakTime, 0)
    }
    
    func testStart() {
        timerManager.start()
        XCTAssertEqual(timerManager.state, .working)
    }
    
    func testPause() {
        timerManager.start()
        timerManager.pause()
        XCTAssertEqual(timerManager.state, .paused)
    }
    
    func testResume() {
        timerManager.start()
        timerManager.pause()
        timerManager.resume()
        XCTAssertEqual(timerManager.state, .working)
    }
    
    func testWorkProgress() {
        // 假设工作时长 20 分钟 = 1200 秒
        // 如果已工作 600 秒，进度应该是 0.5
        // 注意：这里需要直接设置 elapsedWorkTime，但它是 private(set)
        // 所以我们测试计算逻辑
        XCTAssertEqual(timerManager.workProgress, 0)
    }
    
    func testRemainingWorkTime() {
        // 初始状态，剩余时间应该等于工作时长
        XCTAssertEqual(timerManager.remainingWorkTime, timerManager.workDurationSeconds)
    }
    
    func testStartBreak() {
        timerManager.startBreak()
        XCTAssertEqual(timerManager.state, .breaking)
        XCTAssertEqual(timerManager.elapsedBreakTime, 0)
    }
    
    func testResetWorkCycle() {
        timerManager.start()
        timerManager.resetWorkCycle()
        XCTAssertEqual(timerManager.elapsedWorkTime, 0)
        XCTAssertEqual(timerManager.state, .working)
    }
}
```

**Step 3: 运行测试**

在 Xcode 中：Product > Test (⌘U)

预期：所有测试通过

**Step 4: 提交**

```bash
git add .
git commit -m "feat: 实现 TimerManager 核心计时逻辑"
```

---

## 后续阶段概览

由于完整实施计划较长，以下是后续阶段的概览：

### 阶段 5：休息界面
- Task 5.1: 创建休息遮罩窗口控制器
- Task 5.2: 实现多显示器遮罩
- Task 5.3: 实现不同休息样式视图

### 阶段 6：活动检测
- Task 6.1: 实现 ActivityMonitor
- Task 6.2: 实现空闲检测和自动重置
- Task 6.3: 处理系统睡眠/唤醒

### 阶段 7：全屏应用检测
- Task 7.1: 实现 AppDetector
- Task 7.2: 实现应用白名单管理界面

### 阶段 8：菜单栏视图完善
- Task 8.1: 实现完整的 MenuBarView
- Task 8.2: 实现状态图标更新

### 阶段 9：设置界面
- Task 9.1: 创建设置窗口
- Task 9.2: 实现各设置分类视图

### 阶段 10：统计界面
- Task 10.1: 创建统计窗口
- Task 10.2: 实现数据可视化
- Task 10.3: 实现数据导出

### 阶段 11：系统集成
- Task 11.1: 实现开机自启
- Task 11.2: 实现系统通知
- Task 11.3: 实现外观跟随系统

### 阶段 12：收尾
- Task 12.1: 添加应用图标
- Task 12.2: 完善错误处理
- Task 12.3: 性能优化和测试

---

## 执行检查点

每完成一个 Task 后：
1. 运行所有测试确保通过
2. 运行应用手动验证功能
3. 提交代码

每完成一个阶段后：
1. 回顾该阶段实现
2. 更新设计文档（如有变更）
3. 创建阶段性 tag

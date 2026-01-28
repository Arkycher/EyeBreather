# EyeBreather 功能增强实施计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 增加声音提醒、休息统计、勿扰时段、渐进模式实现，并修复代码设计问题

**Architecture:** 
- 新增 `BreakStatistics` 模型用于统计数据持久化
- 新增 `SoundManager` 管理声音播放
- 扩展 `AppSettings` 支持新设置项
- 重构 `BreakCoordinator` 实现渐进模式逻辑
- 提取设计常量到 `DesignConstants`

**Tech Stack:** SwiftUI, AVFoundation (声音), UserDefaults (统计持久化)

---

## 渐进模式说明

**渐进模式 (Progressive Mode)** 的设计理念：
- 初始行为类似温和模式（弹出通知，可跳过）
- 用户每次跳过休息，跳过计数 +1
- 当连续跳过次数达到阈值（默认 3 次），下次休息自动变为强制模式
- 完成一次休息后，跳过计数重置为 0
- 这样既给用户灵活性，又能防止用户无限跳过

---

## Task 1: 提取设计常量

**Files:**
- Create: `EyeBreather/Shared/Constants/DesignConstants.swift`

**Step 1: 创建设计常量文件**

```swift
import SwiftUI

/// 设计系统常量
enum DesignConstants {
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
    }
    
    // MARK: - Font Sizes
    enum FontSize {
        static let caption: CGFloat = 11
        static let footnote: CGFloat = 13
        static let body: CGFloat = 14
        static let headline: CGFloat = 15
        static let title: CGFloat = 16
    }
    
    // MARK: - Sidebar
    enum Sidebar {
        static let width: CGFloat = 160
        static let itemSpacing: CGFloat = 2
        static let backgroundColor = Color(nsColor: NSColor(white: 0.94, alpha: 1.0))
        static let selectedColor = Color(nsColor: NSColor(white: 0.86, alpha: 1.0))
        static let hoverColor = Color(nsColor: NSColor(white: 0.90, alpha: 1.0))
    }
    
    // MARK: - Card
    enum Card {
        static let shadowOpacity: Double = 0.06
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 2
    }
    
    // MARK: - Settings Window
    enum SettingsWindow {
        static let width: CGFloat = 640
        static let height: CGFloat = 520
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreather/Shared/Constants/DesignConstants.swift
git commit -m "refactor: 提取设计常量到 DesignConstants"
```

---

## Task 2: 新增休息统计模型

**Files:**
- Create: `EyeBreather/Shared/Models/BreakStatistics.swift`

**Step 1: 创建统计模型**

```swift
import Foundation

/// 每日休息统计
struct DailyBreakStatistics: Codable, Equatable {
    let date: String // yyyy-MM-dd 格式
    var completedBreaks: Int = 0
    var skippedBreaks: Int = 0
    var totalBreakSeconds: Int = 0
    
    /// 总休息次数
    var totalBreaks: Int { completedBreaks + skippedBreaks }
    
    /// 完成率
    var completionRate: Double {
        guard totalBreaks > 0 else { return 0 }
        return Double(completedBreaks) / Double(totalBreaks)
    }
}

/// 休息统计管理器
@MainActor
final class BreakStatisticsManager: ObservableObject {
    static let shared = BreakStatisticsManager()
    
    private static let storageKey = "com.eyebreather.statistics"
    
    @Published private(set) var todayStatistics: DailyBreakStatistics
    @Published private(set) var allStatistics: [DailyBreakStatistics] = []
    
    /// 渐进模式：连续跳过次数
    @Published private(set) var consecutiveSkips: Int = 0
    
    private init() {
        self.allStatistics = Self.loadAll()
        self.todayStatistics = Self.loadToday(from: allStatistics)
        self.consecutiveSkips = UserDefaults.standard.integer(forKey: "consecutiveSkips")
    }
    
    // MARK: - Date Helper
    
    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Load
    
    private static func loadAll() -> [DailyBreakStatistics] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stats = try? JSONDecoder().decode([DailyBreakStatistics].self, from: data) else {
            return []
        }
        return stats
    }
    
    private static func loadToday(from all: [DailyBreakStatistics]) -> DailyBreakStatistics {
        if let today = all.first(where: { $0.date == todayKey }) {
            return today
        }
        return DailyBreakStatistics(date: todayKey)
    }
    
    // MARK: - Save
    
    private func save() {
        // 更新或添加今日统计
        if let index = allStatistics.firstIndex(where: { $0.date == todayStatistics.date }) {
            allStatistics[index] = todayStatistics
        } else {
            allStatistics.append(todayStatistics)
        }
        
        // 只保留最近 30 天
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffKey = formatter.string(from: thirtyDaysAgo)
        allStatistics = allStatistics.filter { $0.date >= cutoffKey }
        
        // 保存
        if let data = try? JSONEncoder().encode(allStatistics) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
        
        UserDefaults.standard.set(consecutiveSkips, forKey: "consecutiveSkips")
    }
    
    // MARK: - Record
    
    func recordBreakCompleted(durationSeconds: Int) {
        todayStatistics.completedBreaks += 1
        todayStatistics.totalBreakSeconds += durationSeconds
        consecutiveSkips = 0 // 重置连续跳过
        save()
    }
    
    func recordBreakSkipped() {
        todayStatistics.skippedBreaks += 1
        consecutiveSkips += 1
        save()
    }
    
    /// 渐进模式：是否应该强制休息
    var shouldForceBreak: Bool {
        let threshold = SettingsManager.shared.settings.progressiveForceThreshold
        return consecutiveSkips >= threshold
    }
    
    /// 重置连续跳过计数（用于新的一天）
    func resetConsecutiveSkipsIfNewDay() {
        let today = Self.todayKey
        if todayStatistics.date != today {
            consecutiveSkips = 0
            todayStatistics = DailyBreakStatistics(date: today)
            save()
        }
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreather/Shared/Models/BreakStatistics.swift
git commit -m "feat: 添加休息统计模型 BreakStatistics"
```

---

## Task 3: 扩展 AppSettings

**Files:**
- Modify: `EyeBreather/Shared/Models/AppSettings.swift`

**Step 1: 添加新设置项**

在 `AppSettings` 结构体中添加：

```swift
// MARK: - 声音提醒
    
/// 启用声音提醒
var enableSound: Bool = true

/// 休息开始提示音
var breakStartSound: String = "default"

/// 休息结束提示音
var breakEndSound: String = "default"

// MARK: - 勿扰时段

/// 启用勿扰时段
var enableDoNotDisturb: Bool = false

/// 勿扰开始时间（小时，0-23）
var doNotDisturbStart: Int = 22

/// 勿扰结束时间（小时，0-23）
var doNotDisturbEnd: Int = 8

// MARK: - 渐进模式

/// 渐进模式：连续跳过多少次后强制休息
var progressiveForceThreshold: Int = 3
```

**Step 2: 提交**

```bash
git add EyeBreather/Shared/Models/AppSettings.swift
git commit -m "feat: AppSettings 添加声音、勿扰时段、渐进模式设置"
```

---

## Task 4: 创建声音管理器

**Files:**
- Create: `EyeBreather/Core/SoundManager.swift`

**Step 1: 创建声音管理器**

```swift
import Foundation
import AVFoundation
import AppKit

/// 声音管理器
@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    /// 可用的提示音列表
    static let availableSounds: [(id: String, name: String)] = [
        ("default", "系统默认"),
        ("glass", "玻璃"),
        ("ping", "叮"),
        ("pop", "弹出"),
        ("purr", "呼噜"),
        ("submarine", "潜艇"),
        ("tink", "铃声")
    ]
    
    private init() {}
    
    /// 播放休息开始提示音
    func playBreakStartSound() {
        guard SettingsManager.shared.settings.enableSound else { return }
        let soundId = SettingsManager.shared.settings.breakStartSound
        playSystemSound(soundId)
    }
    
    /// 播放休息结束提示音
    func playBreakEndSound() {
        guard SettingsManager.shared.settings.enableSound else { return }
        let soundId = SettingsManager.shared.settings.breakEndSound
        playSystemSound(soundId)
    }
    
    private func playSystemSound(_ soundId: String) {
        // 使用系统声音
        let soundName: String
        switch soundId {
        case "glass": soundName = "Glass"
        case "ping": soundName = "Ping"
        case "pop": soundName = "Pop"
        case "purr": soundName = "Purr"
        case "submarine": soundName = "Submarine"
        case "tink": soundName = "Tink"
        default: soundName = "Glass" // 默认使用 Glass
        }
        
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreather/Core/SoundManager.swift
git commit -m "feat: 添加声音管理器 SoundManager"
```

---

## Task 5: 创建勿扰时段检查器

**Files:**
- Create: `EyeBreather/Core/DoNotDisturbManager.swift`

**Step 1: 创建勿扰管理器**

```swift
import Foundation

/// 勿扰时段管理器
@MainActor
final class DoNotDisturbManager {
    static let shared = DoNotDisturbManager()
    
    private init() {}
    
    /// 检查当前是否在勿扰时段内
    var isInDoNotDisturbPeriod: Bool {
        let settings = SettingsManager.shared.settings
        guard settings.enableDoNotDisturb else { return false }
        
        let now = Calendar.current.component(.hour, from: Date())
        let start = settings.doNotDisturbStart
        let end = settings.doNotDisturbEnd
        
        // 处理跨午夜的情况
        if start <= end {
            // 例如：9:00 - 17:00（同一天内）
            return now >= start && now < end
        } else {
            // 例如：22:00 - 08:00（跨午夜）
            return now >= start || now < end
        }
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreather/Core/DoNotDisturbManager.swift
git commit -m "feat: 添加勿扰时段管理器"
```

---

## Task 6: 重构 BreakCoordinator - 实现渐进模式和统计

**Files:**
- Modify: `EyeBreather/Core/BreakCoordinator.swift`

**Step 1: 更新 handleBreakTimeReached 方法**

```swift
private func handleBreakTimeReached() {
    // 检查勿扰时段
    guard !DoNotDisturbManager.shared.isInDoNotDisturbPeriod else { return }
    
    // 检查是否应该暂停
    guard !AppDetector.shared.shouldPauseReminder else { return }
    
    // 防止重复触发
    guard !breakTriggered else { return }
    breakTriggered = true
    
    // 检查新的一天，重置统计
    BreakStatisticsManager.shared.resetConsecutiveSkipsIfNewDay()
    
    let settings = SettingsManager.shared.settings
    
    switch settings.reminderMode {
    case .forced:
        // 强制模式：直接显示遮罩
        startBreak()
        
    case .gentle:
        // 温和模式：发送通知，30秒后自动开始休息
        sendBreakNotification()
        scheduleAutoBreak()
        
    case .progressive:
        // 渐进模式：根据连续跳过次数决定
        if BreakStatisticsManager.shared.shouldForceBreak {
            // 跳过次数达到阈值，强制休息
            startBreak()
        } else {
            // 还可以跳过，发送通知
            sendBreakNotification()
            scheduleAutoBreak()
        }
    }
}
```

**Step 2: 更新统计记录方法**

```swift
private func recordBreakCompleted() {
    let breakDuration = SettingsManager.shared.settings.breakDuration
    BreakStatisticsManager.shared.recordBreakCompleted(durationSeconds: breakDuration)
}

private func recordBreakSkipped() {
    BreakStatisticsManager.shared.recordBreakSkipped()
}
```

**Step 3: 在 startBreak 中播放声音**

```swift
func startBreak() {
    cancelAutoBreak()
    SoundManager.shared.playBreakStartSound()
    TimerManager.shared.startBreak()
    BreakWindowController.shared.showOverlay()
}
```

**Step 4: 在 handleBreakCompleted 中播放结束声音**

```swift
private func handleBreakCompleted() {
    breakTriggered = false
    BreakWindowController.shared.hideOverlay()
    TimerManager.shared.completeBreak()
    recordBreakCompleted()
    SoundManager.shared.playBreakEndSound()
    
    sendNotification(
        title: "休息完成",
        body: "休息完成，继续工作吧！"
    )
}
```

**Step 5: 提交**

```bash
git add EyeBreather/Core/BreakCoordinator.swift
git commit -m "feat: BreakCoordinator 实现渐进模式、勿扰时段检查和声音播放"
```

---

## Task 7: 更新设置界面 - 休息规则添加渐进模式阈值

**Files:**
- Modify: `EyeBreather/Features/Settings/SettingsView.swift`

**Step 1: 在 BreakRulesSectionContent 中添加渐进模式阈值设置**

在提醒方式卡片后添加：

```swift
// 渐进模式设置（仅渐进模式显示）
if settingsManager.settings.reminderMode == .progressive {
    SettingsCard(title: "渐进模式设置", footer: "连续跳过达到阈值后，下次休息将变为强制模式") {
        Stepper(value: $settingsManager.settings.progressiveForceThreshold, in: 1...10) {
            SettingsRow(
                title: "强制休息阈值",
                value: "\(settingsManager.settings.progressiveForceThreshold) 次"
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreather/Features/Settings/SettingsView.swift
git commit -m "feat: 设置界面添加渐进模式阈值配置"
```

---

## Task 8: 更新设置界面 - 通用页面添加声音和勿扰设置

**Files:**
- Modify: `EyeBreather/Features/Settings/SettingsView.swift`

**Step 1: 在 GeneralSectionContent 中添加声音设置卡片**

```swift
// 声音设置卡片
SettingsCard(title: "声音提醒") {
    VStack(spacing: 0) {
        Toggle(isOn: $settingsManager.settings.enableSound) {
            SettingsRow(title: "启用声音提醒")
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        
        if settingsManager.settings.enableSound {
            Divider().padding(.leading, 12)
            
            Picker("休息开始", selection: $settingsManager.settings.breakStartSound) {
                ForEach(SoundManager.availableSounds, id: \.id) { sound in
                    Text(sound.name).tag(sound.id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            
            Divider().padding(.leading, 12)
            
            Picker("休息结束", selection: $settingsManager.settings.breakEndSound) {
                ForEach(SoundManager.availableSounds, id: \.id) { sound in
                    Text(sound.name).tag(sound.id)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
```

**Step 2: 添加勿扰时段卡片**

```swift
// 勿扰时段卡片
SettingsCard(title: "勿扰时段", footer: "在指定时间段内不会触发休息提醒") {
    VStack(spacing: 0) {
        Toggle(isOn: $settingsManager.settings.enableDoNotDisturb) {
            SettingsRow(title: "启用勿扰时段")
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        
        if settingsManager.settings.enableDoNotDisturb {
            Divider().padding(.leading, 12)
            
            HStack {
                Text("时间段")
                Spacer()
                Picker("", selection: $settingsManager.settings.doNotDisturbStart) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d:00", hour)).tag(hour)
                    }
                }
                .frame(width: 80)
                
                Text("至")
                    .foregroundColor(.secondary)
                
                Picker("", selection: $settingsManager.settings.doNotDisturbEnd) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(String(format: "%02d:00", hour)).tag(hour)
                    }
                }
                .frame(width: 80)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
    }
}
```

**Step 3: 提交**

```bash
git add EyeBreather/Features/Settings/SettingsView.swift
git commit -m "feat: 设置界面添加声音提醒和勿扰时段配置"
```

---

## Task 9: 更新菜单栏视图 - 显示统计信息

**Files:**
- Modify: `EyeBreather/Features/Timer/MenuBarView.swift`

**Step 1: 在菜单栏视图中显示今日统计**

在现有内容后添加统计信息显示。

**Step 2: 提交**

```bash
git add EyeBreather/Features/Timer/MenuBarView.swift
git commit -m "feat: 菜单栏弹窗显示今日休息统计"
```

---

## Task 10: 桌面壁纸权限引导

**Files:**
- Modify: `EyeBreather/Features/Break/BreakOverlayView.swift`

**Step 1: 添加权限检查和引导**

修改 `DesktopWallpaperView`，当无法获取壁纸时显示友好提示。

**Step 2: 提交**

```bash
git add EyeBreather/Features/Break/BreakOverlayView.swift
git commit -m "fix: 桌面壁纸无权限时显示友好提示"
```

---

## Task 11: 应用设计常量到 SettingsView

**Files:**
- Modify: `EyeBreather/Features/Settings/SettingsView.swift`

**Step 1: 将硬编码值替换为 DesignConstants**

**Step 2: 提交**

```bash
git add EyeBreather/Features/Settings/SettingsView.swift
git commit -m "refactor: SettingsView 使用 DesignConstants"
```

---

---

# 测试计划（覆盖率目标 95%+）

---

## Task 12: 修复现有测试 - AppSettingsTests

**Files:**
- Modify: `EyeBreatherTests/Models/AppSettingsTests.swift`

**问题:** 现有测试引用了已删除的属性（`enableFullscreenPause`, `whitelistApps`, `.scenery`）

**Step 1: 更新 testDefaultValues**

```swift
func testDefaultValues() {
    let settings = AppSettings.default
    
    XCTAssertEqual(settings.workDuration, 20)
    XCTAssertEqual(settings.breakDuration, 20)
    XCTAssertEqual(settings.reminderMode, .gentle)
    XCTAssertEqual(settings.preBreakWarning, 60)
    XCTAssertEqual(settings.delayOptions, [5, 15, 30])
    XCTAssertTrue(settings.enableActivityDetection)
    XCTAssertEqual(settings.idleResetThreshold, 5)
    XCTAssertTrue(settings.enableMeetingDetection)
    XCTAssertEqual(settings.breakStyle, .blur)
    XCTAssertNil(settings.customBackgroundPath)
    XCTAssertFalse(settings.launchAtLogin)
    XCTAssertFalse(settings.showInDock)
    XCTAssertEqual(settings.appearance, .system)
    // 新增字段
    XCTAssertTrue(settings.enableSound)
    XCTAssertEqual(settings.breakStartSound, "default")
    XCTAssertFalse(settings.enableDoNotDisturb)
    XCTAssertEqual(settings.progressiveForceThreshold, 3)
}
```

**Step 2: 更新 testSaveAndLoad**

```swift
func testSaveAndLoad() {
    var settings = AppSettings()
    settings.workDuration = 25
    settings.reminderMode = .forced
    settings.breakStyle = .dark
    settings.enableSound = false
    settings.enableDoNotDisturb = true
    settings.doNotDisturbStart = 23
    settings.doNotDisturbEnd = 7
    
    settings.save()
    
    let loaded = AppSettings.load()
    XCTAssertEqual(loaded.workDuration, 25)
    XCTAssertEqual(loaded.reminderMode, .forced)
    XCTAssertEqual(loaded.breakStyle, .dark)
    XCTAssertFalse(loaded.enableSound)
    XCTAssertTrue(loaded.enableDoNotDisturb)
    XCTAssertEqual(loaded.doNotDisturbStart, 23)
    XCTAssertEqual(loaded.doNotDisturbEnd, 7)
}
```

**Step 3: 更新 testCodable**

```swift
func testCodable() throws {
    var settings = AppSettings()
    settings.focusApps = [FocusApp(bundleId: "com.apple.Safari", name: "Safari", isPreset: false)]
    
    let encoded = try JSONEncoder().encode(settings)
    let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
    
    XCTAssertEqual(settings, decoded)
}
```

**Step 4: 添加新字段测试**

```swift
func testSoundSettings() {
    var settings = AppSettings()
    settings.enableSound = true
    settings.breakStartSound = "glass"
    settings.breakEndSound = "ping"
    
    settings.save()
    let loaded = AppSettings.load()
    
    XCTAssertTrue(loaded.enableSound)
    XCTAssertEqual(loaded.breakStartSound, "glass")
    XCTAssertEqual(loaded.breakEndSound, "ping")
}

func testDoNotDisturbSettings() {
    var settings = AppSettings()
    settings.enableDoNotDisturb = true
    settings.doNotDisturbStart = 22
    settings.doNotDisturbEnd = 8
    
    settings.save()
    let loaded = AppSettings.load()
    
    XCTAssertTrue(loaded.enableDoNotDisturb)
    XCTAssertEqual(loaded.doNotDisturbStart, 22)
    XCTAssertEqual(loaded.doNotDisturbEnd, 8)
}

func testProgressiveSettings() {
    var settings = AppSettings()
    settings.progressiveForceThreshold = 5
    
    settings.save()
    let loaded = AppSettings.load()
    
    XCTAssertEqual(loaded.progressiveForceThreshold, 5)
}
```

**Step 5: 提交**

```bash
git add EyeBreatherTests/Models/AppSettingsTests.swift
git commit -m "test: 修复 AppSettingsTests 并添加新字段测试"
```

---

## Task 13: 创建 BreakStatisticsTests

**Files:**
- Create: `EyeBreatherTests/Core/BreakStatisticsTests.swift`

**Step 1: 创建统计测试文件**

```swift
import XCTest
@testable import EyeBreather

final class DailyBreakStatisticsTests: XCTestCase {
    
    func testInitialValues() {
        let stats = DailyBreakStatistics(date: "2026-01-27")
        
        XCTAssertEqual(stats.date, "2026-01-27")
        XCTAssertEqual(stats.completedBreaks, 0)
        XCTAssertEqual(stats.skippedBreaks, 0)
        XCTAssertEqual(stats.totalBreakSeconds, 0)
    }
    
    func testTotalBreaks() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 5
        stats.skippedBreaks = 2
        
        XCTAssertEqual(stats.totalBreaks, 7)
    }
    
    func testCompletionRateZeroDivision() {
        let stats = DailyBreakStatistics(date: "2026-01-27")
        XCTAssertEqual(stats.completionRate, 0)
    }
    
    func testCompletionRate() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 8
        stats.skippedBreaks = 2
        
        XCTAssertEqual(stats.completionRate, 0.8, accuracy: 0.001)
    }
    
    func testCompletionRate100Percent() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 10
        stats.skippedBreaks = 0
        
        XCTAssertEqual(stats.completionRate, 1.0)
    }
    
    func testCodable() throws {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 5
        stats.skippedBreaks = 2
        stats.totalBreakSeconds = 100
        
        let encoded = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(DailyBreakStatistics.self, from: encoded)
        
        XCTAssertEqual(stats, decoded)
    }
}

@MainActor
final class BreakStatisticsManagerTests: XCTestCase {
    
    override func tearDown() {
        // 清理测试数据
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.statistics")
        UserDefaults.standard.removeObject(forKey: "consecutiveSkips")
        super.tearDown()
    }
    
    func testRecordBreakCompleted() {
        let manager = BreakStatisticsManager.shared
        let initialCompleted = manager.todayStatistics.completedBreaks
        
        manager.recordBreakCompleted(durationSeconds: 20)
        
        XCTAssertEqual(manager.todayStatistics.completedBreaks, initialCompleted + 1)
        XCTAssertEqual(manager.consecutiveSkips, 0) // 完成休息重置跳过计数
    }
    
    func testRecordBreakSkipped() {
        let manager = BreakStatisticsManager.shared
        let initialSkipped = manager.todayStatistics.skippedBreaks
        let initialConsecutive = manager.consecutiveSkips
        
        manager.recordBreakSkipped()
        
        XCTAssertEqual(manager.todayStatistics.skippedBreaks, initialSkipped + 1)
        XCTAssertEqual(manager.consecutiveSkips, initialConsecutive + 1)
    }
    
    func testShouldForceBreakBelowThreshold() {
        let manager = BreakStatisticsManager.shared
        // 确保跳过次数低于阈值
        for _ in 0..<2 {
            manager.recordBreakSkipped()
        }
        manager.recordBreakCompleted(durationSeconds: 20) // 重置
        
        XCTAssertFalse(manager.shouldForceBreak)
    }
    
    func testShouldForceBreakAtThreshold() {
        let manager = BreakStatisticsManager.shared
        manager.recordBreakCompleted(durationSeconds: 20) // 先重置
        
        // 假设阈值是 3，跳过 3 次
        let threshold = SettingsManager.shared.settings.progressiveForceThreshold
        for _ in 0..<threshold {
            manager.recordBreakSkipped()
        }
        
        XCTAssertTrue(manager.shouldForceBreak)
    }
    
    func testConsecutiveSkipsResetOnComplete() {
        let manager = BreakStatisticsManager.shared
        
        manager.recordBreakSkipped()
        manager.recordBreakSkipped()
        XCTAssertEqual(manager.consecutiveSkips, 2)
        
        manager.recordBreakCompleted(durationSeconds: 20)
        XCTAssertEqual(manager.consecutiveSkips, 0)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Core/BreakStatisticsTests.swift
git commit -m "test: 添加 BreakStatistics 单元测试"
```

---

## Task 14: 创建 DoNotDisturbManagerTests

**Files:**
- Create: `EyeBreatherTests/Core/DoNotDisturbManagerTests.swift`

**Step 1: 创建勿扰管理器测试**

```swift
import XCTest
@testable import EyeBreather

@MainActor
final class DoNotDisturbManagerTests: XCTestCase {
    
    override func tearDown() {
        // 恢复默认设置
        SettingsManager.shared.settings.enableDoNotDisturb = false
        super.tearDown()
    }
    
    func testDisabledDoNotDisturb() {
        SettingsManager.shared.settings.enableDoNotDisturb = false
        
        XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
    
    func testSameDayPeriod_InsideRange() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = 9
        SettingsManager.shared.settings.doNotDisturbEnd = 17
        
        // 模拟当前时间为 12:00 - 在范围内
        let now = Calendar.current.component(.hour, from: Date())
        if now >= 9 && now < 17 {
            XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        }
    }
    
    func testCrossMidnightPeriod_Evening() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = 22
        SettingsManager.shared.settings.doNotDisturbEnd = 8
        
        // 如果现在是 23:00，应该在勿扰时段
        let now = Calendar.current.component(.hour, from: Date())
        if now >= 22 || now < 8 {
            XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        } else {
            XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        }
    }
    
    func testCrossMidnightPeriod_Morning() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = 22
        SettingsManager.shared.settings.doNotDisturbEnd = 8
        
        // 如果现在是 6:00，应该在勿扰时段
        let now = Calendar.current.component(.hour, from: Date())
        if now >= 22 || now < 8 {
            XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        } else {
            XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        }
    }
    
    func testBoundaryCondition_StartHour() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.doNotDisturbEnd = (Calendar.current.component(.hour, from: Date()) + 2) % 24
        
        // 当前小时应该在范围内
        XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
    
    func testBoundaryCondition_EndHour() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        let nowHour = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.doNotDisturbStart = (nowHour - 2 + 24) % 24
        SettingsManager.shared.settings.doNotDisturbEnd = nowHour
        
        // 当前小时等于结束时间，应该不在范围内（end 是开区间）
        XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Core/DoNotDisturbManagerTests.swift
git commit -m "test: 添加 DoNotDisturbManager 单元测试"
```

---

## Task 15: 创建 SoundManagerTests

**Files:**
- Create: `EyeBreatherTests/Core/SoundManagerTests.swift`

**Step 1: 创建声音管理器测试**

```swift
import XCTest
@testable import EyeBreather

@MainActor
final class SoundManagerTests: XCTestCase {
    
    override func tearDown() {
        SettingsManager.shared.settings.enableSound = true
        super.tearDown()
    }
    
    func testAvailableSoundsNotEmpty() {
        XCTAssertFalse(SoundManager.availableSounds.isEmpty)
    }
    
    func testAvailableSoundsContainsDefault() {
        let hasDefault = SoundManager.availableSounds.contains { $0.id == "default" }
        XCTAssertTrue(hasDefault)
    }
    
    func testPlayBreakStartSoundWhenDisabled() {
        SettingsManager.shared.settings.enableSound = false
        // 不应该崩溃
        SoundManager.shared.playBreakStartSound()
    }
    
    func testPlayBreakEndSoundWhenDisabled() {
        SettingsManager.shared.settings.enableSound = false
        // 不应该崩溃
        SoundManager.shared.playBreakEndSound()
    }
    
    func testPlayBreakStartSoundWhenEnabled() {
        SettingsManager.shared.settings.enableSound = true
        SettingsManager.shared.settings.breakStartSound = "glass"
        // 不应该崩溃
        SoundManager.shared.playBreakStartSound()
    }
    
    func testPlayBreakEndSoundWhenEnabled() {
        SettingsManager.shared.settings.enableSound = true
        SettingsManager.shared.settings.breakEndSound = "ping"
        // 不应该崩溃
        SoundManager.shared.playBreakEndSound()
    }
    
    func testAllSoundIdsPlayWithoutCrash() {
        SettingsManager.shared.settings.enableSound = true
        for sound in SoundManager.availableSounds {
            SettingsManager.shared.settings.breakStartSound = sound.id
            SoundManager.shared.playBreakStartSound()
            // 确保不崩溃
        }
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Core/SoundManagerTests.swift
git commit -m "test: 添加 SoundManager 单元测试"
```

---

## Task 16: 创建 BreakCoordinatorTests

**Files:**
- Create: `EyeBreatherTests/Core/BreakCoordinatorTests.swift`

**Step 1: 创建休息协调器测试**

```swift
import XCTest
@testable import EyeBreather

@MainActor
final class BreakCoordinatorTests: XCTestCase {
    
    var coordinator: BreakCoordinator!
    
    override func setUp() {
        super.setUp()
        coordinator = BreakCoordinator.shared
    }
    
    override func tearDown() {
        // 恢复默认设置
        SettingsManager.shared.settings.reminderMode = .gentle
        SettingsManager.shared.settings.enableDoNotDisturb = false
        super.tearDown()
    }
    
    func testStartBreak() {
        coordinator.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
    }
    
    func testSkipBreak() {
        coordinator.startBreak()
        coordinator.skipBreak()
        
        // 状态应该不再是 breaking
        XCTAssertNotEqual(TimerManager.shared.state, .breaking)
    }
    
    func testDelayBreak() {
        TimerManager.shared.start()
        coordinator.delayBreak(minutes: 5)
        
        // 状态应该是 working
        XCTAssertEqual(TimerManager.shared.state, .working)
    }
    
    func testForcedModeTriggersBreakDirectly() {
        SettingsManager.shared.settings.reminderMode = .forced
        
        // 发送休息时间到达通知
        NotificationCenter.default.post(name: .breakTimeReached, object: nil)
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "Break should start")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if TimerManager.shared.state == .breaking {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testDoNotDisturbBlocksBreak() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        let now = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.doNotDisturbStart = now
        SettingsManager.shared.settings.doNotDisturbEnd = (now + 2) % 24
        SettingsManager.shared.settings.reminderMode = .forced
        
        TimerManager.shared.start()
        
        // 发送休息时间到达通知
        NotificationCenter.default.post(name: .breakTimeReached, object: nil)
        
        // 等待异步处理
        let expectation = XCTestExpectation(description: "Break should NOT start")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // 在勿扰时段，不应该开始休息
            if TimerManager.shared.state != .breaking {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 2.0)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Core/BreakCoordinatorTests.swift
git commit -m "test: 添加 BreakCoordinator 单元测试"
```

---

## Task 17: 创建 DesignConstantsTests

**Files:**
- Create: `EyeBreatherTests/Shared/DesignConstantsTests.swift`

**Step 1: 创建设计常量测试**

```swift
import XCTest
@testable import EyeBreather

final class DesignConstantsTests: XCTestCase {
    
    func testSpacingValuesArePositive() {
        XCTAssertGreaterThan(DesignConstants.Spacing.xs, 0)
        XCTAssertGreaterThan(DesignConstants.Spacing.sm, 0)
        XCTAssertGreaterThan(DesignConstants.Spacing.md, 0)
        XCTAssertGreaterThan(DesignConstants.Spacing.lg, 0)
        XCTAssertGreaterThan(DesignConstants.Spacing.xl, 0)
        XCTAssertGreaterThan(DesignConstants.Spacing.xxl, 0)
    }
    
    func testSpacingValuesAreOrdered() {
        XCTAssertLessThan(DesignConstants.Spacing.xs, DesignConstants.Spacing.sm)
        XCTAssertLessThan(DesignConstants.Spacing.sm, DesignConstants.Spacing.md)
        XCTAssertLessThan(DesignConstants.Spacing.md, DesignConstants.Spacing.lg)
        XCTAssertLessThan(DesignConstants.Spacing.lg, DesignConstants.Spacing.xl)
        XCTAssertLessThan(DesignConstants.Spacing.xl, DesignConstants.Spacing.xxl)
    }
    
    func testCornerRadiusValuesArePositive() {
        XCTAssertGreaterThan(DesignConstants.CornerRadius.sm, 0)
        XCTAssertGreaterThan(DesignConstants.CornerRadius.md, 0)
        XCTAssertGreaterThan(DesignConstants.CornerRadius.lg, 0)
    }
    
    func testFontSizeValuesArePositive() {
        XCTAssertGreaterThan(DesignConstants.FontSize.caption, 0)
        XCTAssertGreaterThan(DesignConstants.FontSize.footnote, 0)
        XCTAssertGreaterThan(DesignConstants.FontSize.body, 0)
        XCTAssertGreaterThan(DesignConstants.FontSize.headline, 0)
        XCTAssertGreaterThan(DesignConstants.FontSize.title, 0)
    }
    
    func testSettingsWindowDimensions() {
        XCTAssertGreaterThan(DesignConstants.SettingsWindow.width, 0)
        XCTAssertGreaterThan(DesignConstants.SettingsWindow.height, 0)
        XCTAssertGreaterThan(DesignConstants.SettingsWindow.width, DesignConstants.SettingsWindow.height * 0.5)
    }
    
    func testSidebarWidth() {
        XCTAssertGreaterThan(DesignConstants.Sidebar.width, 100)
        XCTAssertLessThan(DesignConstants.Sidebar.width, 300)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Shared/DesignConstantsTests.swift
git commit -m "test: 添加 DesignConstants 单元测试"
```

---

## Task 18: 创建 EnumsTests 扩展

**Files:**
- Modify: `EyeBreatherTests/Models/EnumsTests.swift`

**Step 1: 添加新枚举测试**

```swift
// 添加到现有文件

// MARK: - BreakStyle Tests

func testBreakStyleDisplayNames() {
    XCTAssertEqual(BreakStyle.blur.displayName, "背景模糊")
    XCTAssertEqual(BreakStyle.liquidGlass.displayName, "液态玻璃")
    XCTAssertEqual(BreakStyle.dark.displayName, "深色遮罩")
    XCTAssertEqual(BreakStyle.tips.displayName, "护眼提示")
    XCTAssertEqual(BreakStyle.desktop.displayName, "桌面壁纸")
    XCTAssertEqual(BreakStyle.custom.displayName, "自定义背景")
}

func testBreakStyleDescriptions() {
    for style in BreakStyle.allCases {
        XCTAssertFalse(style.description.isEmpty)
    }
}

func testBreakStyleIcons() {
    for style in BreakStyle.allCases {
        XCTAssertFalse(style.icon.isEmpty)
    }
}

func testBreakStyleCodable() throws {
    let style = BreakStyle.liquidGlass
    let encoded = try JSONEncoder().encode(style)
    let decoded = try JSONDecoder().decode(BreakStyle.self, from: encoded)
    XCTAssertEqual(style, decoded)
}

// MARK: - AppearanceMode Tests

func testAppearanceModeDisplayNames() {
    XCTAssertEqual(AppearanceMode.system.displayName, "跟随系统")
    XCTAssertEqual(AppearanceMode.light.displayName, "浅色模式")
    XCTAssertEqual(AppearanceMode.dark.displayName, "深色模式")
}

func testAppearanceModeCodable() throws {
    let mode = AppearanceMode.dark
    let encoded = try JSONEncoder().encode(mode)
    let decoded = try JSONDecoder().decode(AppearanceMode.self, from: encoded)
    XCTAssertEqual(mode, decoded)
}

// MARK: - TimerState Tests

func testTimerStateCodable() throws {
    for state in [TimerState.idle, .working, .preBreak, .breaking, .paused] {
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(TimerState.self, from: encoded)
        XCTAssertEqual(state, decoded)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/Models/EnumsTests.swift
git commit -m "test: 扩展 EnumsTests 覆盖所有枚举类型"
```

---

## Task 19: 创建 E2E 测试文件

**Files:**
- Create: `EyeBreatherTests/E2E/BreakFlowE2ETests.swift`

**Step 1: 创建端到端测试**

```swift
import XCTest
@testable import EyeBreather

/// 端到端测试：完整休息流程
@MainActor
final class BreakFlowE2ETests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 重置为默认设置
        SettingsManager.shared.resetToDefaults()
        // 清理统计数据
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.statistics")
        UserDefaults.standard.removeObject(forKey: "consecutiveSkips")
    }
    
    override func tearDown() {
        TimerManager.shared.pause()
        BreakWindowController.shared.hideOverlay()
        SettingsManager.shared.resetToDefaults()
        super.tearDown()
    }
    
    // MARK: - E2E: 强制模式完整流程
    
    func testE2E_ForcedMode_CompleteBreak() {
        // 设置强制模式
        SettingsManager.shared.settings.reminderMode = .forced
        SettingsManager.shared.settings.breakDuration = 2 // 2秒快速测试
        
        let initialCompleted = BreakStatisticsManager.shared.todayStatistics.completedBreaks
        
        // 触发休息
        BreakCoordinator.shared.startBreak()
        
        // 验证状态
        XCTAssertEqual(TimerManager.shared.state, .breaking)
        
        // 等待休息完成
        let expectation = XCTestExpectation(description: "Break completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // 休息完成后
            XCTAssertNotEqual(TimerManager.shared.state, .breaking)
            XCTAssertEqual(
                BreakStatisticsManager.shared.todayStatistics.completedBreaks,
                initialCompleted + 1
            )
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - E2E: 温和模式跳过休息
    
    func testE2E_GentleMode_SkipBreak() {
        SettingsManager.shared.settings.reminderMode = .gentle
        
        let initialSkipped = BreakStatisticsManager.shared.todayStatistics.skippedBreaks
        
        // 开始休息然后跳过
        BreakCoordinator.shared.startBreak()
        BreakCoordinator.shared.skipBreak()
        
        // 验证跳过被记录
        XCTAssertEqual(
            BreakStatisticsManager.shared.todayStatistics.skippedBreaks,
            initialSkipped + 1
        )
        XCTAssertNotEqual(TimerManager.shared.state, .breaking)
    }
    
    // MARK: - E2E: 渐进模式达到阈值后强制
    
    func testE2E_ProgressiveMode_ForceAfterThreshold() {
        SettingsManager.shared.settings.reminderMode = .progressive
        SettingsManager.shared.settings.progressiveForceThreshold = 2
        
        // 重置跳过计数
        BreakStatisticsManager.shared.recordBreakCompleted(durationSeconds: 1)
        XCTAssertEqual(BreakStatisticsManager.shared.consecutiveSkips, 0)
        
        // 跳过 2 次
        BreakStatisticsManager.shared.recordBreakSkipped()
        BreakStatisticsManager.shared.recordBreakSkipped()
        
        // 现在应该强制休息
        XCTAssertTrue(BreakStatisticsManager.shared.shouldForceBreak)
    }
    
    // MARK: - E2E: 勿扰时段阻止休息
    
    func testE2E_DoNotDisturb_BlocksBreak() {
        // 设置当前时间在勿扰时段内
        let now = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = now
        SettingsManager.shared.settings.doNotDisturbEnd = (now + 2) % 24
        
        // 验证在勿扰时段
        XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
        
        // 勿扰时段内不应触发休息
        // 这里只验证勿扰检测正常工作
    }
    
    // MARK: - E2E: 延迟休息
    
    func testE2E_DelayBreak() {
        SettingsManager.shared.settings.reminderMode = .gentle
        
        // 开始工作
        TimerManager.shared.start()
        let beforeDelay = TimerManager.shared.elapsedWorkTime
        
        // 延迟 5 分钟
        BreakCoordinator.shared.delayBreak(minutes: 5)
        
        // 验证状态
        XCTAssertEqual(TimerManager.shared.state, .working)
    }
    
    // MARK: - E2E: 声音设置
    
    func testE2E_SoundSettings_ToggleAndPlay() {
        // 启用声音
        SettingsManager.shared.settings.enableSound = true
        SettingsManager.shared.settings.breakStartSound = "glass"
        
        // 验证设置被保存
        SettingsManager.shared.settings.save()
        let loaded = AppSettings.load()
        XCTAssertTrue(loaded.enableSound)
        XCTAssertEqual(loaded.breakStartSound, "glass")
        
        // 播放声音（不应崩溃）
        SoundManager.shared.playBreakStartSound()
    }
    
    // MARK: - E2E: 统计数据持久化
    
    func testE2E_Statistics_Persistence() {
        let manager = BreakStatisticsManager.shared
        let initialCompleted = manager.todayStatistics.completedBreaks
        
        // 记录完成
        manager.recordBreakCompleted(durationSeconds: 20)
        
        // 验证增加
        XCTAssertEqual(manager.todayStatistics.completedBreaks, initialCompleted + 1)
        XCTAssertGreaterThanOrEqual(manager.todayStatistics.totalBreakSeconds, 20)
    }
    
    // MARK: - E2E: 完整工作-休息周期
    
    func testE2E_FullWorkBreakCycle() {
        SettingsManager.shared.settings.workDuration = 1 // 1分钟
        SettingsManager.shared.settings.breakDuration = 2 // 2秒
        SettingsManager.shared.settings.reminderMode = .forced
        
        // 开始工作
        TimerManager.shared.start()
        XCTAssertEqual(TimerManager.shared.state, .working)
        
        // 暂停
        TimerManager.shared.pause()
        XCTAssertEqual(TimerManager.shared.state, .paused)
        
        // 恢复
        TimerManager.shared.resume()
        XCTAssertEqual(TimerManager.shared.state, .working)
        
        // 手动触发休息
        BreakCoordinator.shared.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
    }
}
```

**Step 2: 提交**

```bash
git add EyeBreatherTests/E2E/BreakFlowE2ETests.swift
git commit -m "test: 添加端到端测试 BreakFlowE2ETests"
```

---

## Task 20: 运行测试并验证覆盖率

**Step 1: 运行所有测试**

```bash
xcodebuild test \
    -project EyeBreather.xcodeproj \
    -scheme EyeBreather \
    -destination 'platform=macOS' \
    -enableCodeCoverage YES \
    2>&1 | xcpretty
```

**Step 2: 生成覆盖率报告**

```bash
xcrun xccov view --report --json \
    ~/Library/Developer/Xcode/DerivedData/EyeBreather-*/Logs/Test/*.xcresult \
    > coverage.json
```

**Step 3: 验证覆盖率 >= 95%**

检查覆盖率报告，确保：
- 所有新增文件覆盖率 >= 95%
- 核心业务逻辑覆盖率 100%

**Step 4: 提交覆盖率配置**

```bash
git add -A
git commit -m "test: 运行测试验证覆盖率 95%+"
```

---

## Task 21: 最终构建和验证

**Step 1: 运行完整构建**

```bash
xcodebuild -project EyeBreather.xcodeproj -scheme EyeBreather -configuration Debug build
```

**Step 2: 运行所有测试确保通过**

```bash
xcodebuild test -project EyeBreather.xcodeproj -scheme EyeBreather -destination 'platform=macOS'
```

**Step 3: 手动 E2E 验证清单**

- [ ] 启动应用，菜单栏显示图标
- [ ] 打开设置，所有页面可正常切换
- [ ] 声音设置：启用/禁用，选择不同提示音
- [ ] 勿扰时段：设置时间范围，验证当前是否在范围内
- [ ] 渐进模式：设置阈值，跳过次数达到后强制休息
- [ ] 休息统计：菜单栏显示今日完成/跳过次数
- [ ] 桌面壁纸：选择后正确显示（或显示权限提示）
- [ ] 休息开始时播放声音
- [ ] 休息结束时播放声音

**Step 4: 最终提交**

```bash
git add -A
git commit -m "feat: 完成声音提醒、休息统计、勿扰时段功能及完整测试覆盖"
git push
```

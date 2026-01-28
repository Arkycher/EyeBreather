import XCTest
@testable import EyeBreather

/// 端到端测试：完整休息流程
@MainActor
final class BreakFlowE2ETests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        SettingsManager.shared.resetToDefaults()
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
        SettingsManager.shared.settings.reminderMode = .forced
        SettingsManager.shared.settings.breakDuration = 2
        
        BreakCoordinator.shared.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
    }
    
    // MARK: - E2E: 温和模式跳过休息
    
    func testE2E_GentleMode_SkipBreak() {
        SettingsManager.shared.settings.reminderMode = .gentle
        
        let initialSkipped = BreakStatisticsManager.shared.todayStatistics.skippedBreaks
        
        BreakCoordinator.shared.startBreak()
        BreakCoordinator.shared.skipBreak()
        
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
        
        BreakStatisticsManager.shared.recordBreakCompleted(durationSeconds: 1)
        XCTAssertEqual(BreakStatisticsManager.shared.consecutiveSkips, 0)
        
        BreakStatisticsManager.shared.recordBreakSkipped()
        BreakStatisticsManager.shared.recordBreakSkipped()
        
        XCTAssertTrue(BreakStatisticsManager.shared.shouldForceBreak)
    }
    
    // MARK: - E2E: 勿扰时段验证
    
    func testE2E_DoNotDisturb_IsEnabled() {
        let now = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.enableDoNotDisturb = true
        SettingsManager.shared.settings.doNotDisturbStart = now
        SettingsManager.shared.settings.doNotDisturbEnd = (now + 2) % 24
        
        XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
    
    // MARK: - E2E: 延迟休息
    
    func testE2E_DelayBreak() {
        SettingsManager.shared.settings.reminderMode = .gentle
        
        TimerManager.shared.start()
        BreakCoordinator.shared.delayBreak(minutes: 5)
        
        XCTAssertEqual(TimerManager.shared.state, .working)
    }
    
    // MARK: - E2E: 声音设置
    
    func testE2E_SoundSettings_ToggleAndPlay() {
        SettingsManager.shared.settings.enableSound = true
        SettingsManager.shared.settings.breakStartSound = "glass"
        
        SettingsManager.shared.settings.save()
        let loaded = AppSettings.load()
        XCTAssertTrue(loaded.enableSound)
        XCTAssertEqual(loaded.breakStartSound, "glass")
        
        SoundManager.shared.playBreakStartSound()
    }
    
    // MARK: - E2E: 统计数据持久化
    
    func testE2E_Statistics_Persistence() {
        let manager = BreakStatisticsManager.shared
        let initialCompleted = manager.todayStatistics.completedBreaks
        
        manager.recordBreakCompleted(durationSeconds: 20)
        
        XCTAssertEqual(manager.todayStatistics.completedBreaks, initialCompleted + 1)
        XCTAssertGreaterThanOrEqual(manager.todayStatistics.totalBreakSeconds, 20)
    }
    
    // MARK: - E2E: 完整工作-休息周期
    
    func testE2E_FullWorkBreakCycle() {
        SettingsManager.shared.settings.workDuration = 1
        SettingsManager.shared.settings.breakDuration = 2
        SettingsManager.shared.settings.reminderMode = .forced
        
        // 测试开始工作
        TimerManager.shared.start()
        XCTAssertEqual(TimerManager.shared.state, .working)
        
        // 测试开始休息
        BreakCoordinator.shared.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
    }
}

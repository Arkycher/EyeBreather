import XCTest
@testable import EyeBreather

final class AppSettingsTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // 测试前清理数据
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.settings")
    }
    
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
        XCTAssertTrue(settings.enableMeetingDetection)
        XCTAssertEqual(settings.breakStyle, .blur)
        XCTAssertNil(settings.customBackgroundPath)
        XCTAssertFalse(settings.launchAtLogin)
        XCTAssertFalse(settings.showInDock)
        XCTAssertEqual(settings.appearance, .system)
        // 新增字段
        XCTAssertTrue(settings.enableSound)
        XCTAssertEqual(settings.breakStartSound, "default")
        XCTAssertEqual(settings.breakEndSound, "default")
        XCTAssertFalse(settings.enableDoNotDisturb)
        XCTAssertEqual(settings.doNotDisturbStart, 22)
        XCTAssertEqual(settings.doNotDisturbEnd, 8)
        XCTAssertEqual(settings.progressiveForceThreshold, 3)
    }
    
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
    
    func testLoadReturnsDefaultWhenNoData() {
        UserDefaults.standard.removeObject(forKey: "com.eyebreather.settings")
        
        let loaded = AppSettings.load()
        XCTAssertEqual(loaded, AppSettings.default)
    }
    
    func testCodable() throws {
        var settings = AppSettings()
        settings.focusApps = [FocusApp(bundleId: "com.apple.Safari", name: "Safari", isPreset: false)]
        
        let encoded = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(AppSettings.self, from: encoded)
        
        XCTAssertEqual(settings, decoded)
    }
    
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
}

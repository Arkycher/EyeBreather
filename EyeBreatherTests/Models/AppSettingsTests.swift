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

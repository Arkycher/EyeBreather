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

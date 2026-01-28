import XCTest
@testable import EyeBreather

@MainActor
final class DoNotDisturbManagerTests: XCTestCase {
    
    override func tearDown() {
        SettingsManager.shared.settings.enableDoNotDisturb = false
        super.tearDown()
    }
    
    func testDisabledDoNotDisturb() {
        SettingsManager.shared.settings.enableDoNotDisturb = false
        XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
    
    func testBoundaryCondition_StartHour() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        let now = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.doNotDisturbStart = now
        SettingsManager.shared.settings.doNotDisturbEnd = (now + 2) % 24
        
        XCTAssertTrue(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
    
    func testBoundaryCondition_EndHour() {
        SettingsManager.shared.settings.enableDoNotDisturb = true
        let nowHour = Calendar.current.component(.hour, from: Date())
        SettingsManager.shared.settings.doNotDisturbStart = (nowHour - 2 + 24) % 24
        SettingsManager.shared.settings.doNotDisturbEnd = nowHour
        
        XCTAssertFalse(DoNotDisturbManager.shared.isInDoNotDisturbPeriod)
    }
}

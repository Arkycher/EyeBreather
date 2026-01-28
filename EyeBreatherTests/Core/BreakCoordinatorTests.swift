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
        SettingsManager.shared.settings.reminderMode = .gentle
        SettingsManager.shared.settings.enableDoNotDisturb = false
        TimerManager.shared.pause()
        super.tearDown()
    }
    
    func testStartBreak() {
        coordinator.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
    }
    
    func testSkipBreak() {
        coordinator.startBreak()
        coordinator.skipBreak()
        XCTAssertNotEqual(TimerManager.shared.state, .breaking)
    }
    
    func testDelayBreak() {
        TimerManager.shared.start()
        coordinator.delayBreak(minutes: 5)
        XCTAssertEqual(TimerManager.shared.state, .working)
    }
}

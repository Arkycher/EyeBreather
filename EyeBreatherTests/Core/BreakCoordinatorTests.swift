import XCTest
import UserNotifications
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
        SettingsManager.shared.settings.idleResetThreshold = 5
        BreakWindowController.shared.hideOverlay()
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

    func testPausedBreakRestoresOverlayOnResume() {
        coordinator.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
        XCTAssertTrue(BreakWindowController.shared.isShowingOverlay)

        NotificationCenter.default.post(name: .shouldPauseReminder, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(TimerManager.shared.state, .paused)
        XCTAssertFalse(BreakWindowController.shared.isShowingOverlay)

        NotificationCenter.default.post(name: .shouldResumeReminder, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(TimerManager.shared.state, .breaking)
        XCTAssertTrue(BreakWindowController.shared.isShowingOverlay)
    }

    func testReminderResumeDoesNotResumeManualPause() {
        TimerManager.shared.start()
        TimerManager.shared.pause()
        XCTAssertEqual(TimerManager.shared.state, .paused)

        NotificationCenter.default.post(name: .shouldResumeReminder, object: nil)
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))

        XCTAssertEqual(TimerManager.shared.state, .paused)
        XCTAssertFalse(BreakWindowController.shared.isShowingOverlay)
    }

    func testIdleResetDoesNotDesynchronizeActiveBreakOverlay() {
        SettingsManager.shared.settings.idleResetThreshold = 1
        coordinator.startBreak()
        XCTAssertEqual(TimerManager.shared.state, .breaking)
        XCTAssertTrue(BreakWindowController.shared.isShowingOverlay)

        TimerManager.shared.debugSetLastActivityTime(Date().addingTimeInterval(-120))
        TimerManager.shared.checkIdleReset()

        XCTAssertEqual(TimerManager.shared.state, .breaking)
        XCTAssertTrue(BreakWindowController.shared.isShowingOverlay)
    }

    func testPlainNotificationClickDoesNotStartBreak() {
        let delegate = AppDelegate()
        XCTAssertNotEqual(TimerManager.shared.state, .breaking)

        delegate.handleNotificationAction(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            categoryIdentifier: ""
        )

        XCTAssertNotEqual(TimerManager.shared.state, .breaking)
        XCTAssertFalse(BreakWindowController.shared.isShowingOverlay)
    }

    func testBreakReminderClickStartsBreak() {
        let delegate = AppDelegate()
        XCTAssertNotEqual(TimerManager.shared.state, .breaking)

        delegate.handleNotificationAction(
            actionIdentifier: UNNotificationDefaultActionIdentifier,
            categoryIdentifier: "BREAK_REMINDER"
        )

        XCTAssertEqual(TimerManager.shared.state, .breaking)
        XCTAssertTrue(BreakWindowController.shared.isShowingOverlay)
    }
}

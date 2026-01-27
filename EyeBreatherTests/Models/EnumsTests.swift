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

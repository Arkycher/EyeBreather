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
    
    func testTimerStateRawValues() {
        XCTAssertEqual(TimerState.idle.rawValue, "idle")
        XCTAssertEqual(TimerState.working.rawValue, "working")
        XCTAssertEqual(TimerState.breaking.rawValue, "breaking")
    }
    
    func testTimerStateCodable() throws {
        for state in [TimerState.idle, .working, .preBreak, .breaking, .paused] {
            let encoded = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(TimerState.self, from: encoded)
            XCTAssertEqual(state, decoded)
        }
    }
}

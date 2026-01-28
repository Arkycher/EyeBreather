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
    }
    
    func testSidebarWidth() {
        XCTAssertGreaterThan(DesignConstants.Sidebar.width, 100)
        XCTAssertLessThan(DesignConstants.Sidebar.width, 300)
    }
}

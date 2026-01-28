import XCTest
@testable import EyeBreather

final class DailyBreakStatisticsTests: XCTestCase {
    
    func testInitialValues() {
        let stats = DailyBreakStatistics(date: "2026-01-27")
        
        XCTAssertEqual(stats.date, "2026-01-27")
        XCTAssertEqual(stats.completedBreaks, 0)
        XCTAssertEqual(stats.skippedBreaks, 0)
        XCTAssertEqual(stats.totalBreakSeconds, 0)
    }
    
    func testTotalBreaks() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 5
        stats.skippedBreaks = 2
        
        XCTAssertEqual(stats.totalBreaks, 7)
    }
    
    func testCompletionRateZeroDivision() {
        let stats = DailyBreakStatistics(date: "2026-01-27")
        XCTAssertEqual(stats.completionRate, 0)
    }
    
    func testCompletionRate() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 8
        stats.skippedBreaks = 2
        
        XCTAssertEqual(stats.completionRate, 0.8, accuracy: 0.001)
    }
    
    func testCompletionRate100Percent() {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 10
        stats.skippedBreaks = 0
        
        XCTAssertEqual(stats.completionRate, 1.0)
    }
    
    func testCodable() throws {
        var stats = DailyBreakStatistics(date: "2026-01-27")
        stats.completedBreaks = 5
        stats.skippedBreaks = 2
        stats.totalBreakSeconds = 100
        
        let encoded = try JSONEncoder().encode(stats)
        let decoded = try JSONDecoder().decode(DailyBreakStatistics.self, from: encoded)
        
        XCTAssertEqual(stats, decoded)
    }
}

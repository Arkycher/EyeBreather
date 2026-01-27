import XCTest
import SwiftData
@testable import EyeBreather

final class SwiftDataModelsTests: XCTestCase {
    
    // MARK: - BreakRecord Tests
    
    func testBreakRecordInit() {
        let record = BreakRecord(
            expectedDuration: 20,
            completed: true
        )
        
        XCTAssertNotNil(record.id)
        XCTAssertEqual(record.expectedDuration, 20)
        XCTAssertTrue(record.completed)
        XCTAssertFalse(record.skipped)
        XCTAssertFalse(record.dateKey.isEmpty)
    }
    
    func testBreakRecordDateKey() {
        let date = Date()
        let record = BreakRecord(startTime: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let expectedKey = formatter.string(from: date)
        
        XCTAssertEqual(record.dateKey, expectedKey)
    }
    
    // MARK: - DailyStatistics Tests
    
    func testDailyStatisticsInit() {
        let stats = DailyStatistics()
        
        XCTAssertEqual(stats.totalActiveTime, 0)
        XCTAssertEqual(stats.completedBreaks, 0)
        XCTAssertEqual(stats.skippedBreaks, 0)
        XCTAssertFalse(stats.dateKey.isEmpty)
    }
    
    func testCompletionRate() {
        let stats = DailyStatistics(
            completedBreaks: 8,
            skippedBreaks: 2
        )
        
        XCTAssertEqual(stats.totalBreaks, 10)
        XCTAssertEqual(stats.completionRate, 0.8, accuracy: 0.001)
    }
    
    func testCompletionRateWhenNoBreaks() {
        let stats = DailyStatistics()
        
        XCTAssertEqual(stats.completionRate, 0)
    }
    
    func testFormattedActiveTime() {
        let statsMinutes = DailyStatistics(totalActiveTime: 45 * 60) // 45 分钟
        XCTAssertEqual(statsMinutes.formattedActiveTime, "45m")
        
        let statsHours = DailyStatistics(totalActiveTime: 3 * 3600 + 24 * 60) // 3h 24m
        XCTAssertEqual(statsHours.formattedActiveTime, "3h 24m")
    }
}

import XCTest
@testable import EyeBreather

@MainActor
final class TimerManagerTests: XCTestCase {
    
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager.shared
        // 停止任何现有计时
        timerManager.pause()
    }
    
    override func tearDown() {
        timerManager.pause()
        super.tearDown()
    }
    
    func testInitialState() {
        // 由于是单例，状态可能不是 idle，我们测试基本属性
        XCTAssertGreaterThanOrEqual(timerManager.elapsedWorkTime, 0)
        XCTAssertGreaterThanOrEqual(timerManager.elapsedBreakTime, 0)
    }
    
    func testStart() {
        timerManager.pause() // 确保是暂停状态
        timerManager.start()
        XCTAssertEqual(timerManager.state, .working)
    }
    
    func testPauseFromWorking() {
        timerManager.start()
        timerManager.pause()
        XCTAssertEqual(timerManager.state, .paused)
    }
    
    func testResume() {
        timerManager.start()
        timerManager.pause()
        timerManager.resume()
        XCTAssertEqual(timerManager.state, .working)
    }
    
    func testStartBreak() {
        timerManager.startBreak()
        XCTAssertEqual(timerManager.state, .breaking)
        XCTAssertEqual(timerManager.elapsedBreakTime, 0)
    }
    
    func testWorkProgress() {
        XCTAssertGreaterThanOrEqual(timerManager.workProgress, 0)
        XCTAssertLessThanOrEqual(timerManager.workProgress, 1)
    }
    
    func testRemainingWorkTime() {
        XCTAssertGreaterThanOrEqual(timerManager.remainingWorkTime, 0)
    }
    
    func testRecordActivity() {
        let before = timerManager.lastActivityTime
        Thread.sleep(forTimeInterval: 0.1)
        timerManager.recordActivity()
        XCTAssertGreaterThan(timerManager.lastActivityTime, before)
    }
}

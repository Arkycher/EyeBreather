import Foundation
import SwiftData

/// 休息记录
@Model
final class BreakRecord {
    /// 唯一标识
    var id: UUID
    
    /// 开始时间
    var startTime: Date
    
    /// 实际休息时长（秒）
    var duration: Int
    
    /// 预期休息时长（秒）
    var expectedDuration: Int
    
    /// 是否完成
    var completed: Bool
    
    /// 是否跳过
    var skipped: Bool
    
    /// 所属日期（用于关联查询，格式：yyyy-MM-dd）
    var dateKey: String
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        duration: Int = 0,
        expectedDuration: Int = 20,
        completed: Bool = false,
        skipped: Bool = false
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.expectedDuration = expectedDuration
        self.completed = completed
        self.skipped = skipped
        self.dateKey = Self.dateKeyFormatter.string(from: startTime)
    }
    
    /// 日期格式化器
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

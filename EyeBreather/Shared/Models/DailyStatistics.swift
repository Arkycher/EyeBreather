import Foundation
import SwiftData

/// 每日统计
@Model
final class DailyStatistics {
    /// 日期键（格式：yyyy-MM-dd）
    @Attribute(.unique) var dateKey: String
    
    /// 该日期
    var date: Date
    
    /// 总活跃时长（秒）
    var totalActiveTime: Int
    
    /// 完成的休息次数
    var completedBreaks: Int
    
    /// 跳过的休息次数
    var skippedBreaks: Int
    
    init(
        date: Date = Date(),
        totalActiveTime: Int = 0,
        completedBreaks: Int = 0,
        skippedBreaks: Int = 0
    ) {
        self.date = date
        self.totalActiveTime = totalActiveTime
        self.completedBreaks = completedBreaks
        self.skippedBreaks = skippedBreaks
        self.dateKey = Self.dateKeyFormatter.string(from: date)
    }
    
    /// 日期格式化器
    private static let dateKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// 总休息次数
    var totalBreaks: Int {
        completedBreaks + skippedBreaks
    }
    
    /// 完成率（0-1）
    var completionRate: Double {
        guard totalBreaks > 0 else { return 0 }
        return Double(completedBreaks) / Double(totalBreaks)
    }
    
    /// 格式化的活跃时长
    var formattedActiveTime: String {
        let hours = totalActiveTime / 3600
        let minutes = (totalActiveTime % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

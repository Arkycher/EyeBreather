import Foundation
import Combine

/// 每日休息统计
struct DailyBreakStatistics: Codable, Equatable {
    let date: String // yyyy-MM-dd 格式
    var completedBreaks: Int = 0
    var skippedBreaks: Int = 0
    var totalBreakSeconds: Int = 0
    
    /// 总休息次数
    var totalBreaks: Int { completedBreaks + skippedBreaks }
    
    /// 完成率
    var completionRate: Double {
        guard totalBreaks > 0 else { return 0 }
        return Double(completedBreaks) / Double(totalBreaks)
    }
}

/// 休息统计管理器
@MainActor
final class BreakStatisticsManager: ObservableObject {
    static let shared = BreakStatisticsManager()
    
    private static let storageKey = "com.eyebreather.statistics"
    
    @Published private(set) var todayStatistics: DailyBreakStatistics
    @Published private(set) var allStatistics: [DailyBreakStatistics]
    
    /// 渐进模式：连续跳过次数
    @Published private(set) var consecutiveSkips: Int
    
    private init() {
        let loadedStats = Self.loadAll()
        self.allStatistics = loadedStats
        self.todayStatistics = Self.loadToday(from: loadedStats)
        self.consecutiveSkips = UserDefaults.standard.integer(forKey: "consecutiveSkips")
    }
    
    // MARK: - Date Helper
    
    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    // MARK: - Load
    
    private static func loadAll() -> [DailyBreakStatistics] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let stats = try? JSONDecoder().decode([DailyBreakStatistics].self, from: data) else {
            return []
        }
        return stats
    }
    
    private static func loadToday(from all: [DailyBreakStatistics]) -> DailyBreakStatistics {
        if let today = all.first(where: { $0.date == todayKey }) {
            return today
        }
        return DailyBreakStatistics(date: todayKey)
    }
    
    // MARK: - Save
    
    private func save() {
        // 更新或添加今日统计
        if let index = allStatistics.firstIndex(where: { $0.date == todayStatistics.date }) {
            allStatistics[index] = todayStatistics
        } else {
            allStatistics.append(todayStatistics)
        }
        
        // 只保留最近 30 天
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let cutoffKey = formatter.string(from: thirtyDaysAgo)
        allStatistics = allStatistics.filter { $0.date >= cutoffKey }
        
        // 保存
        if let data = try? JSONEncoder().encode(allStatistics) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
        
        UserDefaults.standard.set(consecutiveSkips, forKey: "consecutiveSkips")
    }
    
    // MARK: - Record
    
    func recordBreakCompleted(durationSeconds: Int) {
        todayStatistics.completedBreaks += 1
        todayStatistics.totalBreakSeconds += durationSeconds
        consecutiveSkips = 0 // 重置连续跳过
        save()
    }
    
    func recordBreakSkipped() {
        todayStatistics.skippedBreaks += 1
        consecutiveSkips += 1
        save()
    }
    
    /// 渐进模式：是否应该强制休息
    var shouldForceBreak: Bool {
        let threshold = SettingsManager.shared.settings.progressiveForceThreshold
        return consecutiveSkips >= threshold
    }
    
    /// 重置连续跳过计数（用于新的一天）
    func resetConsecutiveSkipsIfNewDay() {
        let today = Self.todayKey
        if todayStatistics.date != today {
            consecutiveSkips = 0
            todayStatistics = DailyBreakStatistics(date: today)
            save()
        }
    }
}

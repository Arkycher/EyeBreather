import Foundation
import SwiftData
import Combine

/// 统计管理器
@MainActor
final class StatisticsManager: ObservableObject {
    static let shared = StatisticsManager()
    
    @Published var todayStats: DailyStatistics?
    @Published var weeklyStats: [DailyStatistics] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadTodayStats()
    }
    
    // MARK: - Data Loading
    
    func loadTodayStats() {
        let context = DataStoreManager.shared.mainContext
        let today = dateKey(for: Date())
        
        let descriptor = FetchDescriptor<DailyStatistics>(
            predicate: #Predicate { $0.dateKey == today }
        )
        
        do {
            let results = try context.fetch(descriptor)
            if let stats = results.first {
                todayStats = stats
            } else {
                // 创建今天的统计
                let newStats = DailyStatistics(date: Date())
                context.insert(newStats)
                try context.save()
                todayStats = newStats
            }
        } catch {
            print("加载今日统计失败: \(error)")
        }
    }
    
    func loadWeeklyStats() {
        let context = DataStoreManager.shared.mainContext
        let calendar = Calendar.current
        let today = Date()
        
        // 获取过去7天的日期键
        var dateKeys: [String] = []
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dateKeys.append(dateKey(for: date))
            }
        }
        
        let descriptor = FetchDescriptor<DailyStatistics>(
            predicate: #Predicate { dateKeys.contains($0.dateKey) },
            sortBy: [SortDescriptor(\.dateKey, order: .reverse)]
        )
        
        do {
            weeklyStats = try context.fetch(descriptor)
        } catch {
            print("加载周统计失败: \(error)")
        }
    }
    
    // MARK: - Recording
    
    func recordBreakCompleted() {
        guard let stats = todayStats else {
            loadTodayStats()
            return
        }
        
        stats.completedBreaks += 1
        saveContext()
    }
    
    func recordBreakSkipped() {
        guard let stats = todayStats else {
            loadTodayStats()
            return
        }
        
        stats.skippedBreaks += 1
        saveContext()
    }
    
    func addActiveTime(seconds: Int) {
        guard let stats = todayStats else {
            loadTodayStats()
            return
        }
        
        stats.totalActiveTime += seconds
        saveContext()
    }
    
    // MARK: - Export
    
    func exportToCSV() -> URL? {
        loadWeeklyStats()
        
        var csv = "日期,使用时长(分钟),完成休息,跳过休息,完成率\n"
        
        for stats in weeklyStats {
            let minutes = stats.totalActiveTime / 60
            let rate = stats.totalBreaks > 0 ? Double(stats.completedBreaks) / Double(stats.totalBreaks) * 100 : 0
            csv += "\(stats.dateKey),\(minutes),\(stats.completedBreaks),\(stats.skippedBreaks),\(String(format: "%.1f", rate))%\n"
        }
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("eyebreather-stats.csv")
        
        do {
            try csv.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("导出失败: \(error)")
            return nil
        }
    }
    
    // MARK: - Helpers
    
    private func dateKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func saveContext() {
        do {
            try DataStoreManager.shared.mainContext.save()
        } catch {
            print("保存统计失败: \(error)")
        }
    }
}

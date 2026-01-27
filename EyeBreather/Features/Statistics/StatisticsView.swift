import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// 统计视图
struct StatisticsView: View {
    @ObservedObject private var statsManager = StatisticsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // 今日概览
            todayOverviewCard
            
            // 本周趋势
            weeklyTrendCard
            
            // 导出按钮
            HStack {
                Spacer()
                Button("导出 CSV") {
                    exportData()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(width: 480, height: 420)
        .onAppear {
            statsManager.loadTodayStats()
            statsManager.loadWeeklyStats()
        }
    }
    
    // MARK: - Today Overview
    
    private var todayOverviewCard: some View {
        GroupBox("📊 今日概览") {
            HStack(spacing: 30) {
                statItem(
                    title: "使用时长",
                    value: statsManager.todayStats?.formattedActiveTime ?? "--",
                    icon: "clock"
                )
                
                Divider()
                    .frame(height: 50)
                
                statItem(
                    title: "完成休息",
                    value: "\(statsManager.todayStats?.completedBreaks ?? 0) 次",
                    icon: "checkmark.circle"
                )
                
                Divider()
                    .frame(height: 50)
                
                statItem(
                    title: "跳过休息",
                    value: "\(statsManager.todayStats?.skippedBreaks ?? 0) 次",
                    icon: "xmark.circle"
                )
                
                Divider()
                    .frame(height: 50)
                
                statItem(
                    title: "完成率",
                    value: completionRateText,
                    icon: "chart.pie"
                )
            }
            .padding()
        }
    }
    
    private var completionRateText: String {
        guard let stats = statsManager.todayStats else { return "--%"}
        return String(format: "%.0f%%", stats.completionRate * 100)
    }
    
    private func statItem(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
            
            Text(value)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Weekly Trend
    
    private var weeklyTrendCard: some View {
        GroupBox("📈 本周趋势") {
            if statsManager.weeklyStats.isEmpty {
                Text("暂无数据")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 150)
            } else {
                VStack(spacing: 0) {
                    // 表头
                    HStack {
                        Text("日期")
                            .frame(width: 100, alignment: .leading)
                        Text("使用时长")
                            .frame(width: 80)
                        Text("完成")
                            .frame(width: 50)
                        Text("跳过")
                            .frame(width: 50)
                        Text("完成率")
                            .frame(width: 70)
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    
                    Divider()
                    
                    // 数据行
                    ForEach(statsManager.weeklyStats, id: \.dateKey) { stats in
                        HStack {
                            Text(formatDateKey(stats.dateKey))
                                .frame(width: 100, alignment: .leading)
                            Text(stats.formattedActiveTime)
                                .frame(width: 80)
                            Text("\(stats.completedBreaks)")
                                .frame(width: 50)
                            Text("\(stats.skippedBreaks)")
                                .frame(width: 50)
                            Text(String(format: "%.0f%%", stats.completionRate * 100))
                                .frame(width: 70)
                        }
                        .font(.caption)
                        .padding(.vertical, 6)
                        
                        if stats.dateKey != statsManager.weeklyStats.last?.dateKey {
                            Divider()
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private func formatDateKey(_ dateKey: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateKey) else { return dateKey }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM-dd E"
        displayFormatter.locale = Locale(identifier: "zh_CN")
        
        return displayFormatter.string(from: date)
    }
    
    // MARK: - Export
    
    private func exportData() {
        guard let url = statsManager.exportToCSV() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.commaSeparatedText]
        savePanel.nameFieldStringValue = "eyebreather-stats.csv"
        
        if savePanel.runModal() == .OK, let saveURL = savePanel.url {
            do {
                try FileManager.default.copyItem(at: url, to: saveURL)
            } catch {
                print("保存文件失败: \(error)")
            }
        }
    }
}

#Preview {
    StatisticsView()
}

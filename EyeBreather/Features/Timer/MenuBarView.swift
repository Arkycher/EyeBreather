import SwiftUI

/// 菜单栏弹出视图
struct MenuBarView: View {
    @ObservedObject private var timerManager = TimerManager.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var appDetector = AppDetector.shared
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 12) {
            // 标题栏
            headerView
            
            Divider()
            
            // 计时器状态
            timerStatusView
            
            Divider()
            
            // 今日统计
            todayStatsView
            
            Divider()
            
            // 操作按钮
            actionButtonsView
            
            Divider()
            
            // 底部按钮
            footerView
        }
        .padding(.vertical, 12)
        .frame(width: 280)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Image(systemName: "eye")
                .font(.title2)
                .foregroundColor(.accentColor)
            Text("EyeBreather")
                .font(.headline)
            Spacer()
            
            // 状态指示
            statusIndicator
        }
        .padding(.horizontal)
    }
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        if appDetector.shouldPauseReminder {
            return .orange
        }
        switch timerManager.state {
        case .idle: return .gray
        case .working: return .green
        case .preBreak: return .yellow
        case .breaking: return .blue
        case .paused: return .orange
        }
    }
    
    private var statusText: String {
        if appDetector.shouldPauseReminder {
            return "已暂停"
        }
        switch timerManager.state {
        case .idle: return "未启动"
        case .working: return "工作中"
        case .preBreak: return "即将休息"
        case .breaking: return "休息中"
        case .paused: return "已暂停"
        }
    }
    
    // MARK: - Timer Status
    
    private var timerStatusView: some View {
        VStack(spacing: 8) {
            // 下次休息时间
            HStack {
                Text("下次休息")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(nextBreakText)
                    .font(.subheadline.monospacedDigit())
                    .fontWeight(.medium)
            }
            
            // 进度条
            ProgressView(value: timerManager.workProgress)
                .progressViewStyle(.linear)
                .tint(progressColor)
        }
        .padding(.horizontal)
    }
    
    private var nextBreakText: String {
        if timerManager.state == .breaking {
            return "休息中..."
        }
        if timerManager.state == .paused || appDetector.shouldPauseReminder {
            return "已暂停"
        }
        
        let remaining = timerManager.remainingWorkTime
        let minutes = remaining / 60
        let seconds = remaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private var progressColor: Color {
        if timerManager.isInPreBreakWarning {
            return .orange
        }
        return .accentColor
    }
    
    // MARK: - Today Stats
    
    private var todayStatsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("📊 今日统计")
                .font(.subheadline.bold())
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("使用时长")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedActiveTime)
                        .font(.caption.monospacedDigit())
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("休息次数")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(completedBreaks)/\(totalBreaks)")
                        .font(.caption.monospacedDigit())
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("完成率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(completionRateText)
                        .font(.caption.monospacedDigit())
                }
            }
        }
        .padding(.horizontal)
    }
    
    // 这些属性后续会从 DailyStatistics 中获取，现在用占位值
    private var formattedActiveTime: String {
        // TODO: 从 DailyStatistics 获取
        "--:--"
    }
    
    private var completedBreaks: Int {
        // TODO: 从 DailyStatistics 获取
        0
    }
    
    private var totalBreaks: Int {
        // TODO: 从 DailyStatistics 获取
        0
    }
    
    private var completionRateText: String {
        // TODO: 从 DailyStatistics 获取
        "--%"
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // 暂停/继续按钮
            Button(action: togglePause) {
                HStack(spacing: 4) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                    Text(isPaused ? "继续" : "暂停")
                }
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            // 立即休息按钮
            Button(action: startBreakNow) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                    Text("立即休息")
                }
            }
            .buttonStyle(.bordered)
            .disabled(timerManager.state == .breaking)
        }
        .padding(.horizontal)
    }
    
    private var isPaused: Bool {
        timerManager.state == .paused
    }
    
    private func togglePause() {
        if timerManager.state == .paused {
            timerManager.resume()
        } else if timerManager.state == .working || timerManager.state == .preBreak {
            timerManager.pause()
        } else if timerManager.state == .idle {
            timerManager.start()
        }
    }
    
    private func startBreakNow() {
        timerManager.startBreak()
        BreakWindowController.shared.showOverlay()
    }
    
    // MARK: - Footer
    
    private var footerView: some View {
        HStack {
            Button("设置...") {
                openSettings()
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button("统计...") {
                openStatistics()
            }
            .buttonStyle(.borderless)
            
            Spacer()
            
            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal)
    }
    
    private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }
    
    private func openStatistics() {
        // TODO: 打开统计窗口
        NSApp.activate(ignoringOtherApps: true)
    }
}

#Preview {
    MenuBarView()
}

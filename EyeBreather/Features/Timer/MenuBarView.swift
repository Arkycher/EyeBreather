// EyeBreather/Features/Timer/MenuBarView.swift
import SwiftUI

/// 菜单栏弹出视图 - 圆环式设计
struct MenuBarView: View {
    @ObservedObject private var timerManager = TimerManager.shared
    @ObservedObject private var appDetector = AppDetector.shared
    @ObservedObject private var mediaMonitor = MediaDeviceMonitor.shared
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(spacing: 16) {
            // 圆环进度
            circularTimerView
            
            // 状态指示
            statusIndicatorView
            
            // 操作按钮
            actionButtonsView
            
            Divider()
                .padding(.horizontal)
            
            // 今日统计
            todayStatsView
            
            Divider()
                .padding(.horizontal)
            
            // 底部工具栏
            toolbarView
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(width: 260)
        .background(.regularMaterial)
    }
    
    // MARK: - Circular Timer
    
    private var circularTimerView: some View {
        CircularProgressView(
            progress: timerProgress,
            timeText: timerText,
            subtitle: timerSubtitle,
            color: statusColor,
            size: 120
        )
        .padding(.top, 8)
    }
    
    private var timerProgress: Double {
        switch timerManager.state {
        case .breaking:
            return timerManager.breakProgress
        default:
            return timerManager.workProgress
        }
    }
    
    private var timerText: String {
        if appDetector.shouldPauseReminder {
            return "--:--"
        }
        
        switch timerManager.state {
        case .breaking:
            let remaining = timerManager.remainingBreakTime
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        default:
            let remaining = timerManager.remainingWorkTime
            return String(format: "%d:%02d", remaining / 60, remaining % 60)
        }
    }
    
    private var timerSubtitle: String {
        switch timerManager.state {
        case .breaking:
            return "休息中"
        case .idle:
            return "未启动"
        default:
            return "下次休息"
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicatorView: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.subheadline)
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
        if case .meeting = appDetector.pauseReason {
            return "会议中"
        }
        if case .focusApp(let name) = appDetector.pauseReason {
            return "专注模式 · \(name)"
        }
        switch timerManager.state {
        case .idle: return "未启动"
        case .working: return "工作中"
        case .preBreak: return "即将休息"
        case .breaking: return "休息中"
        case .paused: return "已暂停"
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            // 暂停/继续按钮
            Button(action: togglePause) {
                HStack(spacing: 4) {
                    Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        .font(.caption)
                    Text(isPaused ? "继续" : "暂停")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            
            // 立即休息按钮
            Button(action: startBreakNow) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.slash.fill")
                        .font(.caption)
                    Text("立即休息")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)
            .disabled(timerManager.state == .breaking)
        }
        .padding(.horizontal, 4)
    }
    
    private var isPaused: Bool {
        timerManager.state == .paused || timerManager.state == .idle
    }
    
    private func togglePause() {
        switch timerManager.state {
        case .paused:
            timerManager.resume()
        case .idle:
            timerManager.start()
        case .working, .preBreak:
            timerManager.pause()
        default:
            break
        }
    }
    
    private func startBreakNow() {
        timerManager.startBreak()
        BreakWindowController.shared.showOverlay()
    }
    
    // MARK: - Today Stats
    
    private var todayStatsView: some View {
        HStack {
            Label {
                Text("--:--")
                    .font(.subheadline.monospacedDigit())
            } icon: {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("·")
                .foregroundColor(.secondary)
            
            Spacer()
            
            Label {
                Text("休息 0/0")
                    .font(.subheadline.monospacedDigit())
            } icon: {
                Image(systemName: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
    }
    
    // MARK: - Toolbar
    
    private var toolbarView: some View {
        HStack(spacing: 0) {
            Button(action: openSettings) {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Button(action: openStatistics) {
                Image(systemName: "chart.bar")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
            
            Button(action: quitApp) {
                Image(systemName: "xmark.circle")
                    .font(.title3)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func openSettings() {
        SettingsWindowController.shared.showSettings()
    }
    
    private func openStatistics() {
        StatisticsWindowController.shared.showStatistics()
    }
    
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

#Preview {
    MenuBarView()
}

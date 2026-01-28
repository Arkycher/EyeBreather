import Foundation
import AppKit
import UserNotifications
import Combine

/// 休息协调器
/// 负责监听计时器事件并协调休息流程
@MainActor
final class BreakCoordinator {
    /// 共享实例
    static let shared = BreakCoordinator()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 温和模式自动开始休息的定时器
    private var autoBreakTimer: Timer?
    
    /// 温和模式等待时间（秒）- 发送通知后多久自动开始休息
    private let gentleModeWaitSeconds: TimeInterval = 30
    
    /// 是否已经触发过休息（防止重复触发）
    private var breakTriggered = false
    
    private init() {
        setupObservers()
        requestNotificationPermission()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听休息预警
        NotificationCenter.default.publisher(for: .preBreakWarning)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handlePreBreakWarning()
            }
            .store(in: &cancellables)
        
        // 监听休息时间到达
        NotificationCenter.default.publisher(for: .breakTimeReached)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleBreakTimeReached()
            }
            .store(in: &cancellables)
        
        // 监听休息完成
        NotificationCenter.default.publisher(for: .breakCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleBreakCompleted()
            }
            .store(in: &cancellables)
        
        // 监听是否应该暂停提醒
        NotificationCenter.default.publisher(for: .shouldPauseReminder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShouldPause()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: .shouldResumeReminder)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.handleShouldResume()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Notification Permission
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("通知权限请求失败: \(error)")
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handlePreBreakWarning() {
        // 检查是否应该暂停
        guard !AppDetector.shared.shouldPauseReminder else { return }
        
        // 发送系统通知
        sendNotification(
            title: "即将休息",
            body: "还有 \(SettingsManager.shared.settings.preBreakWarning) 秒就要休息了"
        )
    }
    
    private func handleBreakTimeReached() {
        // 检查勿扰时段
        guard !DoNotDisturbManager.shared.isInDoNotDisturbPeriod else { return }
        
        // 检查是否应该暂停
        guard !AppDetector.shared.shouldPauseReminder else { return }
        
        // 防止重复触发
        guard !breakTriggered else { return }
        breakTriggered = true
        
        // 检查新的一天，重置统计
        BreakStatisticsManager.shared.resetConsecutiveSkipsIfNewDay()
        
        let settings = SettingsManager.shared.settings
        
        switch settings.reminderMode {
        case .forced:
            // 强制模式：直接显示遮罩
            startBreak()
            
        case .gentle:
            // 温和模式：发送通知，30秒后自动开始休息
            sendBreakNotification()
            scheduleAutoBreak()
            
        case .progressive:
            // 渐进模式：根据连续跳过次数决定
            if BreakStatisticsManager.shared.shouldForceBreak {
                // 跳过次数达到阈值，强制休息
                startBreak()
            } else {
                // 还可以跳过，发送通知
                sendBreakNotification()
                scheduleAutoBreak()
            }
        }
    }
    
    /// 安排自动开始休息（温和模式）
    private func scheduleAutoBreak() {
        cancelAutoBreak()
        
        autoBreakTimer = Timer.scheduledTimer(withTimeInterval: gentleModeWaitSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                // 如果还没有开始休息，自动开始
                if TimerManager.shared.state != .breaking {
                    self.startBreak()
                }
            }
        }
    }
    
    /// 取消自动休息定时器
    private func cancelAutoBreak() {
        autoBreakTimer?.invalidate()
        autoBreakTimer = nil
    }
    
    private func handleBreakCompleted() {
        breakTriggered = false
        BreakWindowController.shared.hideOverlay()
        TimerManager.shared.completeBreak()
        recordBreakCompleted()
        SoundManager.shared.playBreakEndSound()
        
        sendNotification(
            title: "休息完成",
            body: "休息完成，继续工作吧！"
        )
    }
    
    private func handleShouldPause() {
        // 全屏应用或白名单应用激活，暂停计时
        if TimerManager.shared.state == .working || TimerManager.shared.state == .preBreak {
            TimerManager.shared.pause()
        }
        
        // 如果正在显示休息遮罩，隐藏它
        if BreakWindowController.shared.isShowingOverlay {
            BreakWindowController.shared.hideOverlay()
        }
    }
    
    private func handleShouldResume() {
        // 恢复计时
        if TimerManager.shared.state == .paused {
            TimerManager.shared.resume()
        }
    }
    
    // MARK: - Break Actions
    
    func startBreak() {
        cancelAutoBreak()
        SoundManager.shared.playBreakStartSound()
        TimerManager.shared.startBreak()
        BreakWindowController.shared.showOverlay()
    }
    
    func skipBreak() {
        cancelAutoBreak()
        breakTriggered = false
        TimerManager.shared.skipBreak()
        BreakWindowController.shared.hideOverlay()
        recordBreakSkipped()
    }
    
    func delayBreak(minutes: Int) {
        cancelAutoBreak()
        breakTriggered = false
        TimerManager.shared.delayBreak(minutes: minutes)
        BreakWindowController.shared.hideOverlay()
    }
    
    // MARK: - Statistics Recording
    
    private func recordBreakCompleted() {
        let breakDuration = SettingsManager.shared.settings.breakDuration
        BreakStatisticsManager.shared.recordBreakCompleted(durationSeconds: breakDuration)
    }
    
    private func recordBreakSkipped() {
        BreakStatisticsManager.shared.recordBreakSkipped()
    }
    
    // MARK: - Notifications
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 立即发送
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func sendBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "休息时间到"
        content.body = "是时候让眼睛休息一下了"
        content.sound = .default
        content.categoryIdentifier = "BREAK_REMINDER"
        
        // 添加操作按钮
        let startAction = UNNotificationAction(
            identifier: "START_BREAK",
            title: "开始休息",
            options: .foreground
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_BREAK",
            title: "跳过",
            options: []
        )
        
        let delayAction = UNNotificationAction(
            identifier: "DELAY_5MIN",
            title: "5分钟后提醒",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "BREAK_REMINDER",
            actions: [startAction, skipAction, delayAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let request = UNNotificationRequest(
            identifier: "break-reminder",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

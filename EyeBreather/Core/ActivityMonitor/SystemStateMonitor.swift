import Foundation
import AppKit
import Combine

/// 系统状态监视器
/// 监听系统睡眠/唤醒事件
@MainActor
final class SystemStateMonitor: ObservableObject {
    /// 共享实例
    static let shared = SystemStateMonitor()
    
    // MARK: - Published Properties
    
    /// 系统是否处于睡眠状态
    @Published private(set) var isSystemSleeping: Bool = false
    
    /// 上次睡眠时间
    @Published private(set) var lastSleepTime: Date?
    
    /// 上次唤醒时间
    @Published private(set) var lastWakeTime: Date?
    
    // MARK: - Private Properties
    
    private var sleepObserver: Any?
    private var wakeObserver: Any?
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
    }
    
    deinit {
        // 在 deinit 中直接清理资源（不调用 @MainActor 方法）
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听系统即将睡眠
        sleepObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemWillSleep()
            }
        }
        
        // 监听系统唤醒
        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleSystemDidWake()
            }
        }
    }
    
    private func removeObservers() {
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleSystemWillSleep() {
        isSystemSleeping = true
        lastSleepTime = Date()
        
        // 暂停计时器
        TimerManager.shared.pause()
        
        // 停止活动监听
        ActivityMonitor.shared.stopMonitoring()
        
        // 隐藏休息遮罩（如果正在显示）
        if BreakWindowController.shared.isShowingOverlay {
            BreakWindowController.shared.hideOverlay()
        }
        
        NotificationCenter.default.post(name: .systemWillSleep, object: nil)
    }
    
    private func handleSystemDidWake() {
        isSystemSleeping = false
        lastWakeTime = Date()
        
        // 计算睡眠时长
        let sleepDuration = calculateSleepDuration()
        
        // 获取空闲重置阈值（秒）
        let idleThreshold = SettingsManager.shared.settings.idleResetThreshold * 60
        
        if sleepDuration >= idleThreshold {
            // 睡眠时间超过阈值，重置工作周期
            TimerManager.shared.resetWorkCycle()
        } else {
            // 睡眠时间较短，继续计时
            TimerManager.shared.resume()
        }
        
        // 重新启动活动监听
        ActivityMonitor.shared.startMonitoring()
        
        NotificationCenter.default.post(name: .systemDidWake, object: nil, userInfo: [
            "sleepDuration": sleepDuration
        ])
    }
    
    // MARK: - Helper Methods
    
    private func calculateSleepDuration() -> Int {
        guard let sleepTime = lastSleepTime else { return 0 }
        return Int(Date().timeIntervalSince(sleepTime))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let systemWillSleep = Notification.Name("com.eyebreather.systemWillSleep")
    static let systemDidWake = Notification.Name("com.eyebreather.systemDidWake")
}

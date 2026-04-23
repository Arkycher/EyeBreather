import Foundation
import AppKit
import Combine
import OSLog

/// 系统状态监视器
/// 监听系统睡眠/唤醒事件
@MainActor
final class SystemStateMonitor: ObservableObject {
    /// 共享实例
    static let shared = SystemStateMonitor()

    private let logger = Logger(subsystem: "com.eyebreather.app", category: "SystemStateMonitor")
    
    // MARK: - Published Properties
    
    /// 系统是否处于睡眠状态
    @Published private(set) var isSystemSleeping: Bool = false

    /// 屏幕是否处于锁定状态
    @Published private(set) var isScreenLocked: Bool = false

    /// 是否处于任何系统挂起态（锁屏或睡眠）
    var isSuspended: Bool {
        isSystemSleeping || isScreenLocked
    }
    
    /// 上次睡眠时间
    @Published private(set) var lastSleepTime: Date?
    
    /// 上次唤醒时间
    @Published private(set) var lastWakeTime: Date?
    
    // MARK: - Private Properties
    
    private var sleepObserver: Any?
    private var wakeObserver: Any?
    private var lockObserver: Any?
    private var unlockObserver: Any?
    private var workspaceObservers: [Any] = []
    
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
        for observer in workspaceObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
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

        lockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenLocked()
            }
        }

        unlockObserver = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenUnlocked()
            }
        }

        if let lockObserver {
            workspaceObservers.append(lockObserver)
        }
        if let unlockObserver {
            workspaceObservers.append(unlockObserver)
        }
    }
    
    private func removeObservers() {
        if let observer = sleepObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        for observer in workspaceObservers {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        workspaceObservers.removeAll()
    }
    
    // MARK: - Event Handlers
    
    private func handleSystemWillSleep() {
        logger.debug("system will sleep")
        isSystemSleeping = true
        enterSuspendedState()
        NotificationCenter.default.post(name: .systemWillSleep, object: nil)
    }
    
    private func handleSystemDidWake() {
        logger.debug("system did wake")
        isSystemSleeping = false
        resumeFromSuspendedStateIfNeeded()
        NotificationCenter.default.post(name: .systemDidWake, object: nil, userInfo: [
            "sleepDuration": calculateSleepDuration()
        ])
    }

    private func handleScreenLocked() {
        guard !isScreenLocked else { return }
        logger.debug("screen locked")
        isScreenLocked = true
        enterSuspendedState()
        NotificationCenter.default.post(name: .systemWillSleep, object: nil)
    }

    private func handleScreenUnlocked() {
        guard isScreenLocked else { return }
        logger.debug("screen unlocked")
        isScreenLocked = false
        resumeFromSuspendedStateIfNeeded()
        NotificationCenter.default.post(name: .systemDidWake, object: nil, userInfo: [
            "sleepDuration": calculateSleepDuration()
        ])
    }
    
    // MARK: - Helper Methods
    
    private func calculateSleepDuration() -> Int {
        guard let sleepTime = lastSleepTime else { return 0 }
        return Int(Date().timeIntervalSince(sleepTime))
    }

    private func enterSuspendedState() {
        if lastSleepTime == nil {
            lastSleepTime = Date()
        }

        logger.debug("enter suspended state: sleeping=\(self.isSystemSleeping, privacy: .public) locked=\(self.isScreenLocked, privacy: .public) timerState=\(TimerManager.shared.state.rawValue, privacy: .public)")

        BreakCoordinator.shared.suspendPendingBreak()
        TimerManager.shared.pause()
        ActivityMonitor.shared.stopMonitoring()

        if BreakWindowController.shared.isShowingOverlay {
            BreakWindowController.shared.hideOverlay()
        }
    }

    private func resumeFromSuspendedStateIfNeeded() {
        guard !isSystemSleeping && !isScreenLocked else { return }

        logger.debug("resume from suspended state")

        lastWakeTime = Date()

        let sleepDuration = calculateSleepDuration()
        let idleThreshold = SettingsManager.shared.settings.idleResetThreshold * 60

        if sleepDuration >= idleThreshold {
            TimerManager.shared.resetWorkCycle()
        } else {
            TimerManager.shared.resume()

            if TimerManager.shared.state == .breaking {
                BreakWindowController.shared.showOverlay()
            } else if TimerManager.shared.state == .preBreak {
                NotificationCenter.default.post(name: .breakTimeReached, object: nil)
            }
        }

        ActivityMonitor.shared.startMonitoring()
        lastSleepTime = nil
    }
}

#if DEBUG
extension SystemStateMonitor {
    func debugSimulateScreenLock() {
        handleScreenLocked()
    }

    func debugSimulateScreenUnlock() {
        handleScreenUnlocked()
    }

    func debugSimulateSystemWillSleep() {
        handleSystemWillSleep()
    }

    func debugSimulateSystemDidWake() {
        handleSystemDidWake()
    }

    func debugResetState() {
        isSystemSleeping = false
        isScreenLocked = false
        lastSleepTime = nil
        lastWakeTime = nil
    }
}
#endif

// MARK: - Notification Names

extension Notification.Name {
    static let systemWillSleep = Notification.Name("com.eyebreather.systemWillSleep")
    static let systemDidWake = Notification.Name("com.eyebreather.systemDidWake")
}

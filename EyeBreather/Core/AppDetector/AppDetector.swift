import Foundation
import AppKit
import Combine

// MARK: - PauseReason

/// 暂停原因枚举
enum PauseReason: Equatable {
    case none
    case focusApp(String)  // 应用名称
    case meeting
}

// MARK: - AppDetector

/// 应用检测器
/// 检测专注模式应用和会议状态
@MainActor
final class AppDetector: ObservableObject {
    /// 共享实例
    static let shared = AppDetector()
    
    // MARK: - Published Properties
    
    /// 当前前台应用 Bundle ID
    @Published private(set) var frontmostAppBundleId: String?
    
    /// 暂停原因
    @Published private(set) var pauseReason: PauseReason = .none
    
    /// 是否应该暂停提醒
    var shouldPauseReminder: Bool {
        pauseReason != .none
    }
    
    // MARK: - Private Properties
    
    private var appObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        observeSettingsChanges()
        observeMeetingStatusChanges()
        updateFrontmostApp()
    }
    
    deinit {
        // 在 deinit 中直接清理资源（不调用 @MainActor 方法）
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // 监听应用激活事件
        appObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.handleAppActivation(notification)
            }
        }
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePauseStatus()
            }
            .store(in: &cancellables)
    }
    
    private func observeMeetingStatusChanges() {
        NotificationCenter.default.publisher(for: .meetingStatusChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePauseStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Event Handlers
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        frontmostAppBundleId = app.bundleIdentifier
        updatePauseStatus()
    }
    
    private func updateFrontmostApp() {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        frontmostAppBundleId = frontApp.bundleIdentifier
        updatePauseStatus()
    }
    
    // MARK: - Pause Status
    
    private func updatePauseStatus() {
        let settings = SettingsManager.shared.settings
        
        var newReason: PauseReason = .none
        let previousReason = pauseReason
        
        // 优先检查会议状态
        if settings.enableMeetingDetection && MediaDeviceMonitor.shared.isInMeeting {
            newReason = .meeting
        }
        // 然后检查专注模式应用
        else if let bundleId = frontmostAppBundleId,
                let focusApp = settings.focusApps.first(where: { $0.bundleId == bundleId }) {
            newReason = .focusApp(focusApp.name)
        }
        
        pauseReason = newReason
        
        // 发送通知
        let wasActive = previousReason != .none
        let isActive = newReason != .none
        
        if isActive != wasActive {
            if isActive {
                NotificationCenter.default.post(name: .shouldPauseReminder, object: nil)
            } else {
                NotificationCenter.default.post(name: .shouldResumeReminder, object: nil)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 检查指定 Bundle ID 是否在专注模式应用列表中
    func isInFocusApps(_ bundleId: String) -> Bool {
        SettingsManager.shared.settings.focusApps.contains(where: { $0.bundleId == bundleId })
    }
    
    /// 添加应用到专注模式列表
    func addToFocusList(bundleId: String, name: String) {
        var settings = SettingsManager.shared.settings
        let newApp = FocusApp(bundleId: bundleId, name: name, isPreset: false)
        if !settings.focusApps.contains(where: { $0.bundleId == bundleId }) {
            settings.focusApps.append(newApp)
            SettingsManager.shared.settings = settings
        }
    }
    
    /// 从专注模式列表移除应用
    func removeFromFocusList(bundleId: String) {
        var settings = SettingsManager.shared.settings
        settings.focusApps.removeAll { $0.bundleId == bundleId }
        SettingsManager.shared.settings = settings
    }
    
    /// 获取所有正在运行的应用（用于白名单选择）
    func getRunningApps() -> [(bundleId: String, name: String)] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app -> (String, String)? in
                guard let bundleId = app.bundleIdentifier,
                      let name = app.localizedName else { return nil }
                return (bundleId, name)
            }
            .sorted { $0.1 < $1.1 }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let shouldPauseReminder = Notification.Name("com.eyebreather.shouldPauseReminder")
    static let shouldResumeReminder = Notification.Name("com.eyebreather.shouldResumeReminder")
}

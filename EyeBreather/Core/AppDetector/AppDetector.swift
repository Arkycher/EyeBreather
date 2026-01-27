import Foundation
import AppKit
import Combine

/// 应用检测器
/// 检测全屏应用和白名单应用
@MainActor
final class AppDetector: ObservableObject {
    /// 共享实例
    static let shared = AppDetector()
    
    // MARK: - Published Properties
    
    /// 当前前台应用 Bundle ID
    @Published private(set) var frontmostAppBundleId: String?
    
    /// 是否有全屏应用正在运行
    @Published private(set) var isFullscreenAppActive: Bool = false
    
    /// 是否应该暂停提醒（全屏或白名单应用）
    @Published private(set) var shouldPauseReminder: Bool = false
    
    // MARK: - Private Properties
    
    private var appObserver: Any?
    private var checkTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupObservers()
        observeSettingsChanges()
    }
    
    deinit {
        // 在 deinit 中直接清理资源（不调用 @MainActor 方法）
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        checkTimer?.invalidate()
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
        
        // 定期检查全屏状态（因为应用可能在激活后才进入全屏）
        checkTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkFullscreenStatus()
            }
        }
        
        // 初始检查
        checkFullscreenStatus()
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePauseStatus()
            }
            .store(in: &cancellables)
    }
    
    private func stopMonitoring() {
        if let observer = appObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Event Handlers
    
    private func handleAppActivation(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        
        frontmostAppBundleId = app.bundleIdentifier
        checkFullscreenStatus()
    }
    
    // MARK: - Fullscreen Detection
    
    private func checkFullscreenStatus() {
        // 获取当前前台应用
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            isFullscreenAppActive = false
            updatePauseStatus()
            return
        }
        
        frontmostAppBundleId = frontApp.bundleIdentifier
        
        // 检查是否全屏
        isFullscreenAppActive = isAppInFullscreen(frontApp)
        
        updatePauseStatus()
    }
    
    private func isAppInFullscreen(_ app: NSRunningApplication) -> Bool {
        // 检查是否有窗口处于 macOS 原生全屏模式
        // 通过检查窗口层级来判断（全屏窗口的 layer 值较高）
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] else {
            return false
        }
        
        let appPID = app.processIdentifier
        
        for windowInfo in windowList {
            guard let windowPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  windowPID == appPID,
                  let windowLayer = windowInfo[kCGWindowLayer as String] as? Int else {
                continue
            }
            
            // macOS 全屏窗口的 layer 通常是 0，但需要结合其他条件
            // 检查窗口是否在独立的 Space 中（全屏模式的特征）
            if let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
               let x = bounds["X"] as? CGFloat,
               let y = bounds["Y"] as? CGFloat,
               let width = bounds["Width"] as? CGFloat,
               let height = bounds["Height"] as? CGFloat {
                
                // 全屏窗口的特征：x=0, y=0，且覆盖整个屏幕
                // 只有当窗口从左上角(0,0)开始才认为是全屏
                for screen in NSScreen.screens {
                    let screenFrame = screen.frame
                    // 真正的全屏：从屏幕原点开始，且覆盖包含菜单栏的区域
                    let isFullscreen = x == 0 && 
                                       y <= 0 && 
                                       width >= screenFrame.width && 
                                       height >= screenFrame.height + abs(y)
                    if isFullscreen && windowLayer == 0 {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    // MARK: - Pause Status
    
    private func updatePauseStatus() {
        let settings = SettingsManager.shared.settings
        
        var shouldPause = false
        
        // 检查全屏暂停
        if settings.enableFullscreenPause && isFullscreenAppActive {
            shouldPause = true
        }
        
        // 检查白名单应用
        if let bundleId = frontmostAppBundleId,
           settings.whitelistApps.contains(bundleId) {
            shouldPause = true
        }
        
        let wasShowingPause = shouldPauseReminder
        shouldPauseReminder = shouldPause
        
        // 发送通知
        if shouldPause != wasShowingPause {
            if shouldPause {
                NotificationCenter.default.post(name: .shouldPauseReminder, object: nil)
            } else {
                NotificationCenter.default.post(name: .shouldResumeReminder, object: nil)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// 检查指定 Bundle ID 是否在白名单中
    func isInWhitelist(_ bundleId: String) -> Bool {
        SettingsManager.shared.settings.whitelistApps.contains(bundleId)
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

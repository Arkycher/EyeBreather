import AppKit
import SwiftUI
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    /// 菜单栏状态项
    private var statusItem: NSStatusItem?
    
    /// 弹出窗口
    private var popover: NSPopover?
    
    /// 事件监听器（点击其他区域关闭 popover）
    private var eventMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupEventMonitor()
        setupNotificationDelegate()
        
        // 隐藏 Dock 图标（根据设置）
        let settings = AppSettings.load()
        updateDockIconVisibility(show: settings.showInDock)
        
        // 初始化外观管理器
        _ = AppearanceManager.shared
        
        // 初始化开机自启管理器
        _ = LaunchAtLoginManager.shared
        
        // 初始化系统状态监视器
        _ = SystemStateMonitor.shared
        
        // 初始化活动监视器
        ActivityMonitor.shared.startMonitoring()
        
        // 启动计时器
        TimerManager.shared.start()
        
        // 初始化休息协调器
        _ = BreakCoordinator.shared
        
        // 初始化应用检测器
        _ = AppDetector.shared
    }
    
    private func setupNotificationDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // 应用在前台时也显示通知
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            handleNotificationResponse(response)
        }
        completionHandler()
    }
    
    @MainActor
    private func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "START_BREAK":
            BreakCoordinator.shared.startBreak()
            
        case "SKIP_BREAK":
            BreakCoordinator.shared.skipBreak()
            
        case "DELAY_5MIN":
            BreakCoordinator.shared.delayBreak(minutes: 5)
            
        case UNNotificationDefaultActionIdentifier:
            // 用户点击通知本身（而非按钮）
            BreakCoordinator.shared.startBreak()
            
        default:
            break
        }
    }
    
    // MARK: - Menu Bar Setup
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "eye", accessibilityDescription: "EyeBreather")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .modelContainer(DataStoreManager.shared.container)
        )
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
    
    // MARK: - Event Monitor
    
    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if self?.popover?.isShown == true {
                self?.popover?.performClose(nil)
            }
        }
    }
    
    // MARK: - Dock Icon
    
    func updateDockIconVisibility(show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
    
    // MARK: - Cleanup
    
    func applicationWillTerminate(_ notification: Notification) {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
        }
    }
}

import AppKit
import SwiftUI
import SwiftData
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func applicationDidFinishLaunching(_ notification: Notification) {
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
        
        // 初始化媒体设备监视器
        _ = MediaDeviceMonitor.shared
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
    
    // MARK: - Dock Icon
    
    func updateDockIconVisibility(show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

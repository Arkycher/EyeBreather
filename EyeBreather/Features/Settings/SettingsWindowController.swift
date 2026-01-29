import AppKit
import SwiftUI
import SwiftData

/// 设置窗口控制器
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    private var appearanceObserver: NSObjectProtocol?
    
    private init() {}
    
    func showSettings() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
            .modelContainer(DataStoreManager.shared.container)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 520),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "EyeBreather"
        window.titlebarAppearsTransparent = true
        // 使用系统窗口背景色，自动适配暗黑模式
        window.backgroundColor = NSColor.windowBackgroundColor
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        
        // 监听系统外观变化，更新窗口背景色
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateWindowAppearance()
        }
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /// 更新窗口外观以匹配系统设置
    private func updateWindowAppearance() {
        window?.backgroundColor = NSColor.windowBackgroundColor
    }
    
    func closeSettings() {
        window?.close()
    }
}

import AppKit
import SwiftUI

/// 设置窗口控制器
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()
    
    private var window: NSWindow?
    
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
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "EyeBreather 设置"
        window.contentView = NSHostingView(rootView: settingsView)
        window.center()
        window.isReleasedWhenClosed = false
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func closeSettings() {
        window?.close()
    }
}

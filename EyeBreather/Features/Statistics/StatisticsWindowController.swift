import AppKit
import SwiftUI
import SwiftData

/// 统计窗口控制器
@MainActor
final class StatisticsWindowController {
    static let shared = StatisticsWindowController()
    
    private var window: NSWindow?
    
    private init() {}
    
    func showStatistics() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let statisticsView = StatisticsView()
            .modelContainer(DataStoreManager.shared.container)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "EyeBreather 统计"
        window.contentView = NSHostingView(rootView: statisticsView)
        window.center()
        window.isReleasedWhenClosed = false
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

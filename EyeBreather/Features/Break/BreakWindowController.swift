import AppKit
import SwiftUI
import Combine

/// 休息遮罩窗口控制器
@MainActor
final class BreakWindowController: ObservableObject {
    /// 共享实例
    static let shared = BreakWindowController()
    
    /// 当前显示的遮罩窗口（每个屏幕一个）
    private var overlayWindows: [NSScreen: NSWindow] = [:]
    
    /// 是否正在显示遮罩
    @Published private(set) var isShowingOverlay: Bool = false
    
    /// 屏幕变化监听器
    private var screenObserver: Any?
    
    private init() {
        setupScreenObserver()
    }
    
    deinit {
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Screen Observer
    
    private func setupScreenObserver() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenChange()
            }
        }
    }
    
    private func handleScreenChange() {
        guard isShowingOverlay else { return }
        
        // 获取当前所有屏幕
        let currentScreens = Set(NSScreen.screens)
        let existingScreens = Set(overlayWindows.keys)
        
        // 移除不存在的屏幕的窗口
        for screen in existingScreens {
            if !currentScreens.contains(screen) {
                overlayWindows[screen]?.close()
                overlayWindows.removeValue(forKey: screen)
            }
        }
        
        // 为新屏幕创建窗口
        for screen in currentScreens {
            if overlayWindows[screen] == nil {
                let window = createOverlayWindow(for: screen)
                overlayWindows[screen] = window
                window.orderFrontRegardless()
            }
        }
        
        // 更新现有窗口的位置和大小
        for (screen, window) in overlayWindows {
            window.setFrame(screen.frame, display: true)
        }
    }
    
    // MARK: - Public Methods
    
    /// 显示休息遮罩
    func showOverlay() {
        guard !isShowingOverlay else { return }
        
        isShowingOverlay = true
        
        // 为每个屏幕创建遮罩窗口
        for screen in NSScreen.screens {
            let window = createOverlayWindow(for: screen)
            overlayWindows[screen] = window
            window.orderFrontRegardless()
        }
    }
    
    /// 隐藏休息遮罩
    func hideOverlay() {
        guard isShowingOverlay else { return }
        
        isShowingOverlay = false
        
        // 关闭所有遮罩窗口
        for window in overlayWindows.values {
            window.close()
        }
        overlayWindows.removeAll()
    }
    
    // MARK: - Private Methods
    
    private func createOverlayWindow(for screen: NSScreen) -> NSWindow {
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // 窗口配置
        window.level = .screenSaver // 高于其他窗口
        window.isOpaque = false
        window.backgroundColor = .clear
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        
        // 设置内容视图 - 确保填满整个窗口
        let breakView = BreakOverlayView()
        let hostingView = NSHostingView(rootView: breakView)
        hostingView.frame = NSRect(origin: .zero, size: screen.frame.size)
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        
        // 确保窗口位置正确
        window.setFrame(screen.frame, display: true)
        
        return window
    }
}

import Foundation
import AppKit
import Combine

/// 用户活动监视器
/// 监听鼠标和键盘事件，判断用户是否活跃
@MainActor
final class ActivityMonitor: ObservableObject {
    /// 共享实例
    static let shared = ActivityMonitor()
    
    // MARK: - Published Properties
    
    /// 是否正在监听
    @Published private(set) var isMonitoring: Bool = false
    
    /// 上次活动时间
    @Published private(set) var lastActivityTime: Date = Date()
    
    /// 当前是否空闲
    @Published private(set) var isIdle: Bool = false
    
    // MARK: - Private Properties
    
    private var eventMonitor: Any?
    private var idleCheckTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        observeSettingsChanges()
    }
    
    deinit {
        // 在 deinit 中清理资源（不调用 @MainActor 方法）
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        idleCheckTimer?.invalidate()
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // 设置变更时可能需要更新监听状态
                guard let self = self else { return }
                if self.isMonitoring {
                    // 重新启动以应用新设置
                    self.stopMonitoring()
                    self.startMonitoring()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 开始监听用户活动
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard SettingsManager.shared.settings.enableActivityDetection else { return }
        
        isMonitoring = true
        lastActivityTime = Date()
        isIdle = false
        
        // 监听全局鼠标和键盘事件
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel]
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordActivity()
            }
        }
        
        // 启动空闲检查定时器
        startIdleCheckTimer()
    }
    
    /// 停止监听
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
    }
    
    /// 记录活动
    func recordActivity() {
        let wasIdle = isIdle
        lastActivityTime = Date()
        isIdle = false
        
        // 通知 TimerManager
        TimerManager.shared.recordActivity()
        
        // 如果从空闲恢复，发送通知
        if wasIdle {
            NotificationCenter.default.post(name: .userBecameActive, object: nil)
        }
    }
    
    // MARK: - Private Methods
    
    private func startIdleCheckTimer() {
        idleCheckTimer?.invalidate()
        idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleStatus()
            }
        }
    }
    
    private func checkIdleStatus() {
        let idleThreshold = SettingsManager.shared.settings.idleResetThreshold * 60
        let idleTime = Int(Date().timeIntervalSince(lastActivityTime))
        
        let wasIdle = isIdle
        isIdle = idleTime >= idleThreshold
        
        if isIdle && !wasIdle {
            // 刚进入空闲状态
            NotificationCenter.default.post(name: .userBecameIdle, object: nil)
            
            // 通知 TimerManager 检查是否需要重置
            TimerManager.shared.checkIdleReset()
        }
    }
    
    /// 获取当前空闲时间（秒）
    var currentIdleTime: Int {
        Int(Date().timeIntervalSince(lastActivityTime))
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userBecameIdle = Notification.Name("com.eyebreather.userBecameIdle")
    static let userBecameActive = Notification.Name("com.eyebreather.userBecameActive")
}

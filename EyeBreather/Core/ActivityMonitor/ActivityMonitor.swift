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
    private var pendingActivityUpdate = false
    
    /// 鼠标移动事件节流：上次处理时间
    private var lastMouseMoveTime: Date = .distantPast
    /// 鼠标移动事件节流间隔（秒）
    /// 5 秒粒度足够判断“是否活跃”，可显著减少全局事件处理开销
    private let mouseMoveThrottleInterval: TimeInterval = 5.0
    
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
        // 性能优化：鼠标移动事件节流，其他事件直接处理
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown, .scrollWheel]
        ) { [weak self] event in
            guard let self = self else { return }
            
            // 鼠标移动事件节流：每 0.5 秒最多处理一次
            if event.type == .mouseMoved {
                let now = Date()
                // 同步检查节流（避免创建过多 Task）
                if now.timeIntervalSince(self.lastMouseMoveTime) < self.mouseMoveThrottleInterval {
                    return
                }
                self.lastMouseMoveTime = now
            }
            
            self.scheduleActivityUpdate()
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

    private func scheduleActivityUpdate() {
        guard !pendingActivityUpdate else { return }
        pendingActivityUpdate = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingActivityUpdate = false
            self.recordActivity()
        }
    }
    
    private func startIdleCheckTimer() {
        idleCheckTimer?.invalidate()
        // 性能优化：延长检查间隔到 30 秒，并设置 tolerance 允许系统合并唤醒
        let timer = Timer(timeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkIdleStatus()
            }
        }
        timer.tolerance = 5.0  // 允许 5 秒误差，让系统合并定时器唤醒
        RunLoop.main.add(timer, forMode: .common)
        idleCheckTimer = timer
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

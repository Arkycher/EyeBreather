import Foundation
import Combine

/// 计时器管理器
@MainActor
final class TimerManager: ObservableObject {
    /// 共享实例
    static let shared = TimerManager()
    
    // MARK: - Published Properties
    
    /// 当前状态
    @Published private(set) var state: TimerState = .idle
    
    /// 当前周期已工作时间（秒）
    @Published private(set) var elapsedWorkTime: Int = 0
    
    /// 当前休息已用时间（秒）
    @Published private(set) var elapsedBreakTime: Int = 0
    
    /// 上次活动时间
    @Published private(set) var lastActivityTime: Date = Date()
    
    // MARK: - Private Properties
    
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// 工作时长设置（秒）
    var workDurationSeconds: Int {
        SettingsManager.shared.settings.workDuration * 60
    }
    
    /// 休息时长设置（秒）
    var breakDurationSeconds: Int {
        SettingsManager.shared.settings.breakDuration
    }
    
    /// 预警时间设置（秒）
    var preBreakWarningSeconds: Int {
        SettingsManager.shared.settings.preBreakWarning
    }
    
    /// 工作进度（0-1）
    var workProgress: Double {
        guard workDurationSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedWorkTime) / Double(workDurationSeconds))
    }
    
    /// 休息进度（0-1）
    var breakProgress: Double {
        guard breakDurationSeconds > 0 else { return 0 }
        return min(1.0, Double(elapsedBreakTime) / Double(breakDurationSeconds))
    }
    
    /// 距离下次休息的剩余时间（秒）
    var remainingWorkTime: Int {
        max(0, workDurationSeconds - elapsedWorkTime)
    }
    
    /// 剩余休息时间（秒）
    var remainingBreakTime: Int {
        max(0, breakDurationSeconds - elapsedBreakTime)
    }
    
    /// 是否处于预警阶段
    var isInPreBreakWarning: Bool {
        remainingWorkTime <= preBreakWarningSeconds && remainingWorkTime > 0
    }
    
    // MARK: - Initialization
    
    private init() {
        observeSettingsChanges()
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // 设置变更时可能需要重新计算
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// 开始工作计时
    func start() {
        guard state == .idle || state == .paused else { return }
        
        state = .working
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 暂停计时
    func pause() {
        guard state == .working || state == .preBreak else { return }
        
        state = .paused
        stopTimer()
    }
    
    /// 继续计时
    func resume() {
        guard state == .paused else { return }
        
        state = .working
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 开始休息
    func startBreak() {
        state = .breaking
        elapsedBreakTime = 0
        stopTimer()
        startTimer()
    }
    
    /// 跳过休息
    func skipBreak() {
        resetWorkCycle()
    }
    
    /// 延迟休息
    func delayBreak(minutes: Int) {
        // 减少已工作时间，相当于延迟
        elapsedWorkTime = max(0, workDurationSeconds - minutes * 60)
        state = .working
    }
    
    /// 完成休息
    func completeBreak() {
        resetWorkCycle()
    }
    
    /// 重置工作周期
    func resetWorkCycle() {
        stopTimer()
        state = .working
        elapsedWorkTime = 0
        elapsedBreakTime = 0
        lastActivityTime = Date()
        startTimer()
    }
    
    /// 记录用户活动
    func recordActivity() {
        lastActivityTime = Date()
    }
    
    /// 检查空闲重置
    func checkIdleReset() {
        let idleThreshold = SettingsManager.shared.settings.idleResetThreshold * 60
        let idleTime = Int(Date().timeIntervalSince(lastActivityTime))
        
        if idleTime >= idleThreshold {
            resetWorkCycle()
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func tick() {
        switch state {
        case .working, .preBreak:
            elapsedWorkTime += 1
            
            // 检查是否进入预警
            if isInPreBreakWarning && state == .working {
                state = .preBreak
                NotificationCenter.default.post(name: .preBreakWarning, object: nil)
            }
            
            // 检查是否需要休息
            if elapsedWorkTime >= workDurationSeconds {
                NotificationCenter.default.post(name: .breakTimeReached, object: nil)
            }
            
        case .breaking:
            elapsedBreakTime += 1
            
            // 检查休息是否完成
            if elapsedBreakTime >= breakDurationSeconds {
                NotificationCenter.default.post(name: .breakCompleted, object: nil)
            }
            
        case .idle, .paused:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let preBreakWarning = Notification.Name("com.eyebreather.preBreakWarning")
    static let breakTimeReached = Notification.Name("com.eyebreather.breakTimeReached")
    static let breakCompleted = Notification.Name("com.eyebreather.breakCompleted")
}

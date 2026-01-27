import Foundation

/// 应用设置
struct AppSettings: Codable, Equatable {
    // MARK: - 休息规则
    
    /// 工作时长（分钟），默认 20
    var workDuration: Int = 20
    
    /// 休息时长（秒），默认 20
    var breakDuration: Int = 20
    
    /// 提醒模式
    var reminderMode: ReminderMode = .gentle
    
    /// 休息预警时间（秒），默认 60
    var preBreakWarning: Int = 60
    
    /// 延迟选项（分钟）
    var delayOptions: [Int] = [5, 15, 30]
    
    // MARK: - 智能检测
    
    /// 启用活动检测
    var enableActivityDetection: Bool = true
    
    /// 空闲重置阈值（分钟），默认 5
    var idleResetThreshold: Int = 5
    
    // MARK: - 智能暂停
    
    /// 启用会议检测（摄像头/麦克风）
    var enableMeetingDetection: Bool = true
    
    /// 专注模式应用列表
    var focusApps: [FocusApp] = FocusApp.presets
    
    /// 启用智能推荐
    var enableSmartRecommend: Bool = true
    
    // MARK: - 休息界面
    
    /// 休息界面样式
    var breakStyle: BreakStyle = .dark
    
    /// 自定义背景图片路径
    var customBackgroundPath: String? = nil
    
    // MARK: - 通用
    
    /// 开机自启
    var launchAtLogin: Bool = false
    
    /// 显示 Dock 图标
    var showInDock: Bool = false
    
    /// 外观模式
    var appearance: AppearanceMode = .system
    
    // MARK: - 默认值
    
    static let `default` = AppSettings()
}

// MARK: - UserDefaults 存储

extension AppSettings {
    private static let storageKey = "com.eyebreather.settings"
    
    /// 从 UserDefaults 加载设置
    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }
    
    /// 保存到 UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}

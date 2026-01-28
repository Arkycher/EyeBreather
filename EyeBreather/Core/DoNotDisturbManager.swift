import Foundation

/// 勿扰时段管理器
@MainActor
final class DoNotDisturbManager {
    static let shared = DoNotDisturbManager()
    
    private init() {}
    
    /// 检查当前是否在勿扰时段内
    var isInDoNotDisturbPeriod: Bool {
        let settings = SettingsManager.shared.settings
        guard settings.enableDoNotDisturb else { return false }
        
        let now = Calendar.current.component(.hour, from: Date())
        let start = settings.doNotDisturbStart
        let end = settings.doNotDisturbEnd
        
        // 处理跨午夜的情况
        if start <= end {
            // 例如：9:00 - 17:00（同一天内）
            return now >= start && now < end
        } else {
            // 例如：22:00 - 08:00（跨午夜）
            return now >= start || now < end
        }
    }
}

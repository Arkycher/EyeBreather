import Foundation
import Combine

/// 设置管理器（全局单例）
@MainActor
final class SettingsManager: ObservableObject {
    /// 共享实例
    static let shared = SettingsManager()
    
    /// 当前设置
    @Published var settings: AppSettings {
        didSet {
            settings.save()
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }
    
    private init() {
        self.settings = AppSettings.load()
    }
    
    /// 重置为默认设置
    func resetToDefaults() {
        settings = .default
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsDidChange = Notification.Name("com.eyebreather.settingsDidChange")
}

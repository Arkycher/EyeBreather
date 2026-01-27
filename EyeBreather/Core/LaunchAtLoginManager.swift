import Foundation
import ServiceManagement

/// 开机自启管理器
@MainActor
final class LaunchAtLoginManager: ObservableObject {
    static let shared = LaunchAtLoginManager()
    
    @Published var isEnabled: Bool = false
    
    private init() {
        updateStatus()
    }
    
    /// 更新当前状态
    func updateStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = SMAppService.mainApp.status == .enabled
        }
    }
    
    /// 设置开机自启
    func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
                isEnabled = enabled
            } catch {
                print("设置开机自启失败: \(error)")
            }
        }
    }
}

import AppKit
import Combine

/// 外观管理器
@MainActor
final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        applyCurrentAppearance()
        observeSettingsChanges()
    }
    
    private func observeSettingsChanges() {
        NotificationCenter.default.publisher(for: .settingsDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.applyCurrentAppearance()
            }
            .store(in: &cancellables)
    }
    
    func applyCurrentAppearance() {
        let mode = SettingsManager.shared.settings.appearance
        
        switch mode {
        case .system:
            NSApp.appearance = nil // 跟随系统
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}

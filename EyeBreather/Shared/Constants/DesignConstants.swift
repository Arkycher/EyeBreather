import SwiftUI
import AppKit

/// 设计系统常量
enum DesignConstants {
    // MARK: - Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 14
    }
    
    // MARK: - Font Sizes
    enum FontSize {
        static let caption: CGFloat = 11
        static let footnote: CGFloat = 13
        static let body: CGFloat = 14
        static let headline: CGFloat = 15
        static let title: CGFloat = 16
    }
    
    // MARK: - Sidebar (使用系统颜色适配暗黑模式)
    enum Sidebar {
        static let width: CGFloat = 160
        static let itemSpacing: CGFloat = 2
        // 使用系统颜色，自动适配暗黑模式
        static let backgroundColor = Color(nsColor: NSColor.windowBackgroundColor)
        static let selectedColor = Color(nsColor: NSColor.selectedContentBackgroundColor).opacity(0.3)
        static let hoverColor = Color(nsColor: NSColor.unemphasizedSelectedContentBackgroundColor).opacity(0.5)
    }
    
    // MARK: - Card
    enum Card {
        static let shadowOpacity: Double = 0.06
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 2
    }
    
    // MARK: - Settings Window
    enum SettingsWindow {
        static let width: CGFloat = 640
        static let height: CGFloat = 520
    }
}

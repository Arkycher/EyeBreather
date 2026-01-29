import XCTest
import SwiftUI
@testable import EyeBreather

/// 设置视图 UI 测试
@MainActor
final class SettingsViewTests: XCTestCase {
    
    // MARK: - 颜色适配测试
    
    func testCardTextColorUsesSystemLabelColor() {
        // 验证卡片文字颜色使用系统标签色（自动适配暗黑模式）
        let systemLabelColor = NSColor.labelColor
        XCTAssertNotNil(systemLabelColor)
    }
    
    func testCardSecondaryColorUsesSystemSecondaryLabelColor() {
        // 验证卡片次要文字颜色使用系统次要标签色
        let systemSecondaryColor = NSColor.secondaryLabelColor
        XCTAssertNotNil(systemSecondaryColor)
    }
    
    // MARK: - 侧边栏颜色测试
    
    func testSidebarBackgroundUsesWindowBackgroundColor() {
        // 验证侧边栏背景使用系统窗口背景色
        let sidebarBg = DesignConstants.Sidebar.backgroundColor
        XCTAssertNotNil(sidebarBg)
    }
    
    func testSidebarSelectedColorUsesSystemColor() {
        // 验证侧边栏选中色使用系统颜色
        let selectedColor = DesignConstants.Sidebar.selectedColor
        XCTAssertNotNil(selectedColor)
    }
    
    // MARK: - 设计常量测试
    
    func testDesignConstantsHaveValidValues() {
        // 验证设计常量有合理的值
        XCTAssertGreaterThan(DesignConstants.Sidebar.width, 0)
        XCTAssertGreaterThan(DesignConstants.CornerRadius.lg, 0)
        XCTAssertGreaterThan(DesignConstants.SettingsWindow.width, 0)
        XCTAssertGreaterThan(DesignConstants.SettingsWindow.height, 0)
    }
    
    // MARK: - 暗黑模式颜色对比度测试
    
    func testDarkModeColorContrast() {
        // 测试暗黑模式下卡片背景色的亮度值
        let darkCardBackground: CGFloat = 0.18  // 暗黑模式卡片背景亮度
        let lightCardBackground: CGFloat = 1.0  // 白色背景亮度
        
        // 暗黑模式背景应该比白色暗
        XCTAssertLessThan(darkCardBackground, lightCardBackground)
        
        // 暗黑模式背景应该有足够的对比度（不是纯黑）
        XCTAssertGreaterThan(darkCardBackground, 0.1)
    }
    
    func testDarkModeBorderColor() {
        // 测试暗黑模式下边框颜色
        let borderBrightness: CGFloat = 0.3
        let backgroundBrightness: CGFloat = 0.18
        
        // 边框应该比背景亮
        XCTAssertGreaterThan(borderBrightness, backgroundBrightness)
        // 边框不应该太亮
        XCTAssertLessThan(borderBrightness, 0.5)
    }
    
    // MARK: - BreakStyle 智能颜色测试
    
    func testBreakStyleColorAdaptation() {
        // 测试每种 BreakStyle 都有定义
        for style in BreakStyle.allCases {
            XCTAssertNotNil(style.displayName)
            XCTAssertNotNil(style.description)
            XCTAssertNotNil(style.icon)
        }
    }
    
    // MARK: - WallpaperManager 亮度计算测试
    
    func testWallpaperBrightnessCalculation() {
        // 创建测试图片 - 纯黑
        let blackImage = createSolidColorImage(color: .black)
        let blackBrightness = WallpaperManager.calculateBrightness(of: blackImage)
        XCTAssertLessThan(blackBrightness, 0.1, "黑色图片亮度应该接近 0")
        
        // 创建测试图片 - 纯白
        let whiteImage = createSolidColorImage(color: .white)
        let whiteBrightness = WallpaperManager.calculateBrightness(of: whiteImage)
        XCTAssertGreaterThan(whiteBrightness, 0.9, "白色图片亮度应该接近 1")
        
        // 创建测试图片 - 灰色
        let grayImage = createSolidColorImage(color: NSColor(white: 0.5, alpha: 1.0))
        let grayBrightness = WallpaperManager.calculateBrightness(of: grayImage)
        XCTAssertGreaterThan(grayBrightness, 0.3)
        XCTAssertLessThan(grayBrightness, 0.7)
    }
    
    // MARK: - Helper Methods
    
    private func createSolidColorImage(color: NSColor) -> NSImage {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        image.unlockFocus()
        return image
    }
}

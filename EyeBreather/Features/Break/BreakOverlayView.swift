import SwiftUI
import AppKit

/// 休息遮罩视图
struct BreakOverlayView: View {
    @ObservedObject private var timerManager = TimerManager.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var wallpaperManager = WallpaperManager.shared
    
    /// 自定义背景的亮度（缓存计算结果）
    @State private var customBackgroundBrightness: CGFloat = 0.3
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景 - 填充整个屏幕
                backgroundView
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                
                // 内容 - 居中显示
                VStack(spacing: 24) {
                    // 标题
                    Text("休息时间")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(textColor)
                        .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 1)
                    
                    // 倒计时
                    Text(formattedRemainingTime)
                        .font(.system(size: 120, weight: .thin, design: .rounded))
                        .foregroundStyle(textColor)
                        .monospacedDigit()
                        .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 2)
                    
                    // 提示文字
                    Text(tipsText)
                        .font(.title2)
                        .foregroundStyle(textColor.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .shadow(color: textShadowColor, radius: textShadowRadius, x: 0, y: 1)
                    
                    // 进度条
                    ProgressView(value: timerManager.breakProgress)
                        .progressViewStyle(.linear)
                        .frame(width: 300)
                        .tint(textColor)
                    
                    // 操作按钮（温和模式和渐进模式非强制状态显示）
                    if canSkipBreak {
                        HStack(spacing: 16) {
                            BreakActionButton(title: "跳过", style: buttonStyle) {
                                skipBreak()
                            }
                            
                            ForEach(settingsManager.settings.delayOptions, id: \.self) { minutes in
                                BreakActionButton(title: "延迟 \(minutes) 分钟", style: buttonStyle) {
                                    delayBreak(minutes: minutes)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch settingsManager.settings.breakStyle {
        case .blur:
            // 毛玻璃效果背景
            Color.clear
                .background(.ultraThinMaterial)
        case .liquidGlass:
            // 液态玻璃效果 - macOS 26 原生 API
            if #available(macOS 26, *) {
                // 原生液态玻璃效果 - 使用 .rect 填充全屏
                Color.clear
                    .glassEffect(in: .rect)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.purple.opacity(0.08),
                                Color.pink.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            } else {
                // 回退方案：渐变 + 毛玻璃
                ZStack {
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.15),
                            Color.purple.opacity(0.1),
                            Color.pink.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Color.clear
                        .background(.ultraThinMaterial)
                }
            }
        case .dark:
            Color.black.opacity(0.95)
        case .tips:
            Color.black.opacity(0.85)
        case .desktop:
            // 使用系统桌面壁纸 - 从 WallpaperManager 获取
            GeometryReader { geo in
                if let image = WallpaperManager.shared.wallpaperImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width + 120, height: geo.size.height + 120)
                        .offset(x: -60, y: -60)
                        .blur(radius: 30)
                        .overlay(Color.black.opacity(0.3))
                } else {
                    // 回退：深色渐变背景
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.2),
                            Color(red: 0.05, green: 0.05, blue: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            .clipped()
        case .custom:
            if let path = settingsManager.settings.customBackgroundPath,
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.3))
                    .onAppear {
                        // 分析自定义背景的亮度
                        customBackgroundBrightness = WallpaperManager.calculateBrightness(of: nsImage)
                    }
            } else {
                Color.black.opacity(0.9)
            }
        }
    }
    
    // MARK: - Tips Content
    
    private var tipsText: String {
        if settingsManager.settings.breakStyle == .tips {
            return settingsManager.settings.customTipsText
        }
        return "看向远处，放松眼睛"
    }
    
    // MARK: - Computed Properties
    
    /// 是否可以跳过休息
    private var canSkipBreak: Bool {
        switch settingsManager.settings.reminderMode {
        case .forced:
            // 强制模式不能跳过
            return false
        case .gentle:
            // 温和模式可以跳过
            return true
        case .progressive:
            // 渐进模式：未达到强制阈值时可以跳过
            return !BreakStatisticsManager.shared.shouldForceBreak
        }
    }
    
    private var formattedRemainingTime: String {
        let remaining = timerManager.remainingBreakTime
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "%d", seconds)
    }
    
    // MARK: - 智能颜色计算
    
    /// 当前背景是否偏亮
    private var isBackgroundBright: Bool {
        switch settingsManager.settings.breakStyle {
        case .blur, .liquidGlass:
            // 毛玻璃效果，取决于系统外观
            return false // 通常偏暗
        case .dark, .tips:
            // 深色背景
            return false
        case .desktop:
            // 使用壁纸管理器分析的亮度，考虑到有 0.3 的黑色遮罩
            // 遮罩后的亮度 = 原亮度 * 0.7
            return (wallpaperManager.wallpaperBrightness * 0.7) > 0.5
        case .custom:
            // 自定义背景，考虑到有 0.3 的黑色遮罩
            return (customBackgroundBrightness * 0.7) > 0.5
        }
    }
    
    /// 根据背景亮度确定文字颜色
    private var textColor: Color {
        isBackgroundBright ? .black : .white
    }
    
    /// 文字阴影颜色（与文字颜色相反，用于增加对比度）
    private var textShadowColor: Color {
        if isBackgroundBright {
            return Color.white.opacity(0.6)
        } else {
            return Color.black.opacity(0.4)
        }
    }
    
    /// 文字阴影半径
    private var textShadowRadius: CGFloat {
        switch settingsManager.settings.breakStyle {
        case .blur, .liquidGlass:
            return 3
        case .dark, .tips:
            return 1
        case .desktop, .custom:
            return 4
        }
    }
    
    /// 按钮样式
    private var buttonStyle: BreakButtonStyle {
        if isBackgroundBright {
            return .light
        }
        switch settingsManager.settings.breakStyle {
        case .blur, .liquidGlass:
            return .glass
        case .dark, .tips:
            return .dark
        case .desktop, .custom:
            return .overlay
        }
    }
    
    // MARK: - Actions
    
    private func skipBreak() {
        timerManager.skipBreak()
        BreakWindowController.shared.hideOverlay()
    }
    
    private func delayBreak(minutes: Int) {
        timerManager.delayBreak(minutes: minutes)
        BreakWindowController.shared.hideOverlay()
    }
}

// MARK: - Button Style Enum

/// 休息界面按钮样式
enum BreakButtonStyle {
    case glass    // 毛玻璃效果（用于模糊背景）
    case dark     // 深色背景上的按钮
    case overlay  // 图片背景上的按钮（深色遮罩）
    case light    // 亮色背景上的按钮（深色文字）
}

// MARK: - Custom Break Action Button

/// 自适应背景的休息操作按钮
struct BreakActionButton: View {
    let title: String
    let style: BreakButtonStyle
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(buttonTextColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: buttonShadowColor, radius: isHovering ? 8 : 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovering = hovering
            }
        }
    }
    
    @ViewBuilder
    private var buttonBackground: some View {
        switch style {
        case .glass:
            // 毛玻璃效果按钮
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .opacity(isHovering ? 1.0 : 0.8)
        case .dark:
            // 深色背景按钮（白色半透明）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovering ? 0.25 : 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        case .overlay:
            // 图片深色背景上的按钮（白色半透明）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(isHovering ? 0.3 : 0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
        case .light:
            // 亮色背景上的按钮（深色半透明）
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(isHovering ? 0.25 : 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
        }
    }
    
    private var buttonTextColor: Color {
        switch style {
        case .glass, .dark, .overlay:
            return .white
        case .light:
            return .black
        }
    }
    
    private var buttonShadowColor: Color {
        switch style {
        case .glass:
            return Color.black.opacity(0.15)
        case .dark:
            return Color.black.opacity(0.2)
        case .overlay:
            return Color.black.opacity(0.3)
        case .light:
            return Color.white.opacity(0.3)
        }
    }
}

#Preview {
    BreakOverlayView()
        .frame(width: 800, height: 600)
}

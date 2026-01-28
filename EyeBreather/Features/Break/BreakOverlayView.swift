import SwiftUI
import AppKit

/// 休息遮罩视图
struct BreakOverlayView: View {
    @ObservedObject private var timerManager = TimerManager.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        ZStack {
            // 背景
            backgroundView
            
            // 内容
            VStack(spacing: 24) {
                // 标题
                Text("休息时间")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                // 倒计时
                Text(formattedRemainingTime)
                    .font(.system(size: 120, weight: .thin, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                // 提示文字
                Text(tipsText)
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                // 进度条
                ProgressView(value: timerManager.breakProgress)
                    .progressViewStyle(.linear)
                    .frame(width: 300)
                    .tint(.white)
                
                // 操作按钮（仅温和模式显示）
                if settingsManager.settings.reminderMode == .gentle {
                    HStack(spacing: 20) {
                        Button("跳过") {
                            skipBreak()
                        }
                        .buttonStyle(.bordered)
                        
                        ForEach(settingsManager.settings.delayOptions, id: \.self) { minutes in
                            Button("延迟 \(minutes) 分钟") {
                                delayBreak(minutes: minutes)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.top, 20)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            // 液态玻璃效果 - macOS 26 风格
            ZStack {
                // 渐变背景
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.15),
                        Color.purple.opacity(0.1),
                        Color.pink.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                // 玻璃效果叠加
                Color.clear
                    .background(.ultraThinMaterial)
            }
        case .dark:
            Color.black.opacity(0.95)
        case .tips:
            Color.black.opacity(0.85)
        case .lockScreen:
            // 使用系统锁屏壁纸
            if let wallpaperURL = NSWorkspace.shared.desktopImageURL(for: NSScreen.main ?? NSScreen.screens[0]),
               let nsImage = NSImage(contentsOf: wallpaperURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.4))
                    .blur(radius: 20)
            } else {
                Color.black.opacity(0.9)
            }
        case .custom:
            if let path = settingsManager.settings.customBackgroundPath,
               let nsImage = NSImage(contentsOfFile: path) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(Color.black.opacity(0.3))
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
    
    private var formattedRemainingTime: String {
        let remaining = timerManager.remainingBreakTime
        let minutes = remaining / 60
        let seconds = remaining % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return String(format: "%d", seconds)
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

#Preview {
    BreakOverlayView()
        .frame(width: 800, height: 600)
}

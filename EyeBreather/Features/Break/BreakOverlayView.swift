import SwiftUI

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
                Text("看向远处，放松眼睛")
                    .font(.title2)
                    .foregroundColor(.white.opacity(0.8))
                
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
        case .dark:
            Color.black.opacity(0.95)
        case .tips:
            Color.black.opacity(0.9)
        case .animation:
            Color.black.opacity(0.9)
        case .scenery:
            // TODO: 添加自然风景图片
            Color.black.opacity(0.9)
        case .custom:
            // TODO: 添加自定义背景
            Color.black.opacity(0.9)
        }
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

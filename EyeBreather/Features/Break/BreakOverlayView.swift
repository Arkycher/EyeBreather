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
                
                // 操作按钮（温和模式和渐进模式非强制状态显示）
                if canSkipBreak {
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
            // 使用系统桌面壁纸
            GeometryReader { geometry in
                DesktopWallpaperView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .overlay(Color.black.opacity(0.3))
            .blur(radius: 30)
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

// MARK: - Desktop Wallpaper View

/// 获取并显示当前桌面壁纸（完全异步加载，不阻塞 UI）
private struct DesktopWallpaperView: View {
    @State private var wallpaperImage: NSImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = wallpaperImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // 加载中或回退：优雅的深色渐变背景
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .task {
            await loadWallpaperAsync()
        }
    }
    
    /// 异步加载壁纸，不阻塞主线程
    private func loadWallpaperAsync() async {
        // 在后台线程执行 I/O 操作
        let image = await Task.detached(priority: .userInitiated) {
            return loadWallpaperImage()
        }.value
        
        // 回到主线程更新 UI
        await MainActor.run {
            self.wallpaperImage = image
            self.isLoading = false
        }
    }
    
    /// 同步加载壁纸图片（在后台线程调用）
    private nonisolated func loadWallpaperImage() -> NSImage? {
        // 方法1：通过 NSWorkspace 获取当前桌面壁纸
        // 注意：NSWorkspace 需要在主线程调用，所以我们直接尝试读取文件
        
        // 方法2：直接读取壁纸配置获取路径
        if let url = getWallpaperURLFromWorkspace(),
           let image = NSImage(contentsOf: url) {
            return image
        }
        
        // 方法3：尝试从系统壁纸目录读取默认壁纸
        let wallpaperPaths = [
            "/System/Library/Desktop Pictures",
            "\(NSHomeDirectory())/Library/Desktop Pictures"
        ]
        
        for basePath in wallpaperPaths {
            if let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) {
                // 优先查找常见壁纸
                let preferredNames = ["Sonoma", "Ventura", "Monterey", "Big Sur"]
                for name in preferredNames {
                    if let match = contents.first(where: { $0.contains(name) }),
                       let image = NSImage(contentsOfFile: "\(basePath)/\(match)") {
                        return image
                    }
                }
                // 否则使用第一个图片
                if let firstImage = contents.first(where: { 
                    $0.hasSuffix(".heic") || $0.hasSuffix(".jpg") || $0.hasSuffix(".png") 
                }),
                   let image = NSImage(contentsOfFile: "\(basePath)/\(firstImage)") {
                    return image
                }
            }
        }
        
        return nil
    }
    
    /// 从 NSWorkspace 获取壁纸 URL（需要同步调用）
    private nonisolated func getWallpaperURLFromWorkspace() -> URL? {
        // 使用 DispatchQueue.main.sync 在主线程获取壁纸 URL
        // 但只获取 URL，不加载图片
        var result: URL?
        DispatchQueue.main.sync {
            if let screen = NSScreen.main {
                result = NSWorkspace.shared.desktopImageURL(for: screen)
            }
        }
        return result
    }
}

#Preview {
    BreakOverlayView()
        .frame(width: 800, height: 600)
}

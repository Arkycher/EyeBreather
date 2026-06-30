import Foundation
import AppKit
import Combine

/// 壁纸管理器 - 负责加载和缓存桌面壁纸
@MainActor
final class WallpaperManager: ObservableObject {
    /// 共享实例
    static let shared = WallpaperManager()
    
    // MARK: - Published Properties
    
    /// 当前加载的壁纸图片
    @Published private(set) var wallpaperImage: NSImage?
    
    /// 是否正在加载
    @Published private(set) var isLoading: Bool = false
    
    /// 是否有访问权限
    @Published private(set) var hasPermission: Bool = false
    
    /// 错误信息
    @Published private(set) var errorMessage: String?
    
    /// 壁纸的平均亮度 (0-1, 0=暗, 1=亮)
    @Published private(set) var wallpaperBrightness: CGFloat = 0.3

    /// 当前加载的自定义背景图片
    @Published private(set) var customBackgroundImage: NSImage?

    /// 自定义背景图片亮度
    @Published private(set) var customBackgroundBrightness: CGFloat = 0.3
    
    /// 壁纸是否偏亮（用于决定文字颜色）
    var isWallpaperBright: Bool {
        wallpaperBrightness > 0.5
    }
    
    // MARK: - Private Properties
    
    /// 缓存的壁纸 URL
    private var cachedWallpaperURL: URL?
    private var wallpaperLoadGeneration = 0
    private var customBackgroundLoadGeneration = 0
    private var loadedCustomBackgroundPath: String?
    
    private init() {
        // 性能优化：懒加载壁纸，只在需要时才加载
        // 不再在初始化时加载，由 BreakOverlayView 首次显示时触发
    }
    
    /// 确保壁纸已加载（懒加载入口）
    func ensureLoaded() {
        guard wallpaperImage == nil && !isLoading else { return }
        loadWallpaper()
    }
    
    // MARK: - Public Methods
    
    /// 加载桌面壁纸
    func loadWallpaper() {
        wallpaperLoadGeneration += 1
        let generation = wallpaperLoadGeneration
        isLoading = true
        errorMessage = nil

        let primaryWallpaperURL = NSScreen.main.flatMap { NSWorkspace.shared.desktopImageURL(for: $0) }

        DispatchQueue.global(qos: .userInitiated).async {
            let result = Self.loadWallpaperSnapshot(primaryURL: primaryWallpaperURL)

            DispatchQueue.main.async { [weak self] in
                guard let self, self.wallpaperLoadGeneration == generation else { return }

                self.cachedWallpaperURL = result.url
                self.wallpaperImage = result.image
                self.wallpaperBrightness = result.brightness
                self.hasPermission = result.hasPermission
                self.errorMessage = result.errorMessage
                self.isLoading = false
            }
        }
    }
    
    /// 分析自定义图片的亮度
    func analyzeBrightness(of imagePath: String) -> CGFloat {
        guard let image = NSImage(contentsOfFile: imagePath) else {
            return 0.3 // 默认偏暗
        }
        return Self.calculateBrightness(of: image)
    }

    func loadCustomBackground(path: String?) {
        guard loadedCustomBackgroundPath != path || customBackgroundImage == nil else { return }

        customBackgroundLoadGeneration += 1
        let generation = customBackgroundLoadGeneration
        loadedCustomBackgroundPath = path

        guard let path else {
            customBackgroundImage = nil
            customBackgroundBrightness = 0.3
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let image = NSImage(contentsOfFile: path)
            let brightness = image.map { Self.calculateBrightness(of: $0) } ?? 0.3

            DispatchQueue.main.async { [weak self] in
                guard let self, self.customBackgroundLoadGeneration == generation else { return }

                self.customBackgroundImage = image
                self.customBackgroundBrightness = brightness
            }
        }
    }
    
    /// 计算图片的平均亮度
    nonisolated static func calculateBrightness(of image: NSImage) -> CGFloat {
        // 缩小图片以提高计算速度
        let sampleSize = CGSize(width: 50, height: 50)
        
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return 0.3
        }
        
        // 创建位图上下文
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * Int(sampleSize.width)
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: Int(sampleSize.width * sampleSize.height) * bytesPerPixel)
        
        guard let context = CGContext(
            data: &pixelData,
            width: Int(sampleSize.width),
            height: Int(sampleSize.height),
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return 0.3
        }
        
        // 绘制缩小的图片
        context.draw(cgImage, in: CGRect(origin: .zero, size: sampleSize))
        
        // 计算平均亮度（使用中心区域，因为休息界面文字在中间）
        var totalBrightness: CGFloat = 0
        var sampleCount: CGFloat = 0
        
        // 只采样中心 60% 区域
        let centerStartX = Int(sampleSize.width * 0.2)
        let centerEndX = Int(sampleSize.width * 0.8)
        let centerStartY = Int(sampleSize.height * 0.2)
        let centerEndY = Int(sampleSize.height * 0.8)
        
        for y in centerStartY..<centerEndY {
            for x in centerStartX..<centerEndX {
                let offset = (y * Int(sampleSize.width) + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0
                
                // 使用感知亮度公式 (ITU-R BT.709)
                let brightness = 0.2126 * r + 0.7152 * g + 0.0722 * b
                totalBrightness += brightness
                sampleCount += 1
            }
        }
        
        return sampleCount > 0 ? totalBrightness / sampleCount : 0.3
    }
    
    /// 请求文件夹访问权限（通过打开面板）
    func requestPermission() {
        let openPanel = NSOpenPanel()
        openPanel.title = "授权访问桌面壁纸"
        openPanel.message = "请选择包含壁纸的文件夹以授权访问。通常壁纸位于 /System/Library/Desktop Pictures 或您的图片文件夹。"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = false
        
        // 设置默认路径到系统壁纸目录
        if let systemPicturesURL = URL(string: "file:///System/Library/Desktop Pictures") {
            openPanel.directoryURL = systemPicturesURL
        }
        
        if openPanel.runModal() == .OK {
            // 用户选择了文件夹，重新尝试加载
            loadWallpaper()
        }
    }
    
    /// 刷新壁纸（用户切换桌面壁纸后调用）
    func refresh() {
        wallpaperLoadGeneration += 1
        wallpaperImage = nil
        cachedWallpaperURL = nil
        loadWallpaper()
    }
    
    // MARK: - Private Methods
    
    nonisolated private static func loadWallpaperSnapshot(primaryURL: URL?) -> WallpaperSnapshot {
        if let primaryURL {
            if let image = NSImage(contentsOf: primaryURL) {
                return WallpaperSnapshot(
                    image: image,
                    brightness: calculateBrightness(of: image),
                    hasPermission: true,
                    errorMessage: nil,
                    url: primaryURL
                )
            }

            do {
                let data = try Data(contentsOf: primaryURL)
                if let image = NSImage(data: data) {
                    return WallpaperSnapshot(
                        image: image,
                        brightness: calculateBrightness(of: image),
                        hasPermission: true,
                        errorMessage: nil,
                        url: primaryURL
                    )
                }
            } catch {
                let fallback = loadSystemDefaultWallpaper()
                if fallback.image != nil {
                    return fallback
                }

                return WallpaperSnapshot(
                    image: nil,
                    brightness: 0.3,
                    hasPermission: false,
                    errorMessage: "无法访问壁纸文件，可能需要授权",
                    url: primaryURL
                )
            }
        }

        return loadSystemDefaultWallpaper()
    }

    nonisolated private static func loadSystemDefaultWallpaper() -> WallpaperSnapshot {
        let systemWallpaperPath = "/System/Library/Desktop Pictures"
        
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: systemWallpaperPath) else {
            return WallpaperSnapshot(image: nil, brightness: 0.3, hasPermission: false, errorMessage: nil, url: nil)
        }
        
        // 按优先级查找系统壁纸
        let preferredNames = ["Sonoma", "Sequoia", "Ventura", "Monterey", "Big Sur"]
        
        for name in preferredNames {
            if let match = contents.first(where: { $0.contains(name) && ($0.hasSuffix(".heic") || $0.hasSuffix(".jpg")) }),
               let image = NSImage(contentsOfFile: "\(systemWallpaperPath)/\(match)") {
                return WallpaperSnapshot(
                    image: image,
                    brightness: calculateBrightness(of: image),
                    hasPermission: true,
                    errorMessage: nil,
                    url: URL(fileURLWithPath: "\(systemWallpaperPath)/\(match)")
                )
            }
        }
        
        // 如果没有找到首选壁纸，使用第一个可用的
        if let firstImage = contents.first(where: { $0.hasSuffix(".heic") || $0.hasSuffix(".jpg") }),
           let image = NSImage(contentsOfFile: "\(systemWallpaperPath)/\(firstImage)") {
            return WallpaperSnapshot(
                image: image,
                brightness: calculateBrightness(of: image),
                hasPermission: true,
                errorMessage: nil,
                url: URL(fileURLWithPath: "\(systemWallpaperPath)/\(firstImage)")
            )
        }

        return WallpaperSnapshot(image: nil, brightness: 0.3, hasPermission: false, errorMessage: nil, url: nil)
    }
}

private struct WallpaperSnapshot {
    let image: NSImage?
    let brightness: CGFloat
    let hasPermission: Bool
    let errorMessage: String?
    let url: URL?
}

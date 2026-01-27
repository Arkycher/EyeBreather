import Foundation

struct FocusApp: Codable, Identifiable, Equatable, Hashable {
    var id: String { bundleId }
    let bundleId: String
    let name: String
    let isPreset: Bool
    
    static let presets: [FocusApp] = [
        // 会议
        FocusApp(bundleId: "us.zoom.xos", name: "Zoom", isPreset: true),
        FocusApp(bundleId: "com.tencent.meeting", name: "腾讯会议", isPreset: true),
        FocusApp(bundleId: "com.bytedance.lark", name: "飞书", isPreset: true),
        FocusApp(bundleId: "com.alibaba.DingTalkMac", name: "钉钉", isPreset: true),
        FocusApp(bundleId: "com.microsoft.teams", name: "Teams", isPreset: true),
        FocusApp(bundleId: "com.apple.FaceTime", name: "FaceTime", isPreset: true),
        
        // 视频
        FocusApp(bundleId: "org.videolan.vlc", name: "VLC", isPreset: true),
        FocusApp(bundleId: "com.colliderli.iina", name: "IINA", isPreset: true),
        FocusApp(bundleId: "com.apple.TV", name: "Apple TV", isPreset: true),
        
        // 游戏
        FocusApp(bundleId: "com.valvesoftware.steam", name: "Steam", isPreset: true),
        FocusApp(bundleId: "com.epicgames.EpicGamesLauncher", name: "Epic Games", isPreset: true),
    ]
}

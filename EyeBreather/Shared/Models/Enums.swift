import Foundation

/// 提醒模式
enum ReminderMode: String, Codable, CaseIterable {
    case forced = "forced"           // 强制模式
    case gentle = "gentle"           // 温和模式
    case progressive = "progressive" // 渐进模式
    
    var displayName: String {
        switch self {
        case .forced: return "强制模式"
        case .gentle: return "温和模式"
        case .progressive: return "渐进模式"
        }
    }
    
    var description: String {
        switch self {
        case .forced: return "休息时全屏遮罩，必须完成"
        case .gentle: return "弹出通知提醒，可选择跳过"
        case .progressive: return "多次跳过后自动变为强制模式"
        }
    }
}

/// 休息界面样式
enum BreakStyle: String, Codable, CaseIterable {
    case dark = "dark"           // 纯黑
    case tips = "tips"           // 护眼提示
    case animation = "animation" // 动画引导
    case scenery = "scenery"     // 自然风景
    case custom = "custom"       // 自定义背景
    
    var displayName: String {
        switch self {
        case .dark: return "深色遮罩"
        case .tips: return "护眼提示"
        case .animation: return "动画引导"
        case .scenery: return "自然风景"
        case .custom: return "自定义背景"
        }
    }
}

/// 外观模式
enum AppearanceMode: String, Codable, CaseIterable {
    case system = "system" // 跟随系统
    case light = "light"   // 浅色
    case dark = "dark"     // 深色
    
    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

/// 计时器状态
enum TimerState: String, Codable {
    case idle = "idle"         // 空闲（未开始）
    case working = "working"   // 工作中
    case preBreak = "preBreak" // 休息预警
    case breaking = "breaking" // 休息中
    case paused = "paused"     // 已暂停
}

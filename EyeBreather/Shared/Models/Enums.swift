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
    case blur = "blur"           // 背景模糊
    case dark = "dark"           // 纯黑
    case tips = "tips"           // 护眼提示
    case animation = "animation" // 动画引导
    case scenery = "scenery"     // 自然风景
    case custom = "custom"       // 自定义背景
    
    var displayName: String {
        switch self {
        case .blur: return "背景模糊"
        case .dark: return "深色遮罩"
        case .tips: return "护眼提示"
        case .animation: return "动画引导"
        case .scenery: return "自然风景"
        case .custom: return "自定义背景"
        }
    }
    
    var description: String {
        switch self {
        case .blur: return "屏幕渐变为毛玻璃效果，隐约可见但无法工作"
        case .dark: return "纯黑色背景，完全遮挡屏幕"
        case .tips: return "显示护眼小贴士，支持自定义内容"
        case .animation: return "呼吸引导动画，帮助放松眼睛"
        case .scenery: return "展示自然风景图片，舒缓心情"
        case .custom: return "使用你选择的图片作为背景"
        }
    }
    
    var icon: String {
        switch self {
        case .blur: return "drop.fill"
        case .dark: return "moon.fill"
        case .tips: return "text.bubble.fill"
        case .animation: return "wind"
        case .scenery: return "leaf.fill"
        case .custom: return "photo.fill"
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

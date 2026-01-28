import Foundation
import AVFoundation
import AppKit

/// 声音管理器
@MainActor
final class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayer: AVAudioPlayer?
    
    /// 可用的提示音列表
    static let availableSounds: [(id: String, name: String)] = [
        ("default", "系统默认"),
        ("glass", "玻璃"),
        ("ping", "叮"),
        ("pop", "弹出"),
        ("purr", "呼噜"),
        ("submarine", "潜艇"),
        ("tink", "铃声")
    ]
    
    private init() {}
    
    /// 播放休息开始提示音
    func playBreakStartSound() {
        guard SettingsManager.shared.settings.enableSound else { return }
        let soundId = SettingsManager.shared.settings.breakStartSound
        playSystemSound(soundId)
    }
    
    /// 播放休息结束提示音
    func playBreakEndSound() {
        guard SettingsManager.shared.settings.enableSound else { return }
        let soundId = SettingsManager.shared.settings.breakEndSound
        playSystemSound(soundId)
    }
    
    private func playSystemSound(_ soundId: String) {
        // 使用系统声音
        let soundName: String
        switch soundId {
        case "glass": soundName = "Glass"
        case "ping": soundName = "Ping"
        case "pop": soundName = "Pop"
        case "purr": soundName = "Purr"
        case "submarine": soundName = "Submarine"
        case "tink": soundName = "Tink"
        default: soundName = "Glass" // 默认使用 Glass
        }
        
        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.play()
        }
    }
}

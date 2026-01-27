import Foundation
import AVFoundation
import Combine
import CoreMediaIO

/// 媒体设备监视器 - 检测摄像头和麦克风使用状态
@MainActor
final class MediaDeviceMonitor: ObservableObject {
    /// 共享实例
    static let shared = MediaDeviceMonitor()
    
    // MARK: - Published Properties
    
    /// 摄像头是否在使用中
    @Published private(set) var isCameraInUse: Bool = false
    
    /// 麦克风是否在使用中
    @Published private(set) var isMicrophoneInUse: Bool = false
    
    /// 是否处于会议中（摄像头或麦克风在使用）
    var isInMeeting: Bool {
        isCameraInUse || isMicrophoneInUse
    }
    
    // MARK: - Private Properties
    
    private var checkTimer: Timer?
    
    // MARK: - Initialization
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        checkTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// 开始监控设备状态
    func startMonitoring() {
        // 每 5 秒检查一次
        checkTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkDeviceStatus()
            }
        }
        // 立即检查一次
        checkDeviceStatus()
    }
    
    /// 停止监控
    func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    // MARK: - Private Methods
    
    private func checkDeviceStatus() {
        isCameraInUse = checkCameraInUse()
        isMicrophoneInUse = checkMicrophoneInUse()
        
        // 发送状态变化通知
        NotificationCenter.default.post(
            name: .meetingStatusChanged,
            object: nil,
            userInfo: ["isInMeeting": isInMeeting]
        )
    }
    
    private func checkCameraInUse() -> Bool {
        // 使用 CoreMediaIO 检测摄像头状态
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else { return false }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIOObjectID>.size
        var devices = [CMIOObjectID](repeating: 0, count: deviceCount)
        
        result = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataSize,
            &devices
        )
        
        guard result == kCMIOHardwareNoError else { return false }
        
        // 检查每个设备是否正在使用
        for device in devices {
            if isDeviceInUse(device) {
                return true
            }
        }
        
        return false
    }
    
    private func isDeviceInUse(_ deviceID: CMIOObjectID) -> Bool {
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var isRunning: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)
        
        let result = CMIOObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0,
            nil,
            dataSize,
            &dataSize,
            &isRunning
        )
        
        return result == kCMIOHardwareNoError && isRunning != 0
    }
    
    private func checkMicrophoneInUse() -> Bool {
        // 简化检测：如果摄像头在使用，通常麦克风也在使用（会议场景）
        return isCameraInUse
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let meetingStatusChanged = Notification.Name("com.eyebreather.meetingStatusChanged")
}

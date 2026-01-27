import SwiftUI

/// 设置视图
struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        TabView {
            // 休息规则
            BreakRulesSettingsView()
                .tabItem {
                    Label("休息规则", systemImage: "clock")
                }
            
            // 智能检测
            SmartDetectionSettingsView()
                .tabItem {
                    Label("智能检测", systemImage: "brain")
                }
            
            // 休息界面
            BreakStyleSettingsView()
                .tabItem {
                    Label("休息界面", systemImage: "photo")
                }
            
            // 通用
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
        }
        .padding(20)
        .frame(width: 480, height: 500)
    }
}

// MARK: - Break Rules Settings

struct BreakRulesSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                // 工作时长
                Stepper(value: $settingsManager.settings.workDuration, in: 1...120) {
                    HStack {
                        Text("工作时长")
                        Spacer()
                        Text("\(settingsManager.settings.workDuration) 分钟")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 休息时长
                Stepper(value: $settingsManager.settings.breakDuration, in: 5...300, step: 5) {
                    HStack {
                        Text("休息时长")
                        Spacer()
                        Text("\(settingsManager.settings.breakDuration) 秒")
                            .foregroundColor(.secondary)
                    }
                }
                
                // 提醒模式
                Picker("提醒模式", selection: $settingsManager.settings.reminderMode) {
                    ForEach(ReminderMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                
                // 休息预警
                Stepper(value: $settingsManager.settings.preBreakWarning, in: 0...300, step: 10) {
                    HStack {
                        Text("休息预警")
                        Spacer()
                        Text("\(settingsManager.settings.preBreakWarning) 秒前")
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("休息规则")
            } footer: {
                Text("默认采用 20-20-20 法则：每工作 20 分钟，休息 20 秒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Smart Detection Settings

struct SmartDetectionSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                // 活动检测
                Toggle("启用活动检测", isOn: $settingsManager.settings.enableActivityDetection)
                
                if settingsManager.settings.enableActivityDetection {
                    Stepper(value: $settingsManager.settings.idleResetThreshold, in: 1...60) {
                        HStack {
                            Text("空闲重置阈值")
                            Spacer()
                            Text("\(settingsManager.settings.idleResetThreshold) 分钟")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("活动检测")
            } footer: {
                Text("检测鼠标和键盘活动，空闲超过阈值后重置计时器")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                // 全屏暂停
                Toggle("全屏应用时暂停", isOn: $settingsManager.settings.enableFullscreenPause)
                
                // 白名单应用
                DisclosureGroup("应用白名单 (\(settingsManager.settings.whitelistApps.count))") {
                    ForEach(settingsManager.settings.whitelistApps, id: \.self) { bundleId in
                        HStack {
                            Text(bundleId)
                                .font(.caption)
                            Spacer()
                            Button(action: {
                                removeFromWhitelist(bundleId)
                            }) {
                                Image(systemName: "minus.circle")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // 添加应用按钮
                    Menu("添加应用...") {
                        ForEach(availableApps, id: \.bundleId) { app in
                            Button(app.name) {
                                addToWhitelist(app.bundleId)
                            }
                        }
                    }
                }
            } header: {
                Text("应用检测")
            } footer: {
                Text("白名单中的应用运行时不会触发休息提醒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
    }
    
    private var availableApps: [(bundleId: String, name: String)] {
        AppDetector.shared.getRunningApps()
            .filter { !settingsManager.settings.whitelistApps.contains($0.bundleId) }
    }
    
    private func addToWhitelist(_ bundleId: String) {
        settingsManager.settings.whitelistApps.append(bundleId)
    }
    
    private func removeFromWhitelist(_ bundleId: String) {
        settingsManager.settings.whitelistApps.removeAll { $0 == bundleId }
    }
}

// MARK: - Break Style Settings

struct BreakStyleSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                Picker("休息界面样式", selection: $settingsManager.settings.breakStyle) {
                    ForEach(BreakStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                
                if settingsManager.settings.breakStyle == .custom {
                    HStack {
                        Text("自定义背景")
                        Spacer()
                        Button("选择图片...") {
                            selectCustomBackground()
                        }
                    }
                    
                    if let path = settingsManager.settings.customBackgroundPath {
                        Text(path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
            } header: {
                Text("休息界面样式")
            }
        }
        .formStyle(.grouped)
    }
    
    private func selectCustomBackground() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            settingsManager.settings.customBackgroundPath = url.path
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                Toggle("开机自动启动", isOn: $settingsManager.settings.launchAtLogin)
                Toggle("在 Dock 中显示图标", isOn: $settingsManager.settings.showInDock)
                
                Picker("外观模式", selection: $settingsManager.settings.appearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            } header: {
                Text("通用")
            }
            
            Section {
                Button("重置为默认设置") {
                    settingsManager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
            
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
    }
}

#Preview {
    SettingsView()
}

import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Settings Section Enum

enum SettingsSection: String, CaseIterable, Identifiable {
    case breakRules = "breakRules"
    case smartPause = "smartPause"
    case appearance = "appearance"
    case general = "general"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .breakRules: return "休息规则"
        case .smartPause: return "智能暂停"
        case .appearance: return "外观"
        case .general: return "通用"
        }
    }
    
    var icon: String {
        switch self {
        case .breakRules: return "timer"
        case .smartPause: return "target"
        case .appearance: return "paintbrush"
        case .general: return "gearshape"
        }
    }
}

// MARK: - Main Settings View

/// 设置视图（侧边栏式设计）
struct SettingsView: View {
    @State private var selectedSection: SettingsSection = .breakRules
    
    var body: some View {
        NavigationSplitView {
            // 侧边栏
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Label(section.title, systemImage: section.icon)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 150, ideal: 180)
        } detail: {
            // 详情视图
            switch selectedSection {
            case .breakRules:
                BreakRulesSection()
            case .smartPause:
                SmartPauseSection()
            case .appearance:
                AppearanceSection()
            case .general:
                GeneralSection()
            }
        }
        .frame(width: 550, height: 450)
    }
}

// MARK: - Break Rules Section

struct BreakRulesSection: View {
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
            } header: {
                Text("时间设置")
            } footer: {
                Text("推荐采用 20-20-20 法则：每工作 20 分钟，休息 20 秒，看向 20 英尺外")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                // 提醒模式
                Picker("提醒模式", selection: $settingsManager.settings.reminderMode) {
                    ForEach(ReminderMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                
                // 显示模式描述
                Text(settingsManager.settings.reminderMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            } header: {
                Text("提醒方式")
            }
            
            Section {
                // 休息预警
                Stepper(value: $settingsManager.settings.preBreakWarning, in: 0...300, step: 10) {
                    HStack {
                        Text("休息预警")
                        Spacer()
                        if settingsManager.settings.preBreakWarning > 0 {
                            Text("\(settingsManager.settings.preBreakWarning) 秒前提醒")
                                .foregroundColor(.secondary)
                        } else {
                            Text("关闭")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("预警设置")
            } footer: {
                Text("在休息开始前提前通知，让你有准备时间")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("休息规则")
    }
}

// MARK: - Smart Pause Section

struct SmartPauseSection: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingAppPicker = false
    
    var body: some View {
        Form {
            Section {
                // 会议检测开关
                Toggle("会议检测", isOn: $settingsManager.settings.enableMeetingDetection)
            } header: {
                Text("会议检测")
            } footer: {
                Text("检测摄像头和麦克风使用，会议期间自动暂停提醒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                // 专注模式应用列表
                ForEach(settingsManager.settings.focusApps) { app in
                    HStack {
                        Image(systemName: app.isPreset ? "app.fill" : "app")
                            .foregroundColor(.accentColor)
                        
                        Text(app.name)
                        
                        Spacer()
                        
                        if app.isPreset {
                            Text("预设")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Button(action: {
                            removeFromFocusApps(app.bundleId)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 添加应用按钮
                Button(action: {
                    showingAppPicker = true
                }) {
                    Label("添加应用...", systemImage: "plus.circle")
                }
            } header: {
                HStack {
                    Text("专注模式应用")
                    Spacer()
                    Text("\(settingsManager.settings.focusApps.count) 个应用")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } footer: {
                Text("这些应用在前台运行时，不会触发休息提醒")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                // 活动检测
                Toggle("活动检测", isOn: $settingsManager.settings.enableActivityDetection)
                
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
                Text("检测鼠标和键盘活动，长时间空闲后自动重置计时器")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                // 智能推荐
                Toggle("智能推荐", isOn: $settingsManager.settings.enableSmartRecommend)
            } header: {
                Text("智能推荐")
            } footer: {
                Text("根据你的使用习惯，智能推荐添加专注模式应用")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("智能暂停")
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleId, name in
                addToFocusApps(bundleId, name: name)
            }
        }
    }
    
    private func addToFocusApps(_ bundleId: String, name: String) {
        // 检查是否已存在
        guard !settingsManager.settings.focusApps.contains(where: { $0.bundleId == bundleId }) else {
            return
        }
        let newApp = FocusApp(bundleId: bundleId, name: name, isPreset: false)
        settingsManager.settings.focusApps.append(newApp)
    }
    
    private func removeFromFocusApps(_ bundleId: String) {
        settingsManager.settings.focusApps.removeAll { $0.bundleId == bundleId }
    }
}

// MARK: - App Picker View

struct AppPickerView: View {
    @Environment(\.dismiss) private var dismiss
    var onSelect: (String, String) -> Void
    
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("选择应用")
                    .font(.headline)
                Spacer()
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            // 搜索框
            TextField("搜索应用...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            // 应用列表
            List(filteredApps, id: \.bundleId) { app in
                Button(action: {
                    onSelect(app.bundleId, app.name)
                    dismiss()
                }) {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "app")
                                .frame(width: 24, height: 24)
                        }
                        
                        Text(app.name)
                        
                        Spacer()
                        
                        Text(app.bundleId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 400, height: 350)
    }
    
    private var runningApps: [(bundleId: String, name: String, icon: NSImage?)] {
        AppDetector.shared.getRunningApps()
            .filter { app in
                !SettingsManager.shared.settings.focusApps.contains(where: { $0.bundleId == app.bundleId })
            }
            .map { ($0.bundleId, $0.name, NSWorkspace.shared.icon(forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleId)?.path ?? "")) }
    }
    
    private var filteredApps: [(bundleId: String, name: String, icon: NSImage?)] {
        if searchText.isEmpty {
            return runningApps
        }
        return runningApps.filter { app in
            app.name.localizedCaseInsensitiveContains(searchText) ||
            app.bundleId.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Appearance Section

struct AppearanceSection: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        Form {
            Section {
                // 外观模式
                Picker("外观模式", selection: $settingsManager.settings.appearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("主题")
            }
            
            Section {
                // 休息界面样式
                Picker("休息界面", selection: $settingsManager.settings.breakStyle) {
                    ForEach(BreakStyle.allCases, id: \.self) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                
                if settingsManager.settings.breakStyle == .custom {
                    HStack {
                        if let path = settingsManager.settings.customBackgroundPath {
                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        } else {
                            Text("未选择背景图片")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("选择图片...") {
                            selectCustomBackground()
                        }
                    }
                }
            } header: {
                Text("休息界面样式")
            } footer: {
                Text("选择休息时显示的界面风格")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .navigationTitle("外观")
    }
    
    private func selectCustomBackground() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "选择休息界面的背景图片"
        
        if panel.runModal() == .OK, let url = panel.url {
            settingsManager.settings.customBackgroundPath = url.path
        }
    }
}

// MARK: - General Section

struct GeneralSection: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            Section {
                Toggle("开机自动启动", isOn: Binding(
                    get: { launchAtLoginManager.isEnabled },
                    set: { launchAtLoginManager.setEnabled($0) }
                ))
                
                Toggle("在 Dock 中显示图标", isOn: Binding(
                    get: { settingsManager.settings.showInDock },
                    set: { newValue in
                        settingsManager.settings.showInDock = newValue
                        if let appDelegate = NSApp.delegate as? AppDelegate {
                            appDelegate.updateDockIconVisibility(show: newValue)
                        }
                    }
                ))
            } header: {
                Text("启动")
            }
            
            Section {
                Button(role: .destructive) {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("重置为默认设置")
                    }
                }
            } header: {
                Text("重置")
            } footer: {
                Text("将所有设置恢复为默认值")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("构建")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("关于")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("通用")
        .alert("重置设置", isPresented: $showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                settingsManager.resetToDefaults()
            }
        } message: {
            Text("确定要将所有设置恢复为默认值吗？此操作无法撤销。")
        }
    }
}

#Preview {
    SettingsView()
}

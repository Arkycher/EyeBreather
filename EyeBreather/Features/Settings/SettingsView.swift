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
        HStack(spacing: 0) {
            // 侧边栏 - Surge 风格：浅灰色背景
            VStack(alignment: .leading, spacing: 2) {
                ForEach(SettingsSection.allCases) { section in
                    SurgeSidebarItem(
                        title: section.title,
                        icon: section.icon,
                        isSelected: selectedSection == section
                    ) {
                        selectedSection = section
                    }
                }
                Spacer()
            }
            .padding(.top, 12)
            .padding(.horizontal, 8)
            .frame(width: 160)
            .frame(maxHeight: .infinity)
            .background(Color(nsColor: NSColor(white: 0.94, alpha: 1.0)))
            
            // 内容区 - 渐变背景
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // 标题区域
                    Text(selectedSection.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal, 28)
                        .padding(.top, 24)
                        .padding(.bottom, 20)
                    
                    // 内容区域
                    detailContent
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                // Surge 风格：粉紫渐变背景
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.98),
                        Color(red: 0.96, green: 0.94, blue: 0.98),
                        Color(red: 0.94, green: 0.92, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        .frame(width: 640, height: 520)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        switch selectedSection {
        case .breakRules:
            BreakRulesSectionContent()
        case .smartPause:
            SmartPauseSectionContent()
        case .appearance:
            AppearanceSectionContent()
        case .general:
            GeneralSectionContent()
        }
    }
}

// MARK: - Surge Sidebar Item (Surge 风格)

struct SurgeSidebarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isSelected ? .primary : .secondary)
                    .frame(width: 22)
                
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color(nsColor: NSColor(white: 0.88, alpha: 1.0)) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings Card

struct SettingsCard<Content: View>: View {
    let title: String
    let footer: String?
    @ViewBuilder let content: () -> Content
    
    init(title: String, footer: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.footer = footer
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 分组标题：深灰色，更有层次感
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(nsColor: NSColor(white: 0.4, alpha: 1.0)))
            
            // 白色圆角卡片
            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
            
            if let footer = footer {
                Text(footer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
        }
    }
}

struct SettingsRow: View {
    let title: String
    var value: String? = nil
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            if let value = value {
                Text(value)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Break Rules Section Content

struct BreakRulesSectionContent: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 时间设置卡片
            SettingsCard(title: "时间设置", footer: "推荐 20-20-20 法则：每 20 分钟休息 20 秒") {
                VStack(spacing: 0) {
                    Stepper(value: $settingsManager.settings.workDuration, in: 1...120) {
                        SettingsRow(title: "工作时长", value: "\(settingsManager.settings.workDuration) 分钟")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    
                    Divider().padding(.leading, 12)
                    
                    Stepper(value: $settingsManager.settings.breakDuration, in: 5...300, step: 5) {
                        SettingsRow(title: "休息时长", value: "\(settingsManager.settings.breakDuration) 秒")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
            }
            
            // 提醒方式卡片
            SettingsCard(title: "提醒方式") {
                VStack(spacing: 0) {
                    Picker("", selection: $settingsManager.settings.reminderMode) {
                        ForEach(ReminderMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(12)
                    
                    Divider().padding(.leading, 12)
                    
                    Text(settingsManager.settings.reminderMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
            }
            
            // 预警设置卡片
            SettingsCard(title: "预警设置", footer: "休息开始前提前通知") {
                Stepper(value: $settingsManager.settings.preBreakWarning, in: 0...300, step: 10) {
                    SettingsRow(
                        title: "休息预警",
                        value: settingsManager.settings.preBreakWarning > 0 
                            ? "\(settingsManager.settings.preBreakWarning) 秒前" 
                            : "关闭"
                    )
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
        }
    }
}

// MARK: - Smart Pause Section Content

struct SmartPauseSectionContent: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingAppPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 会议检测卡片
            SettingsCard(title: "会议检测", footer: "摄像头/麦克风使用时自动暂停") {
                Toggle(isOn: $settingsManager.settings.enableMeetingDetection) {
                    SettingsRow(title: "自动检测会议")
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            
            // 专注模式应用卡片
            SettingsCard(title: "专注模式应用 (\(settingsManager.settings.focusApps.count))", footer: "这些应用在前台时不会触发休息提醒") {
                VStack(spacing: 0) {
                    ForEach(Array(settingsManager.settings.focusApps.enumerated()), id: \.element.id) { index, app in
                        if index > 0 {
                            Divider().padding(.leading, 44)
                        }
                        
                        HStack(spacing: 10) {
                            Image(systemName: "app.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            
                            Text(app.name)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if app.isPreset {
                                Text("预设")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            }
                            
                            Button {
                                removeFromFocusApps(app.bundleId)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    
                    Divider().padding(.leading, 44)
                    
                    Button {
                        showingAppPicker = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                                .frame(width: 20)
                            Text("添加应用...")
                                .foregroundColor(.accentColor)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // 活动检测卡片
            SettingsCard(title: "活动检测", footer: "长时间空闲后自动重置计时器") {
                VStack(spacing: 0) {
                    Toggle(isOn: $settingsManager.settings.enableActivityDetection) {
                        SettingsRow(title: "检测用户活动")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    if settingsManager.settings.enableActivityDetection {
                        Divider().padding(.leading, 12)
                        
                        Stepper(value: $settingsManager.settings.idleResetThreshold, in: 1...60) {
                            SettingsRow(title: "空闲阈值", value: "\(settingsManager.settings.idleResetThreshold) 分钟")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleId, name in
                addToFocusApps(bundleId, name: name)
            }
        }
    }
    
    private func addToFocusApps(_ bundleId: String, name: String) {
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
                .buttonStyle(.bordered)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            // 搜索框
            TextField("搜索应用...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding()
            
            // 应用列表
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredApps.enumerated()), id: \.element.bundleId) { index, app in
                        if index > 0 {
                            Divider().padding(.leading, 44)
                        }
                        
                        Button {
                            onSelect(app.bundleId, app.name)
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "app")
                                        .frame(width: 24, height: 24)
                                }
                                
                                Text(app.name)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(.thickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .frame(width: 380, height: 350)
        .background(.regularMaterial)
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

// MARK: - Appearance Section Content

struct AppearanceSectionContent: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 主题卡片
            SettingsCard(title: "主题") {
                Picker("", selection: $settingsManager.settings.appearance) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(12)
            }
            
            // 休息界面样式卡片
            SettingsCard(title: "休息界面样式", footer: "休息时显示的界面风格") {
                VStack(spacing: 0) {
                    ForEach(Array(BreakStyle.allCases.enumerated()), id: \.element) { index, style in
                        if index > 0 {
                            Divider().padding(.leading, 12)
                        }
                        
                        HStack {
                            Text(style.displayName)
                            Spacer()
                            if settingsManager.settings.breakStyle == style {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .fontWeight(.medium)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            settingsManager.settings.breakStyle = style
                        }
                    }
                    
                    if settingsManager.settings.breakStyle == .custom {
                        Divider().padding(.leading, 12)
                        
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
                            .buttonStyle(.bordered)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                }
            }
        }
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

// MARK: - General Section Content

struct GeneralSectionContent: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var launchAtLoginManager = LaunchAtLoginManager.shared
    @State private var showingResetAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 启动卡片
            SettingsCard(title: "启动") {
                VStack(spacing: 0) {
                    Toggle(isOn: Binding(
                        get: { launchAtLoginManager.isEnabled },
                        set: { launchAtLoginManager.setEnabled($0) }
                    )) {
                        SettingsRow(title: "开机自动启动")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    
                    Divider().padding(.leading, 12)
                    
                    Toggle(isOn: Binding(
                        get: { settingsManager.settings.showInDock },
                        set: { newValue in
                            settingsManager.settings.showInDock = newValue
                            if let appDelegate = NSApp.delegate as? AppDelegate {
                                appDelegate.updateDockIconVisibility(show: newValue)
                            }
                        }
                    )) {
                        SettingsRow(title: "在 Dock 中显示图标")
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
            }
            
            // 重置卡片
            SettingsCard(title: "重置", footer: "将所有设置恢复为默认值") {
                Button {
                    showingResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.red)
                        Text("重置为默认设置")
                            .foregroundColor(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            
            // 关于卡片
            SettingsCard(title: "关于") {
                VStack(spacing: 0) {
                    SettingsRow(
                        title: "版本",
                        value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                    )
                    
                    Divider().padding(.leading, 12)
                    
                    SettingsRow(
                        title: "构建",
                        value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
                    )
                }
            }
        }
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

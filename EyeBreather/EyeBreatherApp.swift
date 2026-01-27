//
//  EyeBreatherApp.swift
//  EyeBreather
//
//  Created by lamther on 2026/1/27.
//

import SwiftUI
import SwiftData

@main
struct EyeBreatherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings 场景作为主窗口（可选显示）
        Settings {
            ContentView()
                .modelContainer(DataStoreManager.shared.container)
        }
    }
}

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
        // 菜单栏应用
        MenuBarExtra {
            MenuBarView()
                .modelContainer(DataStoreManager.shared.container)
        } label: {
            Image(systemName: "eye")
        }
        .menuBarExtraStyle(.window)
        
        // 设置窗口
        Settings {
            ContentView()
                .modelContainer(DataStoreManager.shared.container)
        }
    }
}

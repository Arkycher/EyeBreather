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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataStoreManager.shared.container)
    }
}

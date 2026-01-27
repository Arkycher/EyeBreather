//
//  DataStoreManager.swift
//  EyeBreather
//
//  Created by lamther on 2026/1/27.
//

import Foundation
import SwiftData

/// 数据存储管理器
@MainActor
final class DataStoreManager {
    /// 共享实例
    static let shared = DataStoreManager()
    
    /// SwiftData 容器
    let container: ModelContainer
    
    /// 主上下文
    var mainContext: ModelContext {
        container.mainContext
    }
    
    private init() {
        let schema = Schema([
            BreakRecord.self,
            DailyStatistics.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法初始化 SwiftData 容器: \(error)")
        }
    }
    
    /// 创建用于测试的内存容器
    static func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            BreakRecord.self,
            DailyStatistics.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        return try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
    }
}

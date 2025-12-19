import Foundation
import AppKit
import SwiftUI

// 应用信息结构体，用于存储单个应用的相关信息
struct AppInfo: Identifiable, Hashable, Codable {
    let id: String              // 唯一标识符（通常是 bundleIdentifier 或路径）
    let name: String            // 应用名称
    let path: String            // 应用在磁盘上的绝对路径
    let bundleIdentifier: String? // 应用的包名（Bundle ID）
    var folderId: UUID?         // 所属文件夹的 ID（如果有）
    var category: String?       // 应用分类
    var sortOrder: Int          // 排序权重
    
    init(name: String, path: String, bundleIdentifier: String?, folderId: UUID? = nil, category: String? = nil, sortOrder: Int = 0) {
        self.id = bundleIdentifier ?? path
        self.name = name
        self.path = path
        self.bundleIdentifier = bundleIdentifier
        self.folderId = folderId
        self.category = category
        self.sortOrder = sortOrder
    }
}

// 文件夹信息结构体，用于管理应用分组
struct FolderInfo: Identifiable, Hashable, Codable {
    let id: UUID                // 文件夹唯一 ID
    var name: String            // 文件夹名称
    var appIds: [String]        // 文件夹内包含的应用 ID 列表
    
    init(id: UUID = UUID(), name: String, appIds: [String] = []) {
        self.id = id
        self.name = name
        self.appIds = appIds
    }
}

// Launchpad 界面显示项的枚举，可以是单个应用或一个文件夹
enum LaunchpadItem: Identifiable, Hashable {
    case app(AppInfo)           // 单个应用项
    case folder(FolderInfo)     // 文件夹项
    
    // 统一的 ID 访问接口
    var id: String {
        switch self {
        case .app(let app): return app.id
        case .folder(let folder): return folder.id.uuidString
        }
    }
    
    // 统一的名称访问接口
    var name: String {
        switch self {
        case .app(let app): return app.name
        case .folder(let folder): return folder.name
        }
    }
}

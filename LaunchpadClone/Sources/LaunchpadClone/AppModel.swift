import Foundation
import AppKit
import SwiftUI

struct AppInfo: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let path: String
    let bundleIdentifier: String?
    var folderId: UUID?
    var category: String?
    var sortOrder: Int
    
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

struct FolderInfo: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var appIds: [String]
    
    init(id: UUID = UUID(), name: String, appIds: [String] = []) {
        self.id = id
        self.name = name
        self.appIds = appIds
    }
}

enum LaunchpadItem: Identifiable, Hashable {
    case app(AppInfo)
    case folder(FolderInfo)
    
    var id: String {
        switch self {
        case .app(let app): return app.id
        case .folder(let folder): return folder.id.uuidString
        }
    }
    
    var name: String {
        switch self {
        case .app(let app): return app.name
        case .folder(let folder): return folder.name
        }
    }
}

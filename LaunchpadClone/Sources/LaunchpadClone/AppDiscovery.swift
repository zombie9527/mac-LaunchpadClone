import Foundation
import AppKit

// 应用发现与管理类，负责扫描系统中的应用并管理其在 Launchpad 中的显示
class AppDiscovery: ObservableObject {
    @Published var apps: [AppInfo] = []          // 扫描到的所有应用列表
    @Published var folders: [FolderInfo] = []    // 用户创建的文件夹列表
    @Published var gridItems: [LaunchpadItem] = [] // 最终显示在网格中的项（应用或文件夹）
    @Published var isLoading = false             // 是否正在加载
    private var isScanning = false               // 是否正在扫描中
    var hasScanned = false                       // 是否已经完成过扫描
    
    private let settings = SettingsManager.shared
    
    // 扫描系统应用
    // force: 是否强制重新扫描
    func scan(force: Bool = false) {
        if isScanning { return }
        if !force && hasScanned { return }
        
        print("Starting app scan (force: \(force))...")
        isScanning = true
        isLoading = true
        
        Task {
            // 获取已保存的设置
            let hiddenIds = self.settings.hiddenAppBundleIds
            let savedFolders = self.settings.folders
            let savedCategories = self.settings.categories
            let savedSortOrders = self.settings.sortOrders
            
            // 定义要扫描的目录
            let appDirs = ["/Applications", "/System/Applications", "\(NSHomeDirectory())/Applications"]
            let fileManager = FileManager.default
            var foundApps: [AppInfo] = []
            
            for dir in appDirs {
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: dir)
                    for item in contents {
                        if item.hasSuffix(".app") {
                            let fullPath = (dir as NSString).appendingPathComponent(item)
                            let name = (item as NSString).deletingPathExtension
                            let bundle = Bundle(path: fullPath)
                            let bundleId = bundle?.bundleIdentifier ?? fullPath
                            
                            // 过滤掉隐藏的应用
                            if hiddenIds.contains(bundleId) { continue }
                            
                            let category = savedCategories[bundleId]
                            let sortOrder = savedSortOrders[bundleId] ?? 0
                            
                            let app = AppInfo(name: name, path: fullPath, bundleIdentifier: bundleId, category: category, sortOrder: sortOrder)
                            
                            // 确保应用名称不为空且路径有效
                            if !app.name.isEmpty && fileManager.fileExists(atPath: app.path) {
                                foundApps.append(app)
                            }
                        }
                    }
                } catch {
                    print("Error scanning \(dir): \(error)")
                }
            }
            
            print("Found \(foundApps.count) valid apps.")
            
            // 初始排序：先按自定义排序权重，再按名称字母顺序
            foundApps.sort { (a, b) -> Bool in
                if a.sortOrder != b.sortOrder {
                    return a.sortOrder < b.sortOrder
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            
            // 组织网格显示项
            var items: [LaunchpadItem] = []
            var appsInFolders = [String: UUID]() // appId: folderId，记录哪些应用在文件夹中
            
            // 首先添加文件夹到网格
            for folder in savedFolders {
                items.append(.folder(folder))
                for appId in folder.appIds {
                    appsInFolders[appId] = folder.id
                }
            }
            
            var finalFoundApps: [AppInfo] = []
            for var app in foundApps {
                // 如果应用属于某个文件夹，更新其 folderId
                if let folderId = appsInFolders[app.id] {
                    app.folderId = folderId
                }
                finalFoundApps.append(app)
                
                // 如果应用不属于任何文件夹，则直接添加到顶层网格
                if appsInFolders[app.id] == nil {
                    items.append(.app(app))
                }
            }
            
            // 对顶层项进行排序（文件夹排在前面，然后是应用）
            items.sort { (a, b) -> Bool in
                switch (a, b) {
                case (.folder, .app): return true
                case (.app, .folder): return false
                default: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
            
            let finalApps = finalFoundApps
            let finalFolders = savedFolders
            let finalItems = items
            
            // 在主线程更新 UI
            await MainActor.run {
                self.apps = finalApps
                self.folders = finalFolders
                self.gridItems = finalItems
                self.isLoading = false
                self.isScanning = false
                self.hasScanned = true
            }
        }
    }
    
    // 隐藏应用
    func hide(app: AppInfo) {
        guard let bundleId = app.bundleIdentifier else { return }
        var hidden = settings.hiddenAppBundleIds
        hidden.insert(bundleId)
        settings.hiddenAppBundleIds = hidden
        scan(force: true) // 刷新列表
    }
    
    // 取消隐藏应用
    func unhide(bundleId: String) {
        var hidden = settings.hiddenAppBundleIds
        hidden.remove(bundleId)
        settings.hiddenAppBundleIds = hidden
        scan(force: true) // 刷新列表
    }
    
    // 创建文件夹并添加两个应用
    func createFolder(with app1: AppInfo, and app2: AppInfo, name: String = "New Folder") {
        let folder = FolderInfo(name: name, appIds: [app1.id, app2.id])
        var currentFolders = settings.folders
        currentFolders.append(folder)
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 将应用添加到现有文件夹
    func addToFolder(app: AppInfo, folderId: UUID) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            if !currentFolders[index].appIds.contains(app.id) {
                currentFolders[index].appIds.append(app.id)
            }
        }
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 从文件夹中移除应用
    func removeFromFolder(appId: String, folderId: UUID) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].appIds.removeAll(where: { $0 == appId })
            // 如果文件夹变空，则删除该文件夹
            if currentFolders[index].appIds.isEmpty {
                currentFolders.remove(at: index)
            }
        }
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 重命名文件夹
    func renameFolder(folderId: UUID, newName: String) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].name = newName
        }
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 删除文件夹
    func deleteFolder(folderId: UUID) {
        var currentFolders = settings.folders
        currentFolders.removeAll(where: { $0.id == folderId })
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 设置应用分类
    func setCategory(for bundleId: String, category: String?) {
        var currentCategories = settings.categories
        currentCategories[bundleId] = category
        settings.categories = currentCategories
        scan(force: true)
    }
    
    // 设置应用排序权重
    func setSortOrder(for bundleId: String, order: Int) {
        var currentOrders = settings.sortOrders
        currentOrders[bundleId] = order
        settings.sortOrders = currentOrders
        scan(force: true)
    }
    
    // 批量移动应用到文件夹
    func moveAppsToFolder(appIds: Set<String>, folderId: UUID) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            for appId in appIds {
                if !currentFolders[index].appIds.contains(appId) {
                    currentFolders[index].appIds.append(appId)
                }
            }
        }
        settings.folders = currentFolders
        scan(force: true)
    }
    
    // 启动应用
    func launch(app: AppInfo) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}

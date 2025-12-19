import Foundation
import AppKit

class AppDiscovery: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var folders: [FolderInfo] = []
    @Published var gridItems: [LaunchpadItem] = []
    @Published var isLoading = false
    private var isScanning = false
    var hasScanned = false
    
    private let settings = SettingsManager.shared
    
    func scan(force: Bool = false) {
        if isScanning { return }
        if !force && hasScanned { return }
        
        print("Starting app scan (force: \(force))...")
        isScanning = true
        isLoading = true
        
        Task {
            let hiddenIds = self.settings.hiddenAppBundleIds
            let savedFolders = self.settings.folders
            let savedCategories = self.settings.categories
            let savedSortOrders = self.settings.sortOrders
            
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
                            
                            if hiddenIds.contains(bundleId) { continue }
                            
                            let category = savedCategories[bundleId]
                            let sortOrder = savedSortOrders[bundleId] ?? 0
                            
                            let app = AppInfo(name: name, path: fullPath, bundleIdentifier: bundleId, category: category, sortOrder: sortOrder)
                            foundApps.append(app)
                        }
                    }
                } catch {
                    print("Error scanning \(dir): \(error)")
                }
            }
            
            // Initial sort by custom order, then by name
            foundApps.sort { (a, b) -> Bool in
                if a.sortOrder != b.sortOrder {
                    return a.sortOrder < b.sortOrder
                }
                return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
            }
            
            // Organize into grid items
            var items: [LaunchpadItem] = []
            var appsInFolders = Set<String>()
            
            for folder in savedFolders {
                items.append(.folder(folder))
                appsInFolders.formUnion(folder.appIds)
            }
            
            for app in foundApps {
                if !appsInFolders.contains(app.id) {
                    items.append(.app(app))
                }
            }
            
            // Sort top-level items (folders first, then apps)
            items.sort { (a, b) -> Bool in
                switch (a, b) {
                case (.folder, .app): return true
                case (.app, .folder): return false
                default: return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
                }
            }
            
            let finalApps = foundApps
            let finalFolders = savedFolders
            let finalItems = items
            
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
    
    func hide(app: AppInfo) {
        guard let bundleId = app.bundleIdentifier else { return }
        var hidden = settings.hiddenAppBundleIds
        hidden.insert(bundleId)
        settings.hiddenAppBundleIds = hidden
        scan(force: true) // Refresh
    }
    
    func unhide(bundleId: String) {
        var hidden = settings.hiddenAppBundleIds
        hidden.remove(bundleId)
        settings.hiddenAppBundleIds = hidden
        scan(force: true) // Refresh
    }
    
    func createFolder(with app1: AppInfo, and app2: AppInfo, name: String = "New Folder") {
        let folder = FolderInfo(name: name, appIds: [app1.id, app2.id])
        var currentFolders = settings.folders
        currentFolders.append(folder)
        settings.folders = currentFolders
        scan(force: true) // Refresh
    }
    
    func addToFolder(app: AppInfo, folderId: UUID) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            if !currentFolders[index].appIds.contains(app.id) {
                currentFolders[index].appIds.append(app.id)
            }
        }
        settings.folders = currentFolders
        scan(force: true) // Refresh
    }
    
    func removeFromFolder(appId: String, folderId: UUID) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].appIds.removeAll(where: { $0 == appId })
            if currentFolders[index].appIds.isEmpty {
                currentFolders.remove(at: index)
            }
        }
        settings.folders = currentFolders
        scan(force: true) // Refresh
    }
    
    func renameFolder(folderId: UUID, newName: String) {
        var currentFolders = settings.folders
        if let index = currentFolders.firstIndex(where: { $0.id == folderId }) {
            currentFolders[index].name = newName
        }
        settings.folders = currentFolders
        scan(force: true) // Refresh
    }
    
    func deleteFolder(folderId: UUID) {
        var currentFolders = settings.folders
        currentFolders.removeAll(where: { $0.id == folderId })
        settings.folders = currentFolders
        scan(force: true) // Refresh
    }
    
    func setCategory(for bundleId: String, category: String?) {
        var currentCategories = settings.categories
        currentCategories[bundleId] = category
        settings.categories = currentCategories
        scan(force: true)
    }
    
    func setSortOrder(for bundleId: String, order: Int) {
        var currentOrders = settings.sortOrders
        currentOrders[bundleId] = order
        settings.sortOrders = currentOrders
        scan(force: true)
    }
    
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
    
    func launch(app: AppInfo) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}

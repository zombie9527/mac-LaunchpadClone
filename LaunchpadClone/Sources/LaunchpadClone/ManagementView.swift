import SwiftUI

// 应用管理视图：提供批量隐藏、分类设置和文件夹管理功能
struct ManagementView: View {
    @ObservedObject var discovery: AppDiscovery
    @ObservedObject var settings = SettingsManager.shared
    @State private var selection = Set<String>()     // 当前选中的应用 ID 集合
    @State private var searchText = ""               // 搜索文本
    @State private var showFolderSheet = false       // 是否显示新建文件夹弹窗
    @State private var newFolderName = ""            // 新文件夹名称
    @State private var selectedCategory = "All"      // 当前选中的分类过滤项
    
    // 获取所有已存在的分类列表
    var categories: [String] {
        let allCategories = Set(discovery.apps.compactMap { $0.category })
        return ["All"] + Array(allCategories).sorted()
    }
    
    // 根据搜索和分类过滤后的应用列表
    var filteredApps: [AppInfo] {
        discovery.apps.filter { app in
            let matchesSearch = searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || app.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部工具栏
            HStack {
                // 搜索框
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                // 分类过滤器
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .frame(width: 150)
                
                Spacer()
                
                // 创建文件夹按钮
                Button("Create Folder") {
                    showFolderSheet = true
                }
                .disabled(selection.isEmpty)
                
                // 移动到现有文件夹菜单
                Menu("Move to Folder") {
                    ForEach(discovery.folders) { folder in
                        Button(folder.name) {
                            discovery.moveAppsToFolder(appIds: selection, folderId: folder.id)
                            selection.removeAll()
                        }
                    }
                }
                .disabled(selection.isEmpty || discovery.folders.isEmpty)
                
                // 设置分类菜单
                Menu("Set Category") {
                    Button("New Category...") {
                        showCategoryAlert()
                    }
                    Divider()
                    ForEach(categories.filter { $0 != "All" }, id: \.self) { cat in
                        Button(cat) {
                            batchSetCategory(cat)
                        }
                    }
                    Button("Clear Category") {
                        batchSetCategory(nil)
                    }
                }
                .disabled(selection.isEmpty)
                
                // 批量隐藏按钮
                Button("Hide Selected") {
                    batchHide()
                }
                .disabled(selection.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // 应用列表（支持多选）
            List(filteredApps, selection: $selection) { app in
                HStack {
                    AsyncIconView(path: app.path)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading) {
                        Text(app.name).font(.headline)
                        Text(app.bundleIdentifier ?? "No Bundle ID").font(.caption).foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // 显示当前分类标签
                    if let category = app.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(5)
                    }
                    
                    // 显示当前所属文件夹标签
                    if let folderId = app.folderId, let folder = discovery.folders.first(where: { $0.id == folderId }) {
                        Text(folder.name)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(5)
                    }
                }
            }
            
            // 底部状态栏
            HStack {
                Text("\(selection.count) apps selected")
                Spacer()
                Button("Done") {
                    NSApp.keyWindow?.close()
                }
            }
            .padding()
        }
        .frame(minWidth: 800, minHeight: 500)
        .sheet(isPresented: $showFolderSheet) {
            // 新建文件夹弹窗
            VStack {
                Text("Create New Folder").font(.headline)
                TextField("Folder Name", text: $newFolderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                HStack {
                    Button("Cancel") { showFolderSheet = false }
                    Button("Create") {
                        createFolderFromSelection()
                        showFolderSheet = false
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                }
            }
            .padding()
            .frame(width: 300)
        }
    }
    
    // 批量隐藏选中的应用
    private func batchHide() {
        for id in selection {
            if let app = discovery.apps.first(where: { $0.id == id }) {
                discovery.hide(app: app)
            }
        }
        selection.removeAll()
    }
    
    // 批量设置选中应用的分类
    private func batchSetCategory(_ category: String?) {
        for id in selection {
            if let app = discovery.apps.first(where: { $0.id == id }), let bundleId = app.bundleIdentifier {
                discovery.setCategory(for: bundleId, category: category)
            }
        }
        selection.removeAll()
        discovery.scan(force: true)
    }
    
    // 显示输入新分类名称的系统弹窗
    private func showCategoryAlert() {
        let alert = NSAlert()
        alert.messageText = "New Category"
        alert.informativeText = "Enter a name for the new category:"
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        alert.accessoryView = input
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            let catName = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if !catName.isEmpty {
                batchSetCategory(catName)
            }
        }
    }
    
    // 根据当前选中的应用创建新文件夹
    private func createFolderFromSelection() {
        let selectedApps = discovery.apps.filter { selection.contains($0.id) }
        guard !selectedApps.isEmpty else { return }
        
        let folder = FolderInfo(name: newFolderName, appIds: Array(selection))
        var currentFolders = settings.folders
        currentFolders.append(folder)
        settings.folders = currentFolders
        discovery.scan(force: true)
        selection.removeAll()
    }
}

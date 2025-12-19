import SwiftUI

struct ManagementView: View {
    @ObservedObject var discovery: AppDiscovery
    @ObservedObject var settings = SettingsManager.shared
    @State private var selection = Set<String>()
    @State private var searchText = ""
    @State private var showFolderSheet = false
    @State private var newFolderName = ""
    @State private var selectedCategory = "All"
    
    var categories: [String] {
        let allCategories = Set(discovery.apps.compactMap { $0.category })
        return ["All"] + Array(allCategories).sorted()
    }
    
    var filteredApps: [AppInfo] {
        discovery.apps.filter { app in
            let matchesSearch = searchText.isEmpty || app.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == "All" || app.category == selectedCategory
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                TextField("Search apps...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 200)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(categories, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
                .frame(width: 150)
                
                Spacer()
                
                Button("Create Folder") {
                    showFolderSheet = true
                }
                .disabled(selection.isEmpty)
                
                Menu("Move to Folder") {
                    ForEach(discovery.folders) { folder in
                        Button(folder.name) {
                            discovery.moveAppsToFolder(appIds: selection, folderId: folder.id)
                            selection.removeAll()
                        }
                    }
                }
                .disabled(selection.isEmpty || discovery.folders.isEmpty)
                
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
                
                Button("Hide Selected") {
                    batchHide()
                }
                .disabled(selection.isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // App List
            List(filteredApps, selection: $selection) { app in
                HStack {
                    AsyncIconView(path: app.path)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading) {
                        Text(app.name).font(.headline)
                        Text(app.bundleIdentifier ?? "No Bundle ID").font(.caption).foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let category = app.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(5)
                    }
                    
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
            
            // Footer
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
    
    private func batchHide() {
        for id in selection {
            if let app = discovery.apps.first(where: { $0.id == id }) {
                discovery.hide(app: app)
            }
        }
        selection.removeAll()
    }
    
    private func batchSetCategory(_ category: String?) {
        for id in selection {
            if let app = discovery.apps.first(where: { $0.id == id }), let bundleId = app.bundleIdentifier {
                discovery.setCategory(for: bundleId, category: category)
            }
        }
        selection.removeAll()
        discovery.scan(force: true)
    }
    
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

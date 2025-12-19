import SwiftUI

struct LaunchpadView: View {
    @StateObject var discovery = AppDiscovery()
    @ObservedObject var settings = SettingsManager.shared
    @State private var searchText = ""
    @State private var showSettings = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)
    ]
    
    var filteredItems: [LaunchpadItem] {
        if searchText.isEmpty {
            return discovery.gridItems
        } else {
            return discovery.gridItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // Background Layer
            Group {
                if !settings.backgroundImagePath.isEmpty, let image = NSImage(contentsOfFile: settings.backgroundImagePath) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                }
            }
            .ignoresSafeArea()
            .overlay(Color.black.opacity(1.0 - settings.backgroundOpacity))
            .blur(radius: settings.backgroundBlur)
            
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Spacer()
                    
                    HStack(spacing: 15) {
                        // Search Bar (Shortened)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.title3)
                        }
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: 300)
                        
                        // Refresh Button
                        Button(action: { discovery.scan(force: true) }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .foregroundColor(settings.textColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Refresh App List")
                        
                        // Management Button
                        Button(action: { openManagementWindow() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet.circle.fill")
                                Text("Manage")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(8)
                            .foregroundColor(settings.textColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Open App Management")
                        
                        // Settings Button
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(settings.textColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .popover(isPresented: $showSettings) {
                            SettingsView(settings: settings, discovery: discovery)
                                .frame(width: 300)
                                .padding()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                
                if discovery.isLoading {
                    Spacer()
                    ProgressView("Loading Apps...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(filteredItems) { item in
                                switch item {
                                case .app(let app):
                                    AppIconView(app: app, textColor: settings.textColor, onHide: {
                                        discovery.hide(app: app)
                                    }) {
                                        discovery.launch(app: app)
                                    }
                                    
                                case .folder(let folder):
                                    FolderIconView(folder: folder, textColor: settings.textColor, discovery: discovery)
                                }
                            }
                        }
                        .padding(30)
                    }
                }
            }
        }
        .onAppear {
            discovery.scan()
        }
    }
    
    private func openManagementWindow() {
        if let existingWindow = NSApp.windows.first(where: { $0.title == "App Management" }) {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let managementView = ManagementView(discovery: discovery)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.center()
        window.title = "App Management"
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: managementView)
        window.makeKeyAndOrderFront(nil)
    }
}

// Remove AppDropDelegate as it's no longer used


struct FolderIconView: View {
    let folder: FolderInfo
    let textColor: Color
    let discovery: AppDiscovery
    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var isRenaming = false
    @State private var newName = ""
    
    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            VStack {
                // Folder Icon (Mini grid)
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 80, height: 80)
                    
                    let appsInFolder = discovery.apps.filter { folder.appIds.contains($0.id) }
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                        ForEach(appsInFolder.prefix(9)) { app in
                            AsyncIconView(path: app.path)
                                .frame(width: 18, height: 18)
                        }
                    }
                    .padding(8)
                }
                .shadow(radius: isHovered ? 10 : 2)
                .scaleEffect(isHovered ? 1.05 : 1.0)
                
                Text(folder.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .frame(maxWidth: 100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Rename Folder") {
                newName = folder.name
                isRenaming = true
            }
            Button("Delete Folder", role: .destructive) {
                discovery.deleteFolder(folderId: folder.id)
            }
        }
        .alert("Rename Folder", isPresented: $isRenaming) {
            TextField("New Name", text: $newName)
            Button("Cancel", role: .cancel) { }
            Button("Rename") {
                discovery.renameFolder(folderId: folder.id, newName: newName)
            }
        }
        .onHover { hovering in
            withAnimation(.spring()) {
                isHovered = hovering
            }
        }
        .sheet(isPresented: $isExpanded) {
            FolderDetailView(folder: folder, discovery: discovery, textColor: textColor)
        }
    }
}

struct FolderDetailView: View {
    let folder: FolderInfo
    @ObservedObject var discovery: AppDiscovery
    let textColor: Color
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            HStack {
                Text(folder.name)
                    .font(.title).bold()
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.return)
            }
            .padding()
            
            let appsInFolder = discovery.apps.filter { folder.appIds.contains($0.id) }
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)], spacing: 30) {
                    ForEach(appsInFolder) { app in
                        AppIconView(app: app, textColor: .white, onHide: {
                            discovery.hide(app: app)
                        }) {
                            discovery.launch(app: app)
                            dismiss()
                        }
                        .contextMenu {
                            Button("Remove from Folder") {
                                discovery.removeFromFolder(appId: app.id, folderId: folder.id)
                            }
                            Button("Hide App") {
                                discovery.hide(app: app)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var discovery: AppDiscovery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Customization")
                .font(.headline)
            
            Divider()
            
            Group {
                ColorPicker("Text Color", selection: $settings.textColor)
                
                VStack(alignment: .leading) {
                    Text("Background Opacity: \(settings.backgroundOpacity, specifier: "%.2f")")
                    Slider(value: $settings.backgroundOpacity, in: 0...1)
                }
                
                VStack(alignment: .leading) {
                    Text("Background Blur: \(settings.backgroundBlur, specifier: "%.0f")")
                    Slider(value: $settings.backgroundBlur, in: 0...50)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Background Image Path")
                HStack {
                    TextField("Path to image...", text: $settings.backgroundImagePath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Clear") {
                        settings.backgroundImagePath = ""
                    }
                }
            }
            
            Divider()
            
            VStack(alignment: .leading) {
                Text("Hidden Apps")
                    .font(.subheadline).bold()
                
                if settings.hiddenAppBundleIds.isEmpty {
                    Text("No hidden apps").font(.caption).foregroundColor(.secondary)
                } else {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(Array(settings.hiddenAppBundleIds).sorted(), id: \.self) { bundleId in
                                HStack {
                                    Text(bundleId).font(.caption).lineLimit(1)
                                    Spacer()
                                    Button("Restore") {
                                        discovery.unhide(bundleId: bundleId)
                                    }
                                    .buttonStyle(LinkButtonStyle())
                                }
                            }
                        }
                    }
                    .frame(height: 100)
                }
            }
            
            Text("Tip: Right-click an app to hide it.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AppIconView: View {
    let app: AppInfo
    let textColor: Color
    let onHide: () -> Void
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack {
                AsyncIconView(path: app.path)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .shadow(radius: isHovered ? 10 : 2)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                
                Text(app.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                    .frame(maxWidth: 100)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button("Hide App") {
                onHide()
            }
        }
        .onHover { hovering in
            withAnimation(.spring()) {
                isHovered = hovering
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

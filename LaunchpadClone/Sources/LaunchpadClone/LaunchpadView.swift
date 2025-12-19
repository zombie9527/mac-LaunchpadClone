import SwiftUI

// Launchpad 主视图
struct LaunchpadView: View {
    @StateObject var discovery = AppDiscovery()      // 应用发现逻辑
    @ObservedObject var settings = SettingsManager.shared // 用户设置
    @State private var searchText = ""               // 搜索文本
    @State private var showSettings = false          // 是否显示设置弹窗
    
    // 网格布局定义：自适应宽度，最小 100，最大 120
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)
    ]
    
    // 根据搜索文本过滤后的显示项
    var filteredItems: [LaunchpadItem] {
        if searchText.isEmpty {
            return discovery.gridItems
        } else {
            return discovery.gridItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            // 背景层
            Group {
                if !settings.backgroundImagePath.isEmpty, let image = NSImage(contentsOfFile: settings.backgroundImagePath) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    // 默认使用系统毛玻璃效果
                    VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                }
            }
            .ignoresSafeArea()
            .overlay(Color.black.opacity(1.0 - settings.backgroundOpacity)) // 叠加透明度层
            .blur(radius: settings.backgroundBlur)                         // 背景模糊
            
            VStack(spacing: 0) {
                // 顶部状态栏
                HStack {
                    // 退出按钮
                    Button(action: { NSApp.terminate(nil) }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(settings.textColor.opacity(0.5))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading)
                    .help("Quit App")
                    
                    Spacer()
                    
                    HStack(spacing: 15) {
                        // 搜索框
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Search", text: $searchText)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.title3)
                        }
                        .padding(6)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(10)
                        .frame(maxWidth: 300)
                        
                        // 刷新按钮
                        Button(action: { discovery.scan(force: true) }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title3)
                                .foregroundColor(settings.textColor)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .help("Refresh App List")
                        
                        // 管理按钮：打开独立的应用管理窗口
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
                        
                        // 设置按钮：显示气泡弹窗
                        Button(action: { showSettings.toggle() }) {
                            Image(systemName: "gearshape.fill")
                                .font(.title3)
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
                    
                    // 占位符，保持顶部栏左右平衡
                    Color.clear.frame(width: 40, height: 50)
                }
                .padding(.top, 10)
                .padding(.horizontal)
                .padding(.bottom, 5)
                
                // 内容区域
                if discovery.isLoading {
                    Spacer()
                    ProgressView("Loading Apps...")
                    Spacer()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // 应用网格
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)], spacing: 40) {
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
                            .padding(.horizontal, 40)
                            .padding(.top, 0)
                            .padding(.bottom, 60)
                            
                            Spacer(minLength: 0)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
                
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
        }
        .onAppear {
            discovery.scan() // 视图出现时开始扫描应用
        }
    }
    
    // 打开应用管理窗口
    private func openManagementWindow() {
        // 如果窗口已打开，则将其置于最前
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
        window.level = .mainMenu + 2
        window.makeKeyAndOrderFront(nil)
    }
}

// 文件夹图标视图
struct FolderIconView: View {
    let folder: FolderInfo
    let textColor: Color
    let discovery: AppDiscovery
    @State private var isHovered = false         // 鼠标悬停状态
    @State private var isExpanded = false        // 是否展开文件夹详情
    @State private var isRenaming = false        // 是否正在重命名
    @State private var newName = ""              // 新名称
    
    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            VStack {
                // 文件夹图标（九宫格预览）
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
            // 右键菜单
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
            // 展开文件夹详情视图
            FolderDetailView(folder: folder, discovery: discovery, textColor: textColor)
        }
    }
}

// 文件夹详情视图（点击文件夹后显示的弹窗）
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

// 设置视图
struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    @ObservedObject var discovery: AppDiscovery
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Customization")
                .font(.headline)
            
            Divider()
            
            Group {
                // 颜色选择器
                ColorPicker("Text Color", selection: $settings.textColor)
                
                // 背景透明度调节
                VStack(alignment: .leading) {
                    Text("Background Opacity: \(settings.backgroundOpacity, specifier: "%.2f")")
                    Slider(value: $settings.backgroundOpacity, in: 0...1)
                }
                
                // 背景模糊度调节
                VStack(alignment: .leading) {
                    Text("Background Blur: \(settings.backgroundBlur, specifier: "%.0f")")
                    Slider(value: $settings.backgroundBlur, in: 0...50)
                }
            }
            
            Divider()
            
            // 背景图片路径设置
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
            
            // 已隐藏应用列表
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

// 单个应用图标视图
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

// macOS 毛玻璃效果包装类
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

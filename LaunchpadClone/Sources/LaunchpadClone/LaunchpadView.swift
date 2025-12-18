import SwiftUI

struct LaunchpadView: View {
    @StateObject var discovery = AppDiscovery()
    @StateObject var settings = SettingsManager.shared
    @State private var searchText = ""
    @State private var showSettings = false
    
    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 20)
    ]
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return discovery.apps
        } else {
            return discovery.apps.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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
                    // Search Bar
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
                    
                    // Settings Button
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(settings.textColor)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $showSettings) {
                        SettingsView(settings: settings)
                            .frame(width: 300)
                            .padding()
                    }
                }
                .padding()
                
                if discovery.isLoading {
                    Spacer()
                    ProgressView("Loading Apps...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 30) {
                            ForEach(filteredApps) { app in
                                AppIconView(app: app, textColor: settings.textColor) {
                                    discovery.launch(app: app)
                                }
                            }
                        }
                        .padding(30)
                    }
                }
            }
        }
        .onAppear {
            print("LaunchpadView appeared.")
            discovery.scan()
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: SettingsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Customization")
                .font(.headline)
            
            Divider()
            
            ColorPicker("Text Color", selection: $settings.textColor)
            
            VStack(alignment: .leading) {
                Text("Background Opacity: \(settings.backgroundOpacity, specifier: "%.2f")")
                Slider(value: $settings.backgroundOpacity, in: 0...1)
            }
            
            VStack(alignment: .leading) {
                Text("Background Blur: \(settings.backgroundBlur, specifier: "%.0f")")
                Slider(value: $settings.backgroundBlur, in: 0...50)
            }
            
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
            
            Text("Tip: You can drag an image file here to get its path (if supported) or paste the full path.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AppIconView: View {
    let app: AppInfo
    let textColor: Color
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

import SwiftUI

struct LaunchpadView: View {
    @StateObject var discovery = AppDiscovery()
    @State private var searchText = ""
    
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
        VStack(spacing: 0) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.title3)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(10)
            .padding()
            
            if discovery.isLoading {
                Spacer()
                ProgressView("Loading Apps...")
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 30) {
                        ForEach(filteredApps) { app in
                            AppIconView(app: app) {
                                discovery.launch(app: app)
                            }
                        }
                    }
                    .padding(30)
                }
            }
        }
        .background(VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow).ignoresSafeArea())
        .onAppear {
            print("LaunchpadView appeared.")
            discovery.scan()
        }
    }
}

struct AppIconView: View {
    let app: AppInfo
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
                    .foregroundColor(.white)
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

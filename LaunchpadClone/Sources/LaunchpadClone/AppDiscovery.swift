import Foundation
import AppKit

class AppDiscovery: ObservableObject {
    @Published var apps: [AppInfo] = []
    @Published var isLoading = false
    
    func scan() {
        print("Starting app scan...")
        isLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            let appDirs = ["/Applications", "/System/Applications", "\(NSHomeDirectory())/Applications"]
            let fileManager = FileManager.default
            var foundApps: [AppInfo] = []
            
            for dir in appDirs {
                print("Scanning directory: \(dir)")
                do {
                    let contents = try fileManager.contentsOfDirectory(atPath: dir)
                    print("Found \(contents.count) items in \(dir)")
                    for item in contents {
                        if item.hasSuffix(".app") {
                            let fullPath = (dir as NSString).appendingPathComponent(item)
                            let name = (item as NSString).deletingPathExtension
                            let bundle = Bundle(path: fullPath)
                            let bundleId = bundle?.bundleIdentifier
                            
                            let app = AppInfo(name: name, path: fullPath, bundleIdentifier: bundleId)
                            foundApps.append(app)
                        }
                    }
                } catch {
                    print("Error scanning \(dir): \(error)")
                }
            }
            
            // Sort apps by name
            foundApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            print("Scan complete. Found \(foundApps.count) apps.")
            
            DispatchQueue.main.async {
                self.apps = foundApps
                self.isLoading = false
            }
        }
    }
    
    func launch(app: AppInfo) {
        let url = URL(fileURLWithPath: app.path)
        NSWorkspace.shared.open(url)
    }
}

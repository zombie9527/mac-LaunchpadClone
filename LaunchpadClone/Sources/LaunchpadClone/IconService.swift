import Foundation
import AppKit
import SwiftUI

class IconService {
    static let shared = IconService()
    private var cache = NSCache<NSString, NSImage>()
    
    func icon(for path: String) -> NSImage {
        if let cachedIcon = cache.object(forKey: path as NSString) {
            return cachedIcon
        }
        
        let icon = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(icon, forKey: path as NSString)
        return icon
    }
}

struct AsyncIconView: View {
    let path: String
    @State private var icon: NSImage?
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
            } else {
                Color.gray.opacity(0.2)
                    .onAppear {
                        loadIcon()
                    }
            }
        }
    }
    
    private func loadIcon() {
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedIcon = IconService.shared.icon(for: path)
            DispatchQueue.main.async {
                self.icon = loadedIcon
            }
        }
    }
}

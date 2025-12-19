import Foundation
import AppKit
import SwiftUI

// 图标服务类，负责获取和缓存应用图标
class IconService {
    static let shared = IconService()
    private var cache = NSCache<NSString, NSImage>() // 图标缓存，避免重复从磁盘读取
    
    // 根据路径获取应用图标
    func icon(for path: String) -> NSImage {
        // 如果缓存中有，直接返回
        if let cachedIcon = cache.object(forKey: path as NSString) {
            return cachedIcon
        }
        
        // 否则从系统工作区获取图标并存入缓存
        let icon = NSWorkspace.shared.icon(forFile: path)
        cache.setObject(icon, forKey: path as NSString)
        return icon
    }
}

// 异步图标视图，用于在 UI 中非阻塞地加载图标
struct AsyncIconView: View {
    let path: String                             // 应用路径
    @State private var icon: NSImage?            // 加载后的图标
    
    var body: some View {
        Group {
            if let icon = icon {
                Image(nsImage: icon)
                    .resizable()
            } else {
                // 加载中显示灰色占位块
                Color.gray.opacity(0.2)
                    .onAppear {
                        loadIcon()
                    }
            }
        }
    }
    
    // 异步加载图标
    private func loadIcon() {
        Task {
            let loadedIcon = IconService.shared.icon(for: path)
            await MainActor.run {
                self.icon = loadedIcon
            }
        }
    }
}

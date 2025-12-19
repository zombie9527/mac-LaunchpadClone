import SwiftUI

// 设置管理类，负责持久化存储用户的自定义配置
class SettingsManager: ObservableObject {
    // 使用 @AppStorage 自动将属性持久化到 UserDefaults
    @AppStorage("textColorHex") var textColorHex: String = "#FFFFFF"        // 文字颜色（十六进制）
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.8    // 背景透明度
    @AppStorage("backgroundBlur") var backgroundBlur: Double = 20.0        // 背景模糊度
    @AppStorage("backgroundImagePath") var backgroundImagePath: String = "" // 背景图片路径
    
    // 复杂数据类型（Set, Array, Dictionary）需要先转为 Data 存储
    @AppStorage("hiddenAppBundleIds") var hiddenAppBundleIdsData: Data = Data() // 隐藏的应用 ID
    @AppStorage("foldersData") var foldersData: Data = Data()                   // 文件夹数据
    @AppStorage("categoriesData") var categoriesData: Data = Data()             // 分类数据
    @AppStorage("sortOrdersData") var sortOrdersData: Data = Data()             // 排序权重数据
    
    // 计算属性：方便在 UI 中直接使用 Color 对象
    var textColor: Color {
        get { Color(hex: textColorHex) ?? .white }
        set { textColorHex = newValue.toHex() ?? "#FFFFFF" }
    }
    
    // 计算属性：自动处理 JSON 编解码
    var hiddenAppBundleIds: Set<String> {
        get { (try? JSONDecoder().decode(Set<String>.self, from: hiddenAppBundleIdsData)) ?? [] }
        set { hiddenAppBundleIdsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    var folders: [FolderInfo] {
        get { (try? JSONDecoder().decode([FolderInfo].self, from: foldersData)) ?? [] }
        set { foldersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    var categories: [String: String] {
        get { (try? JSONDecoder().decode([String: String].self, from: categoriesData)) ?? [:] }
        set { categoriesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    var sortOrders: [String: Int] {
        get { (try? JSONDecoder().decode([String: Int].self, from: sortOrdersData)) ?? [:] }
        set { sortOrdersData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
    
    static let shared = SettingsManager()
}

// Color 扩展：支持十六进制字符串转换
extension Color {
    // 从十六进制字符串创建 Color (支持 #RRGGBB 或 #RRGGBBAA)
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexSanitized.hasPrefix("#") {
            hexSanitized.remove(at: hexSanitized.startIndex)
        }
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r, g, b, a: Double
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if hexSanitized.count == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
    
    // 将 Color 转换为十六进制字符串
    func toHex() -> String? {
        let nsColor = NSColor(self).usingColorSpace(.sRGB)
        guard let r = nsColor?.redComponent,
              let g = nsColor?.greenComponent,
              let b = nsColor?.blueComponent else { return nil }
        
        let a = nsColor?.alphaComponent ?? 1.0
        
        if a == 1.0 {
            return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
        } else {
            return String(format: "#%02X%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255), Int(a * 255))
        }
    }
}

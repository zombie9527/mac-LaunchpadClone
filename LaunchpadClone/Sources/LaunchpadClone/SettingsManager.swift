import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("textColorHex") var textColorHex: String = "#FFFFFF"
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.8
    @AppStorage("backgroundBlur") var backgroundBlur: Double = 20.0
    @AppStorage("backgroundImagePath") var backgroundImagePath: String = ""
    
    @AppStorage("hiddenAppBundleIds") var hiddenAppBundleIdsData: Data = Data()
    @AppStorage("foldersData") var foldersData: Data = Data()
    @AppStorage("categoriesData") var categoriesData: Data = Data()
    @AppStorage("sortOrdersData") var sortOrdersData: Data = Data()
    
    var textColor: Color {
        get { Color(hex: textColorHex) ?? .white }
        set { textColorHex = newValue.toHex() ?? "#FFFFFF" }
    }
    
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

extension Color {
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

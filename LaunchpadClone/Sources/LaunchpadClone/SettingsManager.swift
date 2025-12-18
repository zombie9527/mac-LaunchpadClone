import SwiftUI

class SettingsManager: ObservableObject {
    @AppStorage("textColor") var textColor: Color = .white
    @AppStorage("backgroundOpacity") var backgroundOpacity: Double = 0.8
    @AppStorage("backgroundBlur") var backgroundBlur: Double = 20.0
    @AppStorage("backgroundImagePath") var backgroundImagePath: String = ""
    
    static let shared = SettingsManager()
}

// Extension to support Color in AppStorage
extension Color: @retroactive RawRepresentable {
    public init?(rawValue: String) {
        guard let data = Data(base64Encoded: rawValue) else {
            self = .white
            return
        }
        
        do {
            let color = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: data) ?? .white
            self = Color(nsColor: color)
        } catch {
            self = .white
        }
    }

    public var rawValue: String {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: NSColor(self), requiringSecureCoding: false)
            return data.base64EncodedString()
        } catch {
            return ""
        }
    }
}

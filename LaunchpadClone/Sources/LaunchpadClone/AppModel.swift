import Foundation
import AppKit
import SwiftUI

struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let bundleIdentifier: String?
}

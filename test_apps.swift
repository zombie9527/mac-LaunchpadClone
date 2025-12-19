import Foundation
import AppKit

let appDirs = ["/Applications", "/System/Applications", "\(NSHomeDirectory())/Applications"]
let fileManager = FileManager.default

for dir in appDirs {
    print("Scanning: \(dir)")
    do {
        let contents = try fileManager.contentsOfDirectory(atPath: dir)
        for item in contents {
            if item.hasSuffix(".app") {
                let fullPath = (dir as NSString).appendingPathComponent(item)
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                print("Found: \(item) at \(fullPath)")
            }
        }
    } catch {
        print("Error scanning \(dir): \(error)")
    }
}

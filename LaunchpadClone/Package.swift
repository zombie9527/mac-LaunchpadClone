// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LaunchpadClone",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "LaunchpadClone", targets: ["LaunchpadClone"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "LaunchpadClone",
            dependencies: [],
            path: "Sources/LaunchpadClone"
        )
    ]
)

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "XcodeSwitcher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "XcodeSwitcher", path: "Sources/XcodeSwitcher")
    ]
)

// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FileDeck",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FileDeck",
            path: "Sources/FileDeck"
        )
    ]
)

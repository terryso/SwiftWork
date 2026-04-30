// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SwiftWork",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "SwiftWork",
            targets: ["SwiftWork"]
        ),
    ],
    dependencies: [
        // Core SDK for agent capabilities
        .package(
            url: "https://github.com/terryso/open-agent-sdk-swift",
            .upToNextMinor(from: "0.1.0")
        ),
        // Apple's Markdown parsing library
        .package(
            url: "https://github.com/apple/swift-markdown",
            from: "0.5.0"
        ),
        // Code syntax highlighting by John Sundell
        .package(
            url: "https://github.com/JohnSundell/Splash",
            from: "0.9.0"
        ),
        // macOS auto-updater (Phase 4 integration)
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            from: "2.0.0"
        ),
    ],
    targets: [
        .executableTarget(
            name: "SwiftWork",
            dependencies: [
                .product(name: "OpenAgentSDK", package: "open-agent-sdk-swift"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Splash", package: "Splash"),
                .product(name: "Sparkle", package: "Sparkle"),
            ],
            path: "SwiftWork"
        ),
        .testTarget(
            name: "SwiftWorkTests",
            dependencies: ["SwiftWork"],
            path: "SwiftWorkTests"
        ),
    ]
)

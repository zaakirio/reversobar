// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Reversobar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Reversobar",
            path: "Sources/Reversobar",
            resources: [
                .copy("Resources/Flags")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)

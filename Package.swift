// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BigLights",
    defaultLocalization: "zh-Hans",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(
            url: "https://github.com/sparkle-project/Sparkle",
            exact: "2.9.2"
        )
    ],
    targets: [
        .executableTarget(
            name: "BigLights",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/BigLights",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BigLightsTests",
            dependencies: ["BigLights"],
            path: "Tests/BigLightsTests"
        )
    ]
)

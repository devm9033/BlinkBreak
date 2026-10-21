// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BlinkBreak",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "BlinkBreak",
            path: "Sources/BlinkBreak"
        ),
        .testTarget(
            name: "BlinkBreakTests",
            dependencies: ["BlinkBreak"],
            path: "Tests/BlinkBreakTests"
        ),
    ]
)

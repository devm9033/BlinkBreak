// swift-tools-version: 6.0
import PackageDescription
import Foundation

let testingPluginPath = "/Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
let testSwiftSettings: [SwiftSetting] = FileManager.default.fileExists(atPath: testingPluginPath)
    ? [.unsafeFlags(["-load-plugin-library", testingPluginPath])]
    : []

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
            path: "Tests/BlinkBreakTests",
            swiftSettings: testSwiftSettings
        ),
    ]
)

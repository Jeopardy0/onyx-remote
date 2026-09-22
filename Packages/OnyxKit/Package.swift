// swift-tools-version:5.10
import PackageDescription

// The OSC codec (Sources/OnyxKit/OSC) is plain Foundation and builds/tests on
// Linux CI. The transport and adapter (Sources/OnyxKit/Transport,
// OnyxConsoleAdapter.swift) use Network.framework and are wrapped in
// `#if canImport(Network)` so this package still compiles everywhere even
// though only Apple platforms can actually connect to a console.
let package = Package(
    name: "OnyxKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "OnyxKit", targets: ["OnyxKit"])
    ],
    dependencies: [
        .package(path: "../PatchKit"),
        .package(path: "../ConsoleKit")
    ],
    targets: [
        .target(name: "OnyxKit", dependencies: ["PatchKit", "ConsoleKit"]),
        .testTarget(name: "OnyxKitTests", dependencies: ["OnyxKit"])
    ]
)

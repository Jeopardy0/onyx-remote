// swift-tools-version:5.10
import PackageDescription

// Pure Swift — the UI depends only on this protocol, never on OnyxKit or
// Network.framework directly, so it must build/test on Linux CI too.
let package = Package(
    name: "ConsoleKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "ConsoleKit", targets: ["ConsoleKit"])
    ],
    dependencies: [
        .package(path: "../PatchKit")
    ],
    targets: [
        .target(name: "ConsoleKit", dependencies: ["PatchKit"]),
        .testTarget(name: "ConsoleKitTests", dependencies: ["ConsoleKit"])
    ]
)

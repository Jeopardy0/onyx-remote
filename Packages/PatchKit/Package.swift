// swift-tools-version:5.10
import PackageDescription

// Pure Swift, no Apple-only frameworks — must build and test on Linux CI
// as well as macOS/Xcode, per the project's "develop without Xcode" constraint.
let package = Package(
    name: "PatchKit",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [
        .library(name: "PatchKit", targets: ["PatchKit"])
    ],
    targets: [
        .target(name: "PatchKit"),
        .testTarget(name: "PatchKitTests", dependencies: ["PatchKit"])
    ]
)

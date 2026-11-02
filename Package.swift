// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LexcopeCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "LexcopeCore", targets: ["LexcopeCore"])],
    targets: [
        .target(name: "LexcopeCore"),
        .testTarget(name: "LexcopeCoreTests", dependencies: ["LexcopeCore"])
    ]
)

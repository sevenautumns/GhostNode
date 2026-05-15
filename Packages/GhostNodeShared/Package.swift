// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GhostNodeShared",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
    ],
    products: [
        .library(name: "GhostNodeShared", targets: ["GhostNodeShared"]),
    ],
    targets: [
        .target(name: "GhostNodeShared"),
    ]
)

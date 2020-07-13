// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "Hexicon",
    platforms: [.iOS(.v12), .macOS(.v10_15)],
    products: [
        .library(name: "Hexicon", targets: ["Hexicon"]),
        .executable(name: "hexiconj", targets: ["Hexiconjuror"]),
    ],
    dependencies: [
        .package(name: "Commandant", url: "https://github.com/carthage/commandant", from: "0.17.0"),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", .exact("0.50200.0")),
    ],
    targets: [
        .target(name: "Hexicon", dependencies: []),
        .target(name: "Hexiconjuror", dependencies: ["Hexicon", "Commandant", "SwiftSyntax"]),
        .testTarget(name: "HexiconTests", dependencies: ["Hexicon"]),
    ]
)

// swift-tools-version:5.2

import PackageDescription

// tag "swift-5.3-DEVELOPMENT-SNAPSHOT-2020-09-09-a" is the latest
// version which is compatible with Swift 5.3. Actual syntax changes
// are minimal (or even stable?) so the impact of using a dev snapshot
// is presumably minimal.
let swiftSyntaxRevision = "e39d380a1877da137d45cc5dcd23676a3fd00476"

let package = Package(
    name: "Hexicon",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(name: "Hexicon", targets: ["Hexicon"]),
        .executable(name: "hexiconj", targets: ["Hexiconjuror"]),
    ],
    dependencies: [
        .package(name: "Commandant", url: "https://github.com/carthage/commandant", from: "0.17.0"),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", .revision(swiftSyntaxRevision)),
    ],
    targets: [
        .target(name: "Hexicon", dependencies: []),
        .target(name: "Hexiconjuror", dependencies: ["Hexicon", "Commandant", "SwiftSyntax"]),
        .testTarget(name: "HexiconTests", dependencies: ["Hexicon"]),
    ]
)

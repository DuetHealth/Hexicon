# Hexicon

Hexicon for painless localizations.

## Usage

### Installation

### [Swift Package Manager](https://github.com/apple/swift-package-manager)

Create a `Package.swift` file.

```swift
// swift-tools-version:5.2

import PackageDescription

let package = Package(
  name: "TestProject",
  dependencies: [
    .package(url: "https://github.com/DuetHealth/Hexicon.git", from: "1.0.0")
  ],
  targets: [
    .target(name: "TestProject", dependencies: ["Hexicon"])
  ]
)
```

_Coming Soon: Carthage and Cocoapods_

## Install the tool

`swift build -c release && mv .build/release/hexiconj /usr/local/bin`

## License

Hexicon is MIT-licensed. The [MIT license](LICENSE) is included in the root of the repository.


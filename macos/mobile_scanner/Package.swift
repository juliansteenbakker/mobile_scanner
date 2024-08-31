// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "mobile_scanner",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "mobile-scanner", targets: ["mobile_scanner"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "mobile_scanner",
            dependencies: [],
            resources: [
                // To add other resources, see the instructions at
                // https://developer.apple.com/documentation/xcode/bundling-resources-with-a-swift-package
            ]
        )
    ]
)

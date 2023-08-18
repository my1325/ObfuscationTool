// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "SwitchMethod",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "SwitchMethod", targets: ["SwitchMethod"])
    ],
    targets: [
        .target(name: "SwitchMethod")
    ]
)

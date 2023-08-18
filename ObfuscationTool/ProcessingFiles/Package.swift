// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ProcessingFiles",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "ProcessingFiles", targets: ["ProcessingFiles"]),
    ],
    targets: [
        .target(name: "ProcessingFiles"),
    ]
)

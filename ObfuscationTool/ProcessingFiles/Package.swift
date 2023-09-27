// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ProcessingFiles",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "ProcessingFiles", targets: ["ProcessingFiles", "SwiftFilePlugin", "CodeProtocol", "Plugins"]),
    ],
    dependencies: [
        .package(url: "https://github.com/my1325/FilePath.git", .branchItem("main")),
        .package(url: "https://github.com/apple/swift-syntax.git", .branchItem("main")),
    ],
    targets: [
        .target(name: "CodeProtocol"),
        .target(name: "ProcessingFiles", dependencies: [
            "CodeProtocol",
            "FilePath",
        ]),
        .target(name: "SwiftFilePlugin", dependencies: [
            "CodeProtocol",
            "ProcessingFiles",
            "FilePath",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax")
        ]),
        .target(name: "Plugins", dependencies: [
            "CodeProtocol",
            "ProcessingFiles",
            "FilePath",
        ])
    ]
)

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
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: "509.0.0")),
    ],
    targets: [
        .target(name: "CodeProtocol"),
        .target(name: "ProcessingFiles", dependencies: [
            "CodeProtocol",
            "PathKit",
        ]),
        .target(name: "SwiftFilePlugin", dependencies: [
            "CodeProtocol",
            "ProcessingFiles",
            "PathKit",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
            .product(name: "SwiftParser", package: "swift-syntax")
        ]),
        .target(name: "Plugins", dependencies: [
            "CodeProtocol",
            "ProcessingFiles",
            "SwiftFilePlugin",
            "PathKit",
        ])
    ]
)

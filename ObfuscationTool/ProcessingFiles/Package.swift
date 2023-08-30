// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "ProcessingFiles",
    platforms: [.macOS(.v10_13)],
    products: [
        .library(name: "ProcessingFiles", targets: ["ProcessingFiles", "SwiftFilePlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/my1325/FilePath.git", .branchItem("main")),
        .package(url: "https://github.com/my1325/SwiftString.git", .branchItem("main")),
        .package(url: "https://github.com/apple/swift-syntax.git", .branchItem("main")),
    ],
    targets: [
        .target(name: "ProcessingFiles", dependencies: [
            "FilePath",
            "SwiftString",
            .product(name: "SwiftSyntax", package: "swift-syntax"),
        ]),
        .target(name: "SwiftFilePlugin", dependencies: [
            "ProcessingFiles",
            "SwiftString",
            "FilePath"
        ])
    ]
)

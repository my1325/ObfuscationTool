// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ObfuscationCore",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "ObfuscationCore", targets: ["ObfuscationCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit.git", .upToNextMajor(from: "1.0.1")),
        .package(path: "../ProcessingFiles"),
    ],
    targets: [
        .target(
            name: "ObfuscationCore",
            dependencies: [
                "PathKit",
                .product(name: "ProcessingFiles", package: "ProcessingFiles"),
            ]
        ),
        .testTarget(
            name: "ObfuscationCoreTests",
            dependencies: ["ObfuscationCore"]
        ),
    ]
)


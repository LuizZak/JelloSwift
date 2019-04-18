// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "JelloSwift",
    products: [
        .library(name: "JelloSwift", targets: ["JelloSwift"])
    ],
    targets: [
        .target(name: "JelloSwift",
                dependencies: [],
                path: "Sources"),
        .testTarget(name: "JelloSwiftTests",
                    dependencies: ["JelloSwift"])
    ]
)

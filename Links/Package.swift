// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Links",
    platforms: [.iOS(SupportedPlatform.IOSVersion.v15)],
    products: [
        .library(
            name: "Links",
            type: .dynamic,
            targets: ["Links"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ccgus/fmdb", .upToNextMinor(from: "2.7.7")),
    ],
    targets: [
        .target(
            name: "Links",
            dependencies: [
                .product(name: "FMDB", package: "fmdb")
            ]
        ),
        .testTarget(
            name: "LinksTests",
            dependencies: [
                "Links",
                .product(name: "FMDB", package: "fmdb")
            ]
        ),
    ]
)

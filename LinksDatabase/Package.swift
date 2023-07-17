// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LinksDatabase",
    platforms: [.iOS(SupportedPlatform.IOSVersion.v15)],
    products: [
        .library(
            name: "LinksDatabase",
            type: .dynamic,
            targets: ["LinksDatabase"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ccgus/fmdb", .upToNextMinor(from: "2.7.7")),
        .package(path: "../Links")
    ],
    targets: [
        .target(
            name: "LinksDatabase",
            dependencies: [
                .product(name: "FMDB", package: "fmdb"),
                "Links"
            ]
        ),
        .testTarget(
            name: "LinksDatabaseTests",
            dependencies: [
                "LinksDatabase",
                .product(name: "FMDB", package: "fmdb")
            ]
        )
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Account",
    platforms: [.iOS(SupportedPlatform.IOSVersion.v15)],
    products: [
        .library(name: "Account", type: .dynamic, targets: ["Account"]),
    ],
    dependencies: [
        .package(path: "../LinksDatabase"),
        .package(path: "../Links"),
        .package(path: "../LinksMetadata")
    ],
    targets: [
        .target(
            name: "Account",
            dependencies: ["LinksDatabase", "Links", "LinksMetadata"]
        ),
        .testTarget(
            name: "AccountTests",
            dependencies: [
                "Account",
                "Links"
            ]
        )
    ]
)

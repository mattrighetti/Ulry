// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LinksMetadata",
    platforms: [.macOS(SupportedPlatform.MacOSVersion.v10_13), .iOS(SupportedPlatform.IOSVersion.v15)],
    products: [
        .library(name: "LinksMetadata", targets: ["LinksMetadata"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tid-kijyun/Kanna.git", from: "5.2.2"),
        .package(path: "../Links")
    ],
    targets: [
        .target(
            name: "LinksMetadata",
            dependencies: [
                .product(name: "Kanna", package: "kanna"),
                "Links"
            ],
            linkerSettings: [
                .unsafeFlags(["-Xlinker", "-no_application_extension"])
            ]
        ),
        .testTarget(name: "LinksMetadataTests", dependencies: ["LinksMetadata"]),
    ]
)

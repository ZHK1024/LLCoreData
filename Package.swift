// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "LLCoreData",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "LLCoreData",
            targets: ["LLCoreData"]
        )
    ],
    dependencies: [
       
    ],
    targets: [
        .target(
            name: "LLCoreData",
            dependencies: []
        )
    ]
)

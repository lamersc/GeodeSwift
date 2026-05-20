// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "GeodeSwift",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Geode",
            type: .static,
            targets: ["Geode"]
        )
    ],
    targets: [
        .target(
            name: "Geode",
            dependencies: ["GeodeSDK"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(
            name: "GeodeSDK",
            plugins: [.plugin(name: "GeodeSDKPrepare")]
        ),
        .plugin(
            name: "GeodeSDKPrepare",
            capability: .buildTool(),
            packageAccess: true
        ),
    ],
    swiftLanguageModes: [.v6]
)

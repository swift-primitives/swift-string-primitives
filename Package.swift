// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "swift-string-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "String Primitives",
            targets: ["String Primitives"]
        )
    ],
    dependencies: [
        .package(path: "../swift-ascii-primitives"),
        .package(path: "../swift-memory-primitives"),
        .package(path: "../swift-identity-primitives"),
    ],
    targets: [
        .target(
            name: "String Primitives",
            dependencies: [
                .product(name: "ASCII Primitives", package: "swift-ascii-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Identity Primitives", package: "swift-identity-primitives"),
            ],
            swiftSettings: [
                .define("STRING_PRIMITIVES_AVAILABLE", .when(platforms: [
                    .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                    .linux, .windows, .android, .openbsd
                ]))
            ]
        ),
        .testTarget(
            name: "String Primitives Tests",
            dependencies: [
                "String Primitives",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}

// swift-tools-version: 6.3.1

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
        ),
        .library(
            name: "String Primitives Test Support",
            targets: ["String Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-memory-heap-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-span-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-tagged-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ownership-primitives.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "String Primitives",
            dependencies: [
                .product(name: "Memory Heap Primitives", package: "swift-memory-heap-primitives"),
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Tagged Primitives", package: "swift-tagged-primitives"),
                .product(name: "Ownership Primitives", package: "swift-ownership-primitives"),
            ],
            swiftSettings: [
                .define("STRING_PRIMITIVES_AVAILABLE", .when(platforms: [
                    .macOS, .iOS, .tvOS, .watchOS, .visionOS,
                    .linux, .windows, .android, .openbsd
                ]))
            ]
        ),
        .target(
            name: "String Primitives Test Support",
            dependencies: [
                "String Primitives",
                .product(name: "Tagged Primitives Test Support", package: "swift-tagged-primitives"),
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "String Primitives Tests",
            dependencies: [
                "String Primitives",
                "String Primitives Test Support",
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
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}

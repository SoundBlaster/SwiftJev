// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "SwiftJev",
    platforms: [
        .iOS(.v15),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(name: "SwiftJev", targets: ["SwiftJev"]),
        .executable(name: "JevBenchmark", targets: ["SwiftJevBenchmark"])
    ],
    dependencies: [
        .package(url: "https://github.com/SoundBlaster/SwiftDecision.git", revision: "77171f9151eee022b268ce761d115298aa97860f")
    ],
    targets: [
        .target(
            name: "SwiftJev",
            dependencies: [
                .product(name: "SwiftDecision", package: "SwiftDecision")
            ]
        ),
        .executableTarget(
            name: "SwiftJevBenchmark",
            dependencies: ["SwiftJev", .product(name: "SwiftDecision", package: "SwiftDecision")],
            path: "Benchmarks/JevBenchmark"
        ),
        .testTarget(
            name: "SwiftJevTests",
            dependencies: ["SwiftJev", .product(name: "SwiftDecision", package: "SwiftDecision")]
        )
    ]
)

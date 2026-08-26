// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "trollidk",
    platforms: [.iOS(.v15)],
    products: [
        .executable(name: "trollidk", targets: ["trollidk"])
    ],
    targets: [
        .executableTarget(
            name: "trollidk",
            path: "."
        )
    ]
)

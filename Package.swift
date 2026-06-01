// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AgentBoard",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AgentBoard", targets: ["AgentBoard"])
    ],
    dependencies: [
        // Pinned to the v1.13.0 release commit. This has the same APIs the plan requires
        // (`open LocalProcessTerminalView`, overridable `dataReceived(slice:)`, and the
        // `currentDirectory:` parameter on `startProcess`) that the released 1.2.x tags lack.
        // The plan's original revision (9446f605, the current default-branch HEAD) cannot be
        // used: it references an undefined `SyncDebug` symbol and fails to compile.
        .package(
            url: "https://github.com/migueldeicaza/SwiftTerm.git",
            revision: "8e7a1e154f470e19c709a00a8768df348ba5fc43"
        )
    ],
    targets: [
        .executableTarget(
            name: "AgentBoard",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "Sources/AgentBoard",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "AgentBoardTests",
            dependencies: ["AgentBoard"],
            path: "Tests/AgentBoardTests"
        )
    ]
)

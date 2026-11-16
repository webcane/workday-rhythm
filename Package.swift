// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkdayRhythm",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WorkdayRhythmApp", targets: ["WorkdayRhythmApp"])
    ],
    targets: [
        .target(name: "Program"),
        .target(name: "TimerEngine", dependencies: ["Program"]),
        .target(name: "SettingsStore", dependencies: ["Program"]),
        .target(name: "MacIntegration"),
        .target(
            name: "SessionCoordinator", dependencies: ["Program", "TimerEngine", "SettingsStore", "MacIntegration"]),
        .target(
            name: "Presentation", dependencies: ["SessionCoordinator"],
            exclude: ["DesignSystem/README.md"]),
        .executableTarget(
            name: "WorkdayRhythmApp",
            dependencies: ["Presentation", "SessionCoordinator", "SettingsStore", "MacIntegration"]),
        .testTarget(name: "ArchitectureTests"),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation"]),
    ]
)

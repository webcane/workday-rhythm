import Foundation
import XCTest

final class ArchitectureTests: XCTestCase {
    private let root = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    private let allowed: [String: Set<String>] = [
        "Program": [],
        "TimerEngine": ["Program"],
        "SettingsStore": ["Program"],
        "MacIntegration": [],
        "SessionCoordinator": ["Program", "TimerEngine", "SettingsStore", "MacIntegration"],
        "Presentation": ["SessionCoordinator"],
        "WorkdayRhythmApp": ["Presentation", "SessionCoordinator", "SettingsStore", "MacIntegration"],
    ]

    func testPackageDependencies() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["swift", "package", "--disable-sandbox", "--scratch-path",
                             NSTemporaryDirectory() + "workday-architecture-build", "--cache-path",
                             NSTemporaryDirectory() + "workday-architecture-cache", "dump-package"]
        process.currentDirectoryURL = root
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        let manifest = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue(try XCTUnwrap(manifest["dependencies"] as? [Any]).isEmpty)
        let targets = try XCTUnwrap(manifest["targets"] as? [[String: Any]])
        var graph: [String: Set<String>] = [:]
        for target in targets where target["type"] as? String != "test" {
            let name = try XCTUnwrap(target["name"] as? String)
            let dependencies = try XCTUnwrap(target["dependencies"] as? [[String: Any]])
            graph[name] = try Set(dependencies.map { dependency in
                let reference = try XCTUnwrap((dependency["byName"] ?? dependency["target"]) as? [Any])
                return try XCTUnwrap(reference.first as? String)
            })
        }
        XCTAssertEqual(Set(graph.keys), Set(allowed.keys))
        XCTAssertTrue(graphViolations(graph).isEmpty, graphViolations(graph).joined(separator: "\n"))
    }

    func testSourceImports() throws {
        for target in allowed.keys {
            let directory = root.appendingPathComponent("Sources/\(target)")
            let files = try XCTUnwrap(FileManager.default.enumerator(
                at: directory, includingPropertiesForKeys: nil
            ))
            for case let file as URL in files where file.pathExtension == "swift" {
                let violations = try importViolations(String(contentsOf: file, encoding: .utf8), target: target)
                XCTAssertTrue(violations.isEmpty, "\(file.path): \(violations)")
            }
        }
    }

    func testCheckerRejectsForbiddenEdgesAndImports() throws {
        var graph = allowed
        graph["Presentation", default: []].insert("TimerEngine")
        XCTAssertEqual(graphViolations(graph), ["Presentation → TimerEngine"])
        XCTAssertEqual(try importViolations("import AppKit", target: "Program"), ["Program → AppKit"])
        XCTAssertEqual(try importViolations("@preconcurrency import SwiftUI", target: "TimerEngine"),
                       ["TimerEngine → SwiftUI"])
        XCTAssertEqual(try importViolations("internal import struct SettingsStore.SettingsStore", target: "Presentation"),
                       ["Presentation → SettingsStore"])
    }

    private func graphViolations(_ graph: [String: Set<String>]) -> [String] {
        graph.flatMap { target, dependencies in
            dependencies.subtracting(allowed[target] ?? []).map { "\(target) → \($0)" }
        }.sorted()
    }

    private func importViolations(_ source: String, target: String) throws -> [String] {
        let expression = try NSRegularExpression(
            pattern: #"\bimport\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\s+)?([A-Za-z_][A-Za-z_0-9]*)"#
        )
        let range = NSRange(source.startIndex..., in: source)
        return expression.matches(in: source, range: range).compactMap { match in
            guard let range = Range(match.range(at: 1), in: source) else { return nil }
            let module = String(source[range])
            let forbiddenLocal = allowed[module] != nil && !(allowed[target] ?? []).contains(module)
            let forbiddenFramework = ["Program", "TimerEngine"].contains(target)
                && module != "Foundation" && !(allowed[target] ?? []).contains(module)
            return forbiddenLocal || forbiddenFramework ? "\(target) → \(module)" : nil
        }
    }
}

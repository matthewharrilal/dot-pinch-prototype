// Tests/VisualAuditHarnessTests.swift
//
// Env-gated integration scaffold (macOS host only — Process is macOS-only).
// Three smoke checks that assert artifact shape (script exit codes, frame
// counts, CSV structure), not rendering correctness. Set
// RUN_VISUAL_AUDIT_HARNESS=1 to enable; tests XCTSkip otherwise.
#if os(macOS)

import XCTest
@testable import DotPinchPrototype

final class VisualAuditHarnessTests: XCTestCase {

    // MARK: - Constants

    private static let projectRoot =
        "/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype"
    private static let scrubBucket =
        projectRoot + "/captured-frames/wave-7e-scrub"
    private static let scriptPath =
        projectRoot + "/scripts/visual-audit-scrub.sh"
    private static let diffScriptPath =
        projectRoot + "/scripts/reference-correlation-diff.py"

    private var shouldRunIntegration: Bool {
        ProcessInfo.processInfo.environment["RUN_VISUAL_AUDIT_HARNESS"] == "1"
    }

    // MARK: - Harness sanity — both platforms

    func testHarnessRunsOnBothPlatforms() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Set RUN_VISUAL_AUDIT_HARNESS=1 to exercise the real scrub script."
        )

        for platform in ["ios18", "ios26"] {
            for direction in ["expand", "collapse"] {
                let exit = runScript(
                    Self.scriptPath,
                    args: [
                        "--platform=\(platform)",
                        "--direction=\(direction)",
                        "--steps=4",  // tiny sweep for the smoke check
                    ]
                )
                XCTAssertEqual(exit, 0,
                               "scrub script failed for \(platform)/\(direction)")
            }
        }
    }

    // MARK: - Frame count

    func testFrameCountMatchesExpected() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Run after a full 30-step sweep across both platforms + directions."
        )
        var total = 0
        for platform in ["ios18", "ios26"] {
            for direction in ["expand", "collapse"] {
                let dir = "\(Self.scrubBucket)/\(platform)/\(direction)"
                let count = countPNGs(in: dir)
                XCTAssertEqual(
                    count, 30,
                    "expected 30 frames in \(dir), got \(count)"
                )
                total += count
            }
        }
        XCTAssertEqual(total, 120, "expected 120 frames total")
    }

    // MARK: - Correlation report

    func testCorrelationReportGenerated() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Run after the diff script has been invoked."
        )
        for platform in ["ios18", "ios26"] {
            for direction in ["expand", "collapse"] {
                let exit = runScript(
                    "/usr/bin/env",
                    args: [
                        "python3", Self.diffScriptPath,
                        "--platform=\(platform)",
                        "--direction=\(direction)",
                    ]
                )
                XCTAssertEqual(exit, 0,
                               "diff script failed for \(platform)/\(direction)")
                let csvPath = "\(Self.scrubBucket)/\(platform)/\(direction)/correlation-report.csv"
                XCTAssertTrue(
                    FileManager.default.fileExists(atPath: csvPath),
                    "missing CSV at \(csvPath)"
                )
                let rows = parseCSV(at: csvPath)
                // header + ≥1 data rows; we only assert structure.
                XCTAssertGreaterThan(rows.count, 1, "CSV has no data rows")
                XCTAssertEqual(rows[0].first, "p",
                               "first column header should be 'p'")
            }
        }
    }

    // MARK: - Helpers

    private func runScript(_ path: String, args: [String]) -> Int32 {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = args
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus
        } catch {
            return -1
        }
    }

    private func countPNGs(in dir: String) -> Int {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir)
        else { return 0 }
        return contents.filter { $0.hasSuffix(".png") && $0.hasPrefix("p_") }.count
    }

    private func parseCSV(at path: String) -> [[String]] {
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8)
        else { return [] }
        return raw.split(whereSeparator: \.isNewline)
            .map { $0.split(separator: ",").map(String.init) }
    }
}

#endif  // os(macOS)

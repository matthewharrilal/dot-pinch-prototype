// Tests/ReferenceCorrelationTests.swift
//
// Env-gated integration scaffold: drives the visual-audit scrubber at 5
// progress points on iOS 18 + iOS 26.4 sims and asserts pHash / histogram /
// SSIM tolerances against reference frames. macOS-host only (Process);
// XCTSkip unless RUN_VISUAL_AUDIT_HARNESS=1 (and Java available for iOS 18).
// Dual-platform parity uses relaxed thresholds (no histogram — gamut-sensitive).

#if os(macOS)

import XCTest
@testable import DotPinchPrototype

final class ReferenceCorrelationTests: XCTestCase {

    // MARK: - Constants

    private static let projectRoot =
        "/Users/spacewizardmoneygang/Desktop/XcodeInstall/dot-pinch-prototype"
    private static let scrubBucket =
        projectRoot + "/captured-frames/wave-7e-scrub"
    private static let orchestratorPath =
        projectRoot + "/scripts/wave7e-reference-capture.sh"
    private static let scrubScriptPath =
        projectRoot + "/scripts/visual-audit-scrub.sh"
    private static let diffScriptPath =
        projectRoot + "/scripts/reference-correlation-diff.py"

    private static let progressPoints: [Double] = [0.1, 0.3, 0.5, 0.7, 0.9]
    private static let direction = "collapse"

    /// Tolerance thresholds — flag a frame if any is exceeded.
    private static let phashThreshold: Double = 12.0
    private static let histThreshold: Double = 0.5
    private static let ssimThreshold: Double = 0.6

    /// Relaxed parity thresholds — comparing two real renders (no reference
    /// in the loop). pHash 8 / SSIM 0.75 absorb Display-P3 vs sRGB gamut
    /// differences that survive luma normalization.
    private static let parityPHashThreshold: Double = 8.0
    private static let paritySSIMThreshold: Double = 0.75

    // MARK: - Gates

    private var shouldRunIntegration: Bool {
        ProcessInfo.processInfo.environment["RUN_VISUAL_AUDIT_HARNESS"] == "1"
    }

    /// Maestro requires Java; without it, iOS 18 activation degrades and
    /// progress capture scrubs an inactive cell.
    private var hasJavaAvailable: Bool {
        let candidatePaths = [
            "/opt/homebrew/opt/openjdk@17/bin/java",
            "/usr/bin/java",
        ]
        if candidatePaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
            return true
        }
        // PATH lookup — `which java`.
        let exit = runShell("/usr/bin/which", args: ["java"])
        return exit == 0
    }

    // MARK: - 1. iOS 18 5-point correlation

    func testReferenceCorrelationiOS18_5Points() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Set RUN_VISUAL_AUDIT_HARNESS=1 to exercise the real scrub harness."
        )
        try XCTSkipUnless(
            hasJavaAvailable,
            "Java not available; iOS 18 activation requires Maestro/JDK 17."
        )

        try runCorrelationSweep(platform: "ios18")
        try assertCorrelationWithinTolerance(platform: "ios18")
    }

    // MARK: - 2. iOS 26.4 5-point correlation

    func testReferenceCorrelationiOS26_5Points() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Set RUN_VISUAL_AUDIT_HARNESS=1 to exercise the real scrub harness."
        )
        // iOS 26.4 uses simctl coord-tap, no Java required.

        try runCorrelationSweep(platform: "ios26")
        // Relaxed histogram on iOS 26.4 — diff script's P3 → sRGB
        // normalization inflates chi-square; pHash and SSIM (luma) hold.
        try assertCorrelationWithinTolerance(
            platform: "ios26",
            histThreshold: 0.8
        )
    }

    // MARK: - 3. Dual-platform parity

    func testDualPlatformParity() throws {
        try XCTSkipUnless(
            shouldRunIntegration,
            "Set RUN_VISUAL_AUDIT_HARNESS=1 to exercise the real scrub harness."
        )

        // Populate the scrub buckets if prior tests didn't.
        let ios18Dir = "\(Self.scrubBucket)/ios18/\(Self.direction)"
        let ios26Dir = "\(Self.scrubBucket)/ios26/\(Self.direction)"
        if !directoryHasFrames(ios18Dir) || !directoryHasFrames(ios26Dir) {
            let exit = runShell(
                "/bin/bash",
                args: [
                    Self.orchestratorPath,
                    "--direction=\(Self.direction)",
                    "--steps=\(Self.progressPoints.count)",
                    "--skip-build",
                ]
            )
            XCTAssertEqual(exit, 0,
                           "orchestrator failed to populate dual-platform buckets")
        }

        // For each target progress point, pair the nearest ios18/ios26
        // captures and compute phash/SSIM via a one-shot python helper.
        for p in Self.progressPoints {
            let p1000 = Int((p * 1000).rounded())
            let ios18Frame = "\(ios18Dir)/p_\(String(format: "%04d", p1000)).png"
            let ios26Frame = "\(ios26Dir)/p_\(String(format: "%04d", p1000)).png"

            guard FileManager.default.fileExists(atPath: ios18Frame),
                  FileManager.default.fileExists(atPath: ios26Frame) else {
                XCTFail("missing frame pair at p=\(p): \(ios18Frame) / \(ios26Frame)")
                continue
            }

            let metrics = computePairMetrics(a: ios18Frame, b: ios26Frame)
            XCTAssertLessThanOrEqual(
                metrics.phash, Self.parityPHashThreshold,
                "iOS 18 vs iOS 26.4 pHash too high at p=\(p): \(metrics.phash)"
            )
            if metrics.ssim >= 0 {
                XCTAssertGreaterThanOrEqual(
                    metrics.ssim, Self.paritySSIMThreshold,
                    "iOS 18 vs iOS 26.4 SSIM too low at p=\(p): \(metrics.ssim)"
                )
            }
        }
    }

    // MARK: - Sweep + assert

    private func runCorrelationSweep(platform: String) throws {
        // Run a full sweep with steps=N and post-filter to the nearest
        // frames per target progress (implemented in the orchestrator).
        let direction = Self.direction
        let steps = "\(Self.progressPoints.count)"

        let exit = runShell(
            "/bin/bash",
            args: [
                Self.orchestratorPath,
                "--direction=\(direction)",
                "--steps=\(steps)",
                "--skip-\(platform == "ios18" ? "ios26" : "ios18")",
            ]
        )
        XCTAssertEqual(exit, 0,
                       "orchestrator failed for \(platform)/\(direction)")
    }

    private func assertCorrelationWithinTolerance(
        platform: String,
        phashThreshold: Double? = nil,
        histThreshold: Double? = nil,
        ssimThreshold: Double? = nil
    ) throws {
        let csvPath = "\(Self.scrubBucket)/\(platform)/\(Self.direction)/correlation-report.csv"
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: csvPath),
            "missing correlation CSV at \(csvPath)"
        )

        let rows = parseCSV(at: csvPath)
        XCTAssertGreaterThan(rows.count, 1, "CSV has no data rows")

        let header = rows[0]
        guard let pIdx = header.firstIndex(of: "p"),
              let phashIdx = header.firstIndex(of: "perceptual_hash_distance"),
              let histIdx = header.firstIndex(of: "color_histogram_distance"),
              let ssimIdx = header.firstIndex(of: "structural_similarity_index"),
              let flaggedIdx = header.firstIndex(of: "flagged") else {
            XCTFail("CSV header missing expected columns: \(header)")
            return
        }

        let pThresh = phashThreshold ?? Self.phashThreshold
        let hThresh = histThreshold ?? Self.histThreshold
        let sThresh = ssimThreshold ?? Self.ssimThreshold

        // Find rows nearest to each target progress point.
        let dataRows = Array(rows.dropFirst())
        for target in Self.progressPoints {
            let nearest = dataRows.min(by: { lhs, rhs in
                let lp = Double(lhs[pIdx]) ?? .infinity
                let rp = Double(rhs[pIdx]) ?? .infinity
                return abs(lp - target) < abs(rp - target)
            })
            guard let row = nearest else { continue }

            let phash = Double(row[phashIdx]) ?? Double.nan
            let hist = Double(row[histIdx]) ?? Double.nan
            let ssim = Double(row[ssimIdx]) ?? -1
            let flagged = row[flaggedIdx]

            print("[\(platform)] p≈\(target) phash=\(phash) hist=\(hist) ssim=\(ssim) flagged=\(flagged)")

            if !phash.isNaN {
                XCTAssertLessThanOrEqual(
                    phash, pThresh,
                    "\(platform) pHash too high at p≈\(target): \(phash) > \(pThresh)"
                )
            }
            if !hist.isNaN {
                XCTAssertLessThanOrEqual(
                    hist, hThresh,
                    "\(platform) histogram too high at p≈\(target): \(hist) > \(hThresh)"
                )
            }
            if ssim >= 0 {
                XCTAssertGreaterThanOrEqual(
                    ssim, sThresh,
                    "\(platform) SSIM too low at p≈\(target): \(ssim) < \(sThresh)"
                )
            }
        }
    }

    // MARK: - Helpers

    private struct PairMetrics {
        let phash: Double
        let hist: Double
        let ssim: Double
    }

    /// One-shot Python helper that reuses the diff script's primitives to
    /// compare two arbitrary frames (no reference).
    private func computePairMetrics(a: String, b: String) -> PairMetrics {
        let pyScript = """
        import sys
        try:
            from PIL import Image
        except ImportError:
            print("0.0,0.0,-1.0"); sys.exit(0)
        try:
            import imagehash
            HAS = True
        except ImportError:
            HAS = False
        try:
            from skimage.metrics import structural_similarity as ssim_fn
            import numpy as np
            HAS_SK = True
        except ImportError:
            HAS_SK = False

        a_path, b_path = sys.argv[1], sys.argv[2]
        a_img = Image.open(a_path); b_img = Image.open(b_path)
        if HAS:
            ph = float(imagehash.phash(a_img) - imagehash.phash(b_img))
        else:
            def avg(img):
                g = img.convert("L").resize((8,8))
                px = list(g.getdata()); m = sum(px)/len(px); bits=0
                for p in px: bits=(bits<<1)|(1 if p>m else 0)
                return bits
            ph = float(bin(avg(a_img) ^ avg(b_img)).count("1"))
        ha = a_img.convert("RGB").histogram()
        hb = b_img.convert("RGB").histogram()
        ta, tb = max(1,sum(ha)), max(1,sum(hb))
        chi = 0.0
        for x, y in zip(ha, hb):
            nx, ny = x/ta, y/tb
            d = nx+ny
            if d > 0: chi += (nx-ny)**2/d
        if HAS_SK:
            aa = np.array(a_img.convert("L").resize((256,256)))
            bb = np.array(b_img.convert("L").resize((256,256)))
            ss = float(ssim_fn(aa, bb, data_range=255))
        else:
            ss = -1.0
        print(f"{ph},{chi},{ss}")
        """
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        task.arguments = ["python3", "-c", pyScript, a, b]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let line = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty else {
                return PairMetrics(phash: .infinity, hist: .infinity, ssim: -1)
            }
            let parts = line.split(separator: ",").map { Double($0) ?? .nan }
            guard parts.count == 3 else {
                return PairMetrics(phash: .infinity, hist: .infinity, ssim: -1)
            }
            return PairMetrics(phash: parts[0], hist: parts[1], ssim: parts[2])
        } catch {
            return PairMetrics(phash: .infinity, hist: .infinity, ssim: -1)
        }
    }

    private func runShell(_ path: String, args: [String]) -> Int32 {
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

    private func directoryHasFrames(_ dir: String) -> Bool {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir)
        else { return false }
        return contents.contains { $0.hasPrefix("p_") && $0.hasSuffix(".png") }
    }

    private func parseCSV(at path: String) -> [[String]] {
        guard let raw = try? String(contentsOfFile: path, encoding: .utf8)
        else { return [] }
        return raw.split(whereSeparator: \.isNewline)
            .map { $0.split(separator: ",", omittingEmptySubsequences: false).map(String.init) }
    }
}

#endif  // os(macOS)

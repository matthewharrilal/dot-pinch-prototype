//
//  PinchTuning.swift
//  DotPinchPrototype
//
//  Single source of truth for every magic number governing the pinch-to-memory
//  similarity transform. All constants here exist to serve one or more of the
//  nine refusals from /tmp/depth_cue_audit.md — comments cite the refusal each
//  constant enforces.
//
//  CQ-1: no numeric literal cited here may appear anywhere else in the codebase.
//

import CoreGraphics

enum PinchTuning {

    // MARK: - Similarity-transform parameters (REFUSAL #1, #6)

    /// Baseline similarity scale. At progress = 0 the card is at full size.
    /// REFUSAL #1: uniform sx = sy = baselineSimilarityS at p = 0. The transform
    /// is a pure 2D similarity — no rotation, no perspective, no shear.
    static let baselineSimilarityS: CGFloat = 1.0

    /// Destination similarity scale. At progress = 1 the card is shrunk to
    /// destinationSimilarityS of its bounds.
    /// REFUSAL #1: same scalar applied to width AND height. Aspect ratio
    /// invariant across all progress.
    /// Source: spec — "s decreases monotonically from 1.0 to roughly 0.4".
    static let destinationSimilarityS: CGFloat = 0.4

    /// Anchor point in normalized layer bounds (LTR). The fixed point of the
    /// similarity transform — bottom-area, left of center.
    /// REFUSAL #1: composed via translation matrix, NOT layer.anchorPoint
    /// mutation (which would shift the layer's visible position).
    /// Math: T(p) = translate(anchor·(1-s)) · scale(s).
    /// Source: spec — "lower-middle of the visible content area ... biased
    /// toward the leading edge of text."
    static let anchorPoint: CGPoint = CGPoint(x: 0.4, y: 0.85)

    // MARK: - Pinch gesture mapping (REFUSAL #1)

    /// Sensitivity amplification for pinch.scale → progress mapping.
    /// pinch.scale must drop from 1.0 → (1 - 1/k) to reach full progress.
    /// k = 2.5 → pinch.scale 0.6 hits progress 1.0 (comfortable finger travel).
    /// REFUSAL #1: a scalar (not a vector). The gesture's input IS already a
    /// scalar — preserved through to the transform without any axis decoupling.
    static let pinchSensitivity: CGFloat = 2.5

    /// Rubber-band damping coefficient. UIScrollView-tuned (Apple's c = 0.55).
    static let rubberBandDampingC: CGFloat = 0.55

    // MARK: - Affordance materialization

    /// Progress past which affordance icons begin fading in.
    static let affordanceMaterializesAt: CGFloat = 0.6

    // MARK: - Spring physics

    /// Spring response (s). Source: starts from Spring.defaultUI; refined
    /// empirically against Dot reference frames.
    static let springResponse: CGFloat = 0.55

    /// Spring damping ratio. Critically damped to prevent overshoot beyond
    /// the [0, 1] progress range — overshoot would violate the monotonic
    /// scale invariant.
    static let springDamping: CGFloat = 0.85

    // MARK: - Velocity projection (WWDC 2018 / E17)

    /// Minimum gesture velocity (normalized progress units / second) at which
    /// a settle-velocity injection survives the .ended → settle handoff.
    static let velocityHandoffFloorPerSecond: CGFloat = 0.1

    // MARK: - Conversation content

    /// Number of past messages laid out above the current message.
    static let pastMessageCount: Int = 5
}

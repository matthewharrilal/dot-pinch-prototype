//
//  TimelineCompressible.swift
//  DotPinchPrototype
//
//  Protocol abstraction that resolves the PinchToMemoryInteraction →
//  ConversationContentView layer dependency violation (PM-W3-117).
//
//  PinchToMemoryInteraction (Interaction layer) depends only on this protocol,
//  not on the concrete ConversationContentView (Demo layer). ConversationContentView
//  conforms via a one-line extension in the Demo layer. Preserves CQ-4 + INV-14.
//
//  Per IMPL-SPEC §0.4.
//

import CoreGraphics
import QuartzCore

public protocol TimelineCompressible: AnyObject {

    /// Drives Phase-1 timeline compression — past content reveal + global content fade.
    /// Implementations MUST:
    ///   1. Clamp `progress` to [0, 1].
    ///   2. Wrap render-tree mutations in `CATransaction.setDisableActions(true)` (INV-2).
    ///   3. Read all magic numbers from `PinchTuning` (CQ-1).
    ///
    /// - Parameter progress: 0 = baseline (current message visible, past hidden);
    ///                       1 = full Phase-1 compression (past visible, content at floor alpha).
    func setTimelineCompression(_ progress: CGFloat)
}

//
//  PinchMorphState.swift
//  DotPinchPrototype
//
//  The composite state struct that drives the morph as ONE motion, not four.
//
//  This is conjecture Decision 5 (the architectural elevation move per Wave's EP5):
//  define a custom struct conforming to SpringInterpolatable, then animate THAT as one
//  composite spring rather than four parallel animators on the individual properties.
//
//  Why this matters:
//   - One animator means one velocity vector. Retargeting any field automatically
//     retargets all coherently (NINETY-pinch-E01).
//   - One completion event for the morph as a whole (NINETY-pinch-E13).
//   - One settling-time decision shared across all properties (E11).
//   - The code's structure reads as "the morph is one motion of one state object,"
//     not as "the morph is four animations someone remembered to keep in sync."
//
//  The five fields chosen here are the minimum needed to demonstrate the bare-bones
//  test of Decision 5; a fuller production version would include chrome opacity,
//  past-day card staggering parameters, affordance icon progress, etc.
//

import Foundation
import CoreGraphics

public struct PinchMorphState: SpringInterpolatable, VelocityProviding, Equatable {
    public typealias ValueType = PinchMorphState
    public typealias VelocityType = PinchMorphState

    /// The morphing surface's bounds (in the parent's coordinate space).
    /// Fullscreen rect → slot rect interpolates through this single field.
    /// Per the trajectory verdict: anchor at top-left of source slot; bottom_y expands.
    public var bounds: CGRect

    /// The morphing surface's corner radius. Animates 0 (fullscreen) → ~16 (card).
    public var cornerRadius: CGFloat

    /// The chrome (compose bar / status overlay) opacity. 1.0 fullscreen → 0.0 collapsed.
    public var chromeOpacity: CGFloat

    /// The Today affordance glyph progress. 0 = pinch-in glyph, 1 = expand-out glyph.
    /// Bi-directional affordance signaling per Soul Piece #3.
    public var affordanceProgress: CGFloat

    /// The chat content's scroll-position drift — for Soul Piece #6 / live-content
    /// reflow demonstration. Not strictly required by the trajectory verdict but included
    /// so the live-content criterion is visible to a tester.
    public var contentOffsetY: CGFloat

    public init(
        bounds: CGRect,
        cornerRadius: CGFloat,
        chromeOpacity: CGFloat,
        affordanceProgress: CGFloat,
        contentOffsetY: CGFloat = 0
    ) {
        self.bounds = bounds
        self.cornerRadius = cornerRadius
        self.chromeOpacity = chromeOpacity
        self.affordanceProgress = affordanceProgress
        self.contentOffsetY = contentOffsetY
    }

    public static var zero: PinchMorphState {
        PinchMorphState(
            bounds: .zero,
            cornerRadius: 0,
            chromeOpacity: 0,
            affordanceProgress: 0,
            contentOffsetY: 0
        )
    }

    /// Per-component integration. Each field's CGFloat updateValue() is invoked
    /// independently with the SAME spring and SAME dt — this is what couples them
    /// into "one motion" even though they're integrated separately.
    public static func updateValue(
        spring: Spring,
        value: PinchMorphState,
        target: PinchMorphState,
        velocity: PinchMorphState,
        dt: TimeInterval
    ) -> (value: PinchMorphState, velocity: PinchMorphState) {

        let (newBounds, vBounds) = CGRect.updateValue(
            spring: spring, value: value.bounds, target: target.bounds, velocity: velocity.bounds, dt: dt
        )
        let (newCorner, vCorner) = CGFloat.updateValue(
            spring: spring, value: value.cornerRadius, target: target.cornerRadius, velocity: velocity.cornerRadius, dt: dt
        )
        let (newChrome, vChrome) = CGFloat.updateValue(
            spring: spring, value: value.chromeOpacity, target: target.chromeOpacity, velocity: velocity.chromeOpacity, dt: dt
        )
        let (newAffordance, vAffordance) = CGFloat.updateValue(
            spring: spring, value: value.affordanceProgress, target: target.affordanceProgress, velocity: velocity.affordanceProgress, dt: dt
        )
        let (newOffset, vOffset) = CGFloat.updateValue(
            spring: spring, value: value.contentOffsetY, target: target.contentOffsetY, velocity: velocity.contentOffsetY, dt: dt
        )

        return (
            PinchMorphState(
                bounds: newBounds,
                cornerRadius: newCorner,
                chromeOpacity: newChrome,
                affordanceProgress: newAffordance,
                contentOffsetY: newOffset
            ),
            PinchMorphState(
                bounds: vBounds,
                cornerRadius: vCorner,
                chromeOpacity: vChrome,
                affordanceProgress: vAffordance,
                contentOffsetY: vOffset
            )
        )
    }

    /// Linear interpolation between two states. Used during the gesture-active phase
    /// where the pinch directly drives progress (not spring-physics). On gesture release,
    /// the SpringAnimator takes over with updateValue() above.
    public static func interpolate(from: PinchMorphState, to: PinchMorphState, t: CGFloat) -> PinchMorphState {
        let clampedT = clamp(t, 0, 1)
        return PinchMorphState(
            bounds: CGRect(
                x: lerp(from.bounds.minX, to.bounds.minX, clampedT),
                y: lerp(from.bounds.minY, to.bounds.minY, clampedT),
                width: lerp(from.bounds.width, to.bounds.width, clampedT),
                height: lerp(from.bounds.height, to.bounds.height, clampedT)
            ),
            cornerRadius: lerp(from.cornerRadius, to.cornerRadius, clampedT),
            chromeOpacity: lerp(from.chromeOpacity, to.chromeOpacity, clampedT),
            affordanceProgress: lerp(from.affordanceProgress, to.affordanceProgress, clampedT),
            contentOffsetY: lerp(from.contentOffsetY, to.contentOffsetY, clampedT)
        )
    }
}

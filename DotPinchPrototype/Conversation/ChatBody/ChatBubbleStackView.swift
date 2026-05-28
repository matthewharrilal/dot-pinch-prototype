// ChatBubbleStackView — UIScrollView + vertical UIStackView holding bubble
// views. Mirrors chatVC.scrollView + chatVC.bubbleStack at CVC:55-68 with
// the same constraints + scroll behavior so post-handoff visual is identical
// to pre-handoff. Reuses existing ChatBubbleView per §16.11.

import UIKit

@MainActor
final class ChatBubbleStackView: UIView {

    // MARK: - Subviews (closure-init at class top per P1.2)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = .clear
        scroll.alwaysBounceVertical = false
        scroll.keyboardDismissMode = .none
        scroll.showsVerticalScrollIndicator = false
        scroll.clipsToBounds = false
        scroll.isScrollEnabled = false
        return scroll
    }()

    private let bubbleStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = Layout.bubbleSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // MARK: - Token (P2.11)

    private enum Layout {
        static let bubbleSpacing: CGFloat = 16
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        installViewHierarchy()
        activateConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ChatBubbleStackView is code-only; no NSCoder support")
    }

    // MARK: - View hierarchy

    private func installViewHierarchy() {
        addSubview(scrollView)
        scrollView.addSubview(bubbleStack)
    }

    private func activateConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            bubbleStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    // MARK: - Configure

    /// Rebuild bubble views from conversation messages.
    /// P19.3 idempotent: same conversation produces identical view tree.
    func configure(with conversation: Conversation, metadataHidden: Bool = false) {
        wipeBubbles()
        installBubbles(from: conversation.messages, metadataHidden: metadataHidden)
        layoutIfNeeded()
        scheduleScrollToBottom()
    }

    // MARK: - Configure helpers (P11.1 SRP)

    private func wipeBubbles() {
        for bubble in bubbleStack.arrangedSubviews {
            bubbleStack.removeArrangedSubview(bubble)
            bubble.removeFromSuperview()
        }
    }

    private func installBubbles(from messages: [Message], metadataHidden: Bool) {
        for (i, message) in messages.enumerated() {
            let bubble = ChatBubbleView(message: message, metadataHidden: metadataHidden)
            bubbleStack.addArrangedSubview(bubble)
            if metadataHidden, i > 0 {
                let prev = messages[i - 1]
                let prevBubble = bubbleStack.arrangedSubviews[i - 1]
                let sameRole = message.role == prev.role
                bubbleStack.setCustomSpacing(sameRole ? 4 : Layout.bubbleSpacing, after: prevBubble)
            }
        }
    }

    private func scheduleScrollToBottom() {
        // scrollView.contentSize is derived from bubbleStack's intrinsic content,
        // which Auto Layout hasn't computed yet at the moment configure() returns.
        // Synchronous scroll would clamp to (0,0). Defer to next runloop tick.
        DispatchQueue.main.async { [weak self] in
            self?.scrollToBottom()
        }
    }

    private func scrollToBottom() {
        let bottomY = max(0, scrollView.contentSize.height - scrollView.bounds.height)
        scrollView.setContentOffset(CGPoint(x: 0, y: bottomY), animated: false)
    }

    // MARK: - State controller / handoff seam (P5.5)

    /// Read/write the scrollView's contentOffset. Used by the state controller
    /// and handoff capture/apply paths.
    var scrollContentOffset: CGPoint {
        get { scrollView.contentOffset }
        set { scrollView.contentOffset = newValue }
    }

    func stopDeceleration() {
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
    }

    var debugRecentBubbleBottomInWindow: CGPoint? {
        guard let last = bubbleStack.arrangedSubviews.last else { return nil }
        let bottomPoint = CGPoint(x: last.bounds.midX, y: last.bounds.maxY)
        return last.convert(bottomPoint, to: nil)
    }

    var debugFirstBubbleTopInWindow: CGPoint? {
        guard let first = bubbleStack.arrangedSubviews.first else { return nil }
        let topPoint = CGPoint(x: first.bounds.midX, y: 0)
        return first.convert(topPoint, to: nil)
    }
}

// MARK: - ContentScalerView
//
// Track A primitive. The single source of truth is p (normalized gesture
// progress, 0=chat-rest, 1=cell-rest). Scale and blur are derived curves of p,
// applied by internal subscribers. The outer view stays default-anchored for
// Auto Layout coexistence; the inner ScalingSurface holds the off-center
// anchor + the transform. bodyContent and dormantBlur ride the transform;
// dormantLabel is a sibling of the surface — outside the transform — so it
// can render at its own fixed readable size when the cross-fade lands.

@MainActor
final class ContentScalerView: UIView {

    // y=1.0 is literal surface-bottom for the no-composer sandbox; recalibrate
    // to the real composer-anchored recent-message-bottom at migration.
    static let scaleAnchor = CGPoint(x: 0.5, y: 1.0)

    // Curve breakpoints from the reference's visual A/B (arc-normalized p):
    //   scale onset            p = 0.12  text first detectably smaller; still sharp
    //   blur  lead-in begins   p = 0.33  sub-perceptual softening; text readable
    //   blur  crash begins     p = 0.40  text breaks rapidly
    //   dissolve onset         p = 0.42  whole content begins fading to faint
    //   blur  full             p = 0.44  max blur (soft defocus, not slab)
    //   scale full             p = 0.45  surface at scaleAtCellRest; reveal locks
    //   dissolve full          p = 0.46  content at dissolveFloor; visible stillness
    //   top-fade boundary→1.0  p = 0.50  mask completes its descent
    //   HOLD BEAT              p ∈ [0.44, 0.50]  faded full-screen state stable;
    //                          panel bounds bit-identical; Track A tails complete
    //                          mathematically in [0.44, 0.46] but invisibly because
    //                          dissolve has driven content to bg-color.
    //   contraction onset      p = 0.50  panel begins contracting (height curve);
    //                          C¹ eased shoulder over [0.50, 0.55] then linear.
    //   width  onset           p = 0.62  panel width begins shrinking (vertical-first)
    //   pink mask recede       p ∈ [0.50, 0.65]  gradient field reveals
    //   grey mask recede       p ∈ [0.75, 0.90]
    // Ordering: scale leads blur, dissolve crashes after blur, hold beat
    // brackets the A→B handoff, contraction begins after.
    // Structural invariants:
    //   blurFullP < scaleFullP — full blur at full size is impossible.
    //   scaleFullP < panelContractionOnsetP — scale settles cleanly before
    //                                         panel contracts (hold bracketing).
    static let scaleOnsetP: CGFloat = 0.12
    static let scaleFullP: CGFloat = 0.45
    // Blur breakpoints retained as named anchors for the comment block above
    // and external references; the curve itself is now defined by `blurKnotsP`
    // / `blurKnotsY` (see `blurCurve(_:)`). `blurOnsetP` marks the END of the
    // gentle lead-in and the BEGINNING of the fast crash (= where the reference
    // text begins to break readability); `blurFullP` marks the crash settle.
    static let blurOnsetP: CGFloat = 0.40
    static let blurFullP: CGFloat = 0.44
    static let scaleAtCellRest: CGFloat = 0.40

    let bodyContent: ChatBubbleStackView
    let dormantBlur: UIVisualEffectView
    let dormantLabel: UILabel
    private let scalingSurface: ScalingSurface
    private let blurAnimator: UIViewPropertyAnimator

    var progress: CGFloat { scalingSurface.progress }
    var scale: CGFloat { Self.scaleCurve(scalingSurface.progress) }
    var blurFraction: CGFloat { Self.blurCurve(scalingSurface.progress) }

    // Blur fraction curve (item A6 + A7).
    //
    // Maps gesture progress p ∈ [0, 1] → `blurAnimator.fractionComplete`. The
    // animator is paused on a single `UIBlurEffect(style: .regular)` animation
    // step; fractionComplete scrubs blur intensity continuously between
    // "no blur" (0.0) and "full .regular blur" (1.0). We cap our max output
    // below 1.0 so the visible end-state reads as soft defocus, not a frosted
    // slab — the reference's blurred text retains sensible block structure.
    //
    // Shape: gentle lead-in then fast crash. The reference (dense band
    // profile) shows letters staying crisp through p≈0.33, then sharpness
    // collapses 220→8 between p=0.40 and p=0.42. We mirror that: knots place a
    // barely-perceptible engagement at 0.33 (lead-in), still subtle by 0.40
    // (text still readable), then accelerate to max strength by 0.44, then
    // plateau. The lead-in exists for two reasons:
    //   1. It matches what the reference actually does (gradual loosen → fast
    //      crash), not a strict held-at-zero-then-snap behavior.
    //   2. It maintains C¹ continuity at the crash onset — without a lead-in,
    //      the derivative would jump from 0 to large at p=0.40, producing a
    //      visible kink in the rate-of-blur for a finger-scrubbed gesture.
    //
    // Composite with dissolve (item A5/A8): at end-of-Track-A the dissolve
    // fades the entire ContentScalerView (including this blur view) toward
    // background. The visible end-state blur = (blur strength) × (remaining
    // opacity). The pair `blurMaxFraction` × `dissolveFloor` is the joint
    // calibration knob for the composite end-state; do not tune either in
    // isolation. The reference end-state is a faint, soft, sensibly-structured
    // texture — not an opaque blur block.
    //
    // Form: 5-knot piecewise cubic Hermite, Fritsch-Carlson monotone tangents
    // (same construction as `topFadeBoundary(_:)`). Guarantees C¹ continuity,
    // monotone non-decreasing (blur never reverses → reverse pinch retraces
    // identical values), and no overshoot.
    //
    // Knots:
    //   K0 (0.00, 0.000) — no blur at chat-rest.
    //   K1 (0.33, 0.010) — lead-in begins. Value is sub-perceptual at this
    //                      level; text remains readable through ~p=0.38.
    //   K2 (0.40, 0.050) — still sub-perceptual. Crash about to begin.
    //   K3 (0.44, blurMaxFraction) — peak (soft defocus, not a slab).
    //   K4 (0.50, blurMaxFraction) — plateau through Track A handoff into B1.
    //
    // Tangents (Fritsch-Carlson):
    //   d₀ = 0.0303, d₁ = 0.5714, d₂ = ((max−0.05) / 0.04), d₃ = 0
    //   m₀ = d₀, m₁ = harm(d₀,d₁) = 0.0575
    //   m₂ = harm(d₁,d₂) — recomputed at runtime from blurMaxFraction
    //   m₃ = 0 (Fritsch-Carlson rule: adjacent secant is 0 → tangent is 0,
    //          preserves monotonicity into the flat tail)
    //   m₄ = 0 (one-sided, = d₃)
    static let blurMaxFraction: CGFloat = 0.45

    static func blurCurve(_ p: CGFloat) -> CGFloat {
        let ps: [CGFloat] = [0.00, 0.33, 0.40, 0.44, 0.50]
        let ys: [CGFloat] = [0.00, 0.010, 0.050, blurMaxFraction, blurMaxFraction]

        // Secant slopes; tangent at the crash interior recomputed so that
        // `blurMaxFraction` can be tuned without re-deriving constants by hand.
        let d0: CGFloat = (ys[1] - ys[0]) / (ps[1] - ps[0])
        let d1: CGFloat = (ys[2] - ys[1]) / (ps[2] - ps[1])
        let d2: CGFloat = (ys[3] - ys[2]) / (ps[3] - ps[2])
        // d3 = 0 (flat tail K3→K4).

        let m0 = d0
        let m1 = 2 * d0 * d1 / (d0 + d1)
        let m2 = 2 * d1 * d2 / (d1 + d2)
        let m3: CGFloat = 0
        let m4: CGFloat = 0
        let ms: [CGFloat] = [m0, m1, m2, m3, m4]

        if p <= ps[0] { return ys[0] }
        if p >= ps[ps.count - 1] { return ys[ys.count - 1] }

        var i = 0
        while i < ps.count - 1 && p > ps[i + 1] { i += 1 }

        let h = ps[i + 1] - ps[i]
        let t = (p - ps[i]) / h
        let t2 = t * t
        let t3 = t2 * t
        let h00 =  2 * t3 - 3 * t2 + 1
        let h10 =      t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 =      t3 -     t2
        return h00 * ys[i] + h10 * h * ms[i] + h01 * ys[i + 1] + h11 * h * ms[i + 1]
    }

    // Content dissolve alpha (item A5 / A8).
    //
    // Maps gesture progress p ∈ [0, 1] → alpha applied to the whole
    // ContentScalerView (= `self` from inside this class). Because the blur
    // view is a sibling of the scaling surface within the CSV, this single
    // alpha multiplier fades EVERYTHING — bubble stack, blur view, dormant
    // label — together toward background. That co-fading is what converts the
    // would-be "frosted slab" end-state into the reference's "faint, soft,
    // dissolving texture": the blur visually weakens as the content beneath
    // also weakens.
    //
    // The dissolve channel is the one that takes B6 (the recent message) down.
    // The top-fade explicitly hands B6 off at p=0.40 — for p ∈ [0, 0.40], B6
    // is fully opaque from the top-fade's perspective. From p=0.42 onwards
    // the dissolve carries B6 (and the whole content) toward `dissolveFloor`.
    //
    // Composition note: in [0.40, 0.50] the top-fade tail continues (boundary
    // 0.833 → 1.0), the blur crashes (0.40 → 0.44), and the dissolve fades
    // everything (0.42 → 0.46). All three superpose. The composite end-state
    // — not the individual channels' maxes — is what we tune against the
    // reference's faint texture. The 9-luminance-unit top-vs-bottom asymmetry
    // produced by top-fade contributing only at the top is below JND at low
    // contrast and is consistent with the gesture's bottom-anchored character.
    //
    // Shape: held at 1.0 through p=0.42, smoothstep down to `dissolveFloor` by
    // p=0.46, plateau. Smoothstep is C¹ at both endpoints (zero derivative on
    // both sides at the onset and at the floor), so the curve has no kinks at
    // its transitions. The zero-velocity stretches before 0.42 and after 0.46
    // are channel-inactive regions, not engaged-but-stuck regions, which is
    // distinct from the user-perceptible dead zones the interactive principle
    // forbids.
    //
    // Pure function of p — no state; reverse pinch retraces identical values.
    static let dissolveOnsetP: CGFloat = 0.42
    static let dissolveFullP: CGFloat = 0.46
    // Floor is the joint-tuned partner of `blurMaxFraction` for the composite
    // end-state. Measured trajectory in the content region at p=0.46:
    //   floor=0.10 → mean ≈ 234 (essentially erased — content gone)
    //   floor=0.30 → mean ≈ 232.8 (faint but slightly over-erased; +7 vs ref)
    //   floor=0.40 → target landing at ≈ 225 (faint with ghost structure)
    // Reference end-state target is ~225 — faint but still legibly a
    // conversation. Raising the floor brings more of the (blurred) content
    // through; because blurMaxFraction caps the blur, the composite still
    // reads as soft defocus rather than a frosted slab.
    static let dissolveFloor: CGFloat = 0.40

    // D1 — body-out extension. The Track A dissolve takes content from 1.0 to
    // dissolveFloor by p=0.46 and holds. D1's body-out continues from the
    // floor to 0 during the contraction window, completing before the
    // staggered label-in. The handoff at bodyOutOnsetP is continuous
    // (left side held at floor, right side smoothstep starting at floor).
    // C¹ at both endpoints (smoothstep zero-derivative at t=0 and t=1).
    //
    // Application target (per D1 architecture decoupling): this curve is now
    // applied to bodyContent.alpha AND dormantBlur.alpha (separately), not to
    // the CSV's own alpha. CSV.alpha stays at 1 so the dormantLabel (which has
    // moved to be a child of panel) can be controlled independently. The
    // visual effect of the dissolve is unchanged — both bodyContent and blur
    // still fade together on the same curve.
    // D1' reconciliation — body-clear timing moved earlier to match the
    // reference. Re-sampling (multi-metric: mean + dark-coverage<surface-5 +
    // 5th percentile) calibrated against our v23 floor showed:
    //   our v23 floor signature: mean=232.1, p5=226, dark-cov=5.8%
    //   reference at p=0.66+:    mean=232.9, p5=233, dark-cov=1.1%
    // Distinct signatures → reference body is genuinely cleared (alpha=0) by
    // p=0.66, NOT held at floor. Our held-faint phase from p=0.46→0.85
    // diverges from the reference (which has empty cell from 0.66 onward).
    //
    // Fix: move the body-out final fade earlier to match reference's body-
    // clear timing. Track A dissolve and the floor are UNTOUCHED (verified):
    //   - dissolve still goes 1.0→0.40 at [0.42, 0.46] (unchanged)
    //   - body held at floor 0.40 from p=0.46 (unchanged)
    //   - held-faint duration NOW shrinks from [0.46, 0.85] (0.39) to
    //     [0.46, 0.61] (0.15), because the final fade starts earlier
    //   - body-out smoothstep 0.40→0 over [0.61, 0.66] — body fully cleared
    //     by p=0.66, matching reference exactly
    static let bodyOutOnsetP: CGFloat = 0.61
    static let bodyOutFullP: CGFloat = 0.66

    static func contentDissolveAlpha(_ p: CGFloat) -> CGFloat {
        if p <= dissolveOnsetP { return 1.0 }
        if p >= bodyOutFullP { return 0.0 }
        if p >= bodyOutOnsetP {
            // D1 body-out segment: smoothstep from floor → 0
            let t = (p - bodyOutOnsetP) / (bodyOutFullP - bodyOutOnsetP)
            let s = t * t * (3 - 2 * t)
            return dissolveFloor + (0.0 - dissolveFloor) * s
        }
        if p >= dissolveFullP { return dissolveFloor }
        // Track A dissolve segment: smoothstep from 1.0 → floor (unchanged)
        let t = (p - dissolveOnsetP) / (dissolveFullP - dissolveOnsetP)
        let s = t * t * (3 - 2 * t)
        return 1.0 + (dissolveFloor - 1.0) * s
    }

    // D1+D3 — label-in curve (staggered after body-out).
    //
    // Placeholder label fades 0 → 1 over [labelInOnsetP, labelInFullP].
    // Reference sampling showed label-in spans ~0.07 of progress (p=0.86→0.93)
    // in the source; we match that span here. The stagger gap between
    // bodyOutFullP=0.91 and labelInOnsetP=0.93 is 0.02 of progress — the
    // "brief near-empty card moment" the D3 spec asks for.
    //
    // (Note: the reference shows an additional 0.20 of generation-gated
    // stagger from body-out completion at ~p=0.66 to label-in onset at
    // ~p=0.86 — that's the summary-generation/sparkle integration beat,
    // explicitly out of scope for the primitive mechanism here.)
    //
    // Pure function of p, smoothstep (C¹ at both endpoints, monotone
    // non-decreasing, no overshoot). Reverse pinch un-fades the label
    // smoothly.
    // D1' label-in timing — de-gated from generation (primitive).
    //
    // Reference label-in window: p=0.86→0.93 (0.07 span). Empty-card stagger
    // in reference: p=0.66→0.86 = 0.20 of progress. Re-sampling the empty
    // window (0.66→0.86) found ALL metrics flat (mean=232.7-232.9, p5=233,
    // dark-cov=1.1-2.1%) — pure-empty, no transition activity. So the entire
    // 0.20 stagger is generation-gated (the summary can't appear until it's
    // generated; the sparkle/generating beat fills that window).
    //
    // For our primitive (no generation), the de-gated empty-card beat is the
    // natural cross-fade settle: ~0.05. Label-in onset = body-out completion
    // (p=0.66) + 0.05 settle = p=0.71. Label-in span keeps the reference's
    // measured 0.07 width: [0.71, 0.78].
    //
    // INTEGRATION NOTE: when the sparkle/generating beat is built, label-in
    // onset should move LATER (toward the reference's p=0.86) to wait for the
    // generation to complete. The 0.20-of-progress empty-card beat in the
    // reference is the generating window that the sparkle fills.
    static let labelInOnsetP: CGFloat = 0.71
    static let labelInFullP: CGFloat = 0.78

    static func labelInAlpha(_ p: CGFloat) -> CGFloat {
        if p <= labelInOnsetP { return 0.0 }
        if p >= labelInFullP { return 1.0 }
        let t = (p - labelInOnsetP) / (labelInFullP - labelInOnsetP)
        let s = t * t * (3 - 2 * t)
        return s
    }

    static let shadowOnsetP: CGFloat = 0.85
    static let shadowFullP: CGFloat = 1.00

    static func shadowOpacityCurve(_ p: CGFloat) -> CGFloat {
        if p <= shadowOnsetP { return 0.0 }
        if p >= shadowFullP { return 1.0 }
        let t = (p - shadowOnsetP) / (shadowFullP - shadowOnsetP)
        return t * t * (3 - 2 * t)
    }

    static func scaleCurve(_ p: CGFloat) -> CGFloat {
        if p <= scaleOnsetP { return 1.0 }
        if p >= scaleFullP { return scaleAtCellRest }
        let t = (p - scaleOnsetP) / (scaleFullP - scaleOnsetP)
        return 1.0 + (scaleAtCellRest - 1.0) * t
    }

    static let panelWidthOnsetP: CGFloat = 0.62

    // Panel-contraction onset (item B1 — the hold beat at the A→B handoff).
    //
    // Decoupled from `scaleFullP` (which stays at 0.45 so the scale curve and
    // the history-reveal lock-in settle cleanly there). The 0.05 of progress
    // between scaleFullP and panelContractionOnsetP is the HOLD BEAT — the
    // breath between "the conversation dissolved" and "now it becomes an
    // object." Track A's tails complete invisibly inside this window; the
    // panel bounds are bit-identical (still full-screen) through p=0.50.
    //
    // The contraction begins with a C¹ eased shoulder over
    // [panelContractionOnsetP, panelContractionEaseEndP]: cubic Hermite with
    // zero velocity at the onset (so the curve joins the hold's stillness at
    // zero velocity — seamless) and the full linear contraction rate at the
    // shoulder's end (so the bulk of the contraction proceeds at the same
    // pace it would have without easing — the shoulder is an entry, not a
    // slowdown of the whole motion). After the shoulder, linear to 1.0.
    //
    // Why this matters: at p=0.50 the gesture transitions from a held still
    // state into the contraction. A velocity discontinuity here would be a
    // visible lurch — most perceptible kind of kink because the eye is
    // settled on a still frame and then motion erupts. The eased shoulder
    // makes the hold→contraction read as a breath resolving into motion.
    //
    // Geometry unchanged: the contraction is still bottom-anchored,
    // aspect-changing, vertical-first (height precedes width at 0.62). Only
    // the entry velocity profile is smoothed.
    static let panelContractionOnsetP: CGFloat = 0.50
    static let panelContractionEaseEndP: CGFloat = 0.55

    static func panelHeightCurve(_ p: CGFloat) -> CGFloat {
        if p <= panelContractionOnsetP { return 0 }
        if p >= 1.0 { return 1 }

        // Slope of the pure-linear contraction from onset to 1.0. The eased
        // shoulder ramps velocity from 0 at the onset to this slope at the
        // shoulder's end, then the linear segment continues at this same
        // slope — so the post-shoulder contraction proceeds at the rate a
        // pure-linear curve from onset would have, just delayed slightly by
        // the gentle entry.
        let postOnsetSlope = 1.0 / (1.0 - panelContractionOnsetP)
        let shoulderSpan = panelContractionEaseEndP - panelContractionOnsetP
        let yAtEaseEnd = postOnsetSlope * shoulderSpan

        if p <= panelContractionEaseEndP {
            // Cubic Hermite shoulder:
            //   y_a = 0, m_a = 0 (zero-velocity start; matches the hold)
            //   y_b = yAtEaseEnd, m_b = postOnsetSlope (matches linear past shoulder)
            // Monotone non-decreasing, no overshoot, C¹ at both endpoints.
            let t = (p - panelContractionOnsetP) / shoulderSpan
            let t2 = t * t
            let t3 = t2 * t
            let h01 = -2 * t3 + 3 * t2
            let h11 =      t3 -     t2
            return h01 * yAtEaseEnd + h11 * shoulderSpan * postOnsetSlope
        }

        // Linear from (easeEnd, yAtEaseEnd) to (1.0, 1.0) at the same slope.
        return yAtEaseEnd + postOnsetSlope * (p - panelContractionEaseEndP)
    }

    // Item C6 — panelWidthCurve eased onset (closes the kink-ledger entry).
    //
    // Width contracts from viewportW (393pt) → cellWidth (350pt) = 43pt of
    // horizontal travel past p=0.62 — confirmed exercised, so the kink at
    // p=0.62 IS a visible-motion kink and gets the same cubic-Hermite shoulder
    // treatment we used for panelHeightCurve. No co-onset at p=0.62 (verified:
    // pinkMask in end-shoulder by 0.62, greyMask in linear segment, dissolve
    // held, blur held, top-fade held, panel-height in linear) — single-channel
    // onset, just ease its entry.
    //
    // Same geometry as panelHeightCurve's shoulder: zero velocity at onset,
    // full linear rate by shoulder end, linear from shoulder-end to 1.0.
    private static let panelWidthEaseEndP: CGFloat = 0.67

    static func panelWidthCurve(_ p: CGFloat) -> CGFloat {
        if p <= panelWidthOnsetP { return 0 }
        if p >= 1.0 { return 1 }
        let postOnsetSlope = 1.0 / (1.0 - panelWidthOnsetP)
        let shoulderSpan = panelWidthEaseEndP - panelWidthOnsetP
        let yAtEaseEnd = postOnsetSlope * shoulderSpan
        if p <= panelWidthEaseEndP {
            let t = (p - panelWidthOnsetP) / shoulderSpan
            let t2 = t * t
            let t3 = t2 * t
            let h01 = -2 * t3 + 3 * t2
            let h11 =      t3 -     t2
            return h01 * yAtEaseEnd + h11 * shoulderSpan * postOnsetSlope
        }
        return yAtEaseEnd + postOnsetSlope * (p - panelWidthEaseEndP)
    }

    static let pinkMaskRecedeOnsetP: CGFloat = 0.50
    static let pinkMaskRecedeFullP: CGFloat = 0.65
    // Item E3: grey reveal onset moved 0.75 → 0.54 to match reference's
    // staggered timing (pink ~0.53, grey ~0.54 — near-co-onset). Eased
    // shoulders close greyMask's logged kinks at the same time
    // ("finish the channel you're in").
    static let greyMaskRecedeOnsetP: CGFloat = 0.54
    static let greyMaskRecedeFullP: CGFloat = 0.90

    // Pink-mask recede shoulders — co-onset symmetry with panelContractionOnset.
    //
    // Item B1' (pinkMask kink fix). The pinkMask alpha was originally linear with
    // hard-clamped endpoints; its onset at p=0.50 had a velocity discontinuity
    // (derivative jumped 0 → −6.67 at the start of recede) — identical in form
    // to the panelHeightCurve kink we eliminated. Critically, BOTH channels
    // activate at the same instant (p=0.50). Smoothing only one of two
    // simultaneous onsets left the joint event asymmetric: the panel motion
    // eased while the mask reveal popped. The fix is to ease BOTH channels with
    // matched velocity profiles so the joint onset reads as a single smooth event.
    //
    // Form: linear recede [1.0 → 0.0] over [onset, full], with cubic-Hermite
    // shoulders at BOTH endpoints (the channel itself is the seam we're in;
    // C¹ symmetry on the channel is the right fix while we're touching it).
    //   Onset shoulder span:  [0.50, 0.55]  (matched to panelContractionOnset
    //                                         shoulder — the two p=0.50 channels
    //                                         share identical onset velocity)
    //   Linear middle:        [0.55, 0.60]  at the original recede slope (−6.67)
    //   End shoulder span:    [0.60, 0.65]  decelerating to zero velocity at full
    //
    // Hermite shoulder mechanics (same construction as panelHeightCurve):
    //   Onset: tangent 0 at p=0.50, tangent = recede slope at p=0.55.
    //          Knot y values: (0.50, 1.0) → (0.55, 0.667).
    //   End:   tangent = recede slope at p=0.60, tangent 0 at p=0.65.
    //          Knot y values: (0.60, 0.333) → (0.65, 0.0).
    // Symmetric construction: y_55 + y_60 = 1.0; total area under the curve
    // matches the original linear (shoulder areas cancel by symmetry), so the
    // accumulated recede progress is preserved.
    //
    // Guarantees: C¹ continuous (matching tangents at every transition),
    // monotonic non-decreasing (alpha only decreases — mask only ever recedes,
    // never re-covers), no overshoot (Hermite passes exactly through knots).
    // Pure function of p — reverse pinch retraces identical values.
    //
    // Kink ledger (deferred — fix at each channel's seam-verification round):
    //   - pinkMaskAlpha end at p=0.65  → FIXED here (folded into 'finish the
    //                                    channel you're in')
    //   - panelWidthCurve at p=0.62     → Track B contraction seam
    //   - greyMaskAlpha onset at p=0.75 → Track B gradient reveal seam
    //   - greyMaskAlpha end at p=0.90   → Track B gradient reveal seam
    //   - topFadeBoundary math kink at p=0.50 → BENIGN (output clamped at 1.0;
    //                                            no visible motion at the kink)
    //
    // Principle banked: a velocity kink only matters where it produces visible
    // motion. If the channel's output is clamped/saturated across the kink, the
    // discontinuity is invisible and doesn't require fixing.

    private static let pinkMaskOnsetEaseEndP: CGFloat = 0.55
    private static let pinkMaskEndEaseStartP: CGFloat = 0.60

    static func pinkMaskAlpha(_ p: CGFloat) -> CGFloat {
        if p <= pinkMaskRecedeOnsetP { return 1.0 }
        if p >= pinkMaskRecedeFullP { return 0.0 }

        // Recede rate = the linear-curve's slope across the full recede window.
        // The eased shoulders bracket this rate; the linear middle proceeds at
        // exactly this rate so the overall recede progress matches the original.
        let recedeSlope = -1.0 / (pinkMaskRecedeFullP - pinkMaskRecedeOnsetP)
        let onsetShoulderSpan = pinkMaskOnsetEaseEndP - pinkMaskRecedeOnsetP
        let endShoulderSpan = pinkMaskRecedeFullP - pinkMaskEndEaseStartP

        // Linear-middle endpoints — chosen so the middle's slope equals
        // recedeSlope (the linear shoulder→middle and middle→shoulder joins
        // are C¹). y_55 = 0.667, y_60 = 0.333 for the canonical 0.05/0.05/0.05 split.
        let yAtOnsetEaseEnd = 1.0 + recedeSlope * onsetShoulderSpan
        let yAtEndEaseStart = recedeSlope * (pinkMaskRecedeFullP - pinkMaskEndEaseStartP) * -1.0
        // ^ = -recedeSlope * endShoulderSpan, computed positively for clarity

        if p <= pinkMaskOnsetEaseEndP {
            // Onset shoulder: cubic Hermite (1.0, m=0) → (yAtOnsetEaseEnd, m=recedeSlope)
            let t = (p - pinkMaskRecedeOnsetP) / onsetShoulderSpan
            let t2 = t * t
            let t3 = t2 * t
            let h00 =  2 * t3 - 3 * t2 + 1
            let h01 = -2 * t3 + 3 * t2
            let h11 =      t3 -     t2
            // h10 term contributes 0 (m_a = 0)
            return h00 * 1.0 + h01 * yAtOnsetEaseEnd + h11 * onsetShoulderSpan * recedeSlope
        }

        if p <= pinkMaskEndEaseStartP {
            // Linear middle: from (0.55, yAtOnsetEaseEnd) at recedeSlope
            return yAtOnsetEaseEnd + recedeSlope * (p - pinkMaskOnsetEaseEndP)
        }

        // End shoulder: cubic Hermite (yAtEndEaseStart, m=recedeSlope) → (0.0, m=0)
        let t = (p - pinkMaskEndEaseStartP) / endShoulderSpan
        let t2 = t * t
        let t3 = t2 * t
        let h00 =  2 * t3 - 3 * t2 + 1
        let h10 =      t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        // h11 term contributes 0 (m_b = 0)
        return h00 * yAtEndEaseStart + h10 * endShoulderSpan * recedeSlope + h01 * 0.0
    }

    // Grey-mask climbing reveal — item E3 + kink-ledger closure.
    //
    // Returns the value used as a CAGradientLayer mask location, NOT a view alpha.
    // Same conceptual shift as pinkMaskAlpha: one coherent curve is the mask's
    // moving boundary that produces the climbing reveal. The 'alpha' name is
    // retained for backward compatibility with the existing subscriber, but the
    // value is the mask boundary, mapped:
    //   alpha = 1.0 → boundary at top of mask → grey fully hidden (no reveal)
    //   alpha = 0.0 → boundary at bottom of mask → grey maximally revealed
    //
    // The reference shows grey appearing at the top ~p=0.54+, climbing down as
    // the panel contracts. Matching that timing here. Symmetric Hermite shoulders
    // close greyMask's logged kinks (onset and end).
    //
    // Structure (analogous to pinkMaskAlpha):
    //   [0.54, 0.59]: onset shoulder (zero velocity at onset, recedeSlope at shoulder end)
    //   [0.59, 0.85]: linear middle at recedeSlope
    //   [0.85, 0.90]: end shoulder (recedeSlope at start, zero velocity at full)
    // Span = 0.36 (vs pink's 0.15); grey reveal is longer / slower than pink's,
    // matching reference's late-climbing grey character.
    //
    // Co-onset awareness: at p=0.54, greyMask begins climbing CONCURRENTLY with
    // panelContraction (already eased at p=0.50, mid-shoulder by p=0.54) and the
    // pinkMask climb (mid-shoulder at p=0.54). Three-way neighborhood — verified
    // via programmatic sweep covering this region.
    private static let greyMaskOnsetEaseEndP: CGFloat = 0.59
    private static let greyMaskEndEaseStartP: CGFloat = 0.85

    static func greyMaskAlpha(_ p: CGFloat) -> CGFloat {
        if p <= greyMaskRecedeOnsetP { return 1.0 }
        if p >= greyMaskRecedeFullP { return 0.0 }

        let recedeSlope = -1.0 / (greyMaskRecedeFullP - greyMaskRecedeOnsetP)
        let onsetShoulderSpan = greyMaskOnsetEaseEndP - greyMaskRecedeOnsetP
        let endShoulderSpan = greyMaskRecedeFullP - greyMaskEndEaseStartP
        let yAtOnsetEaseEnd = 1.0 + recedeSlope * onsetShoulderSpan
        let yAtEndEaseStart = -recedeSlope * (greyMaskRecedeFullP - greyMaskEndEaseStartP)

        if p <= greyMaskOnsetEaseEndP {
            let t = (p - greyMaskRecedeOnsetP) / onsetShoulderSpan
            let t2 = t * t
            let t3 = t2 * t
            let h00 =  2 * t3 - 3 * t2 + 1
            let h01 = -2 * t3 + 3 * t2
            let h11 =      t3 -     t2
            return h00 * 1.0 + h01 * yAtOnsetEaseEnd + h11 * onsetShoulderSpan * recedeSlope
        }
        if p <= greyMaskEndEaseStartP {
            return yAtOnsetEaseEnd + recedeSlope * (p - greyMaskOnsetEaseEndP)
        }
        let t = (p - greyMaskEndEaseStartP) / endShoulderSpan
        let t2 = t * t
        let t3 = t2 * t
        let h00 =  2 * t3 - 3 * t2 + 1
        let h10 =      t3 - 2 * t2 + t
        return h00 * yAtEndEaseStart + h10 * endShoulderSpan * recedeSlope
    }

    // Top-fade boundary curve (item A3+A4).
    //
    // Maps gesture progress p ∈ [0, 1] → vertical location y ∈ [0, 1] of the
    // CAGradientLayer mask's opaque stop (`locations[1]`). The fade band runs
    // from y=0 (fully transparent) to y=topFadeBoundary(p) (fully opaque);
    // below the boundary, content is unmasked.
    //
    // Shape: cluster-then-hold. The middle bands (B2..B5) fade together in a
    // short p-range, then the boundary slows dramatically as it approaches B6's
    // top edge, holding the recent-message anchor cleanly opaque until the
    // dissolve channel (A5) takes over at p=0.40. The hold is expressed as a
    // velocity slow-down, not a freeze — every value of p has nonzero ∂y/∂p so
    // a slow continuous pinch never feels stuck.
    //
    // Form: piecewise cubic Hermite spline through five knots, with tangents
    // chosen via the Fritsch-Carlson rule (harmonic mean of adjacent secants,
    // capped at 3× the smaller secant). This guarantees simultaneously:
    //   - C¹ continuity (matching velocity on both sides of each knot — no
    //     kinks that would read as visible jerks under a smooth pinch),
    //   - monotone non-decreasing (boundary never reverses → faded content
    //     never un-fades; reverse pinch retraces identical values),
    //   - no overshoot (Hermite passes exactly through the knots).
    //
    // Knot rationale:
    //   K0 (0.00, 0.10)  — resting fade boundary. B1's top is covered by the
    //                      gradient band at chat-rest; alpha at y=60/100/120
    //                      matches predicted 234·(1−α)+25·α to within ±2 lum.
    //   K1 (0.17, 0.167) — boundary just reaches B2's top edge. B2 onset.
    //   K2 (0.27, 0.700) — boundary past B5's top edge. End of the cluster:
    //                      B3, B4, B5 all engage in the steep middle segment.
    //   K3 (0.40, 0.833) — boundary touches B6's top exactly. B6 stays fully
    //                      opaque through all of [0, 0.40]; dissolve owns B6.
    //   K4 (0.50, 1.000) — mask fully descended. During [0.40, 0.50] the
    //                      top-fade and dissolve channels superpose on the
    //                      bottom region; tune A5 with this in mind.
    //
    // Tangents (Fritsch-Carlson):
    //   d₀ = 0.394, d₁ = 5.33, d₂ = 1.02, d₃ = 1.67  (secant slopes)
    //   m₀ = 0.394 (one-sided, = d₀)
    //   m₁ = 2·d₀·d₁ / (d₀+d₁) = 0.734
    //   m₂ = 2·d₁·d₂ / (d₁+d₂) = 1.710
    //   m₃ = 2·d₂·d₃ / (d₂+d₃) = 1.270
    //   m₄ = 1.670 (one-sided, = d₃)
    // All tangents strictly positive → no zero-velocity stretches at knots.
    static let topFadeBoundaryAtRest: CGFloat = 0.10
    static let topFadeBoundaryAtFull: CGFloat = 1.0
    static let topFadeFullAtP: CGFloat = 0.50

    private static let topFadeKnotsP: [CGFloat] = [0.00, 0.17, 0.27, 0.40, 0.50]
    private static let topFadeKnotsY: [CGFloat] = [0.10, 0.167, 0.700, 0.833, 1.000]
    private static let topFadeTangents: [CGFloat] = [0.394, 0.734, 1.710, 1.270, 1.670]

    static func topFadeBoundary(_ p: CGFloat) -> CGFloat {
        let ps = topFadeKnotsP
        let ys = topFadeKnotsY
        let ms = topFadeTangents

        if p <= ps[0] { return ys[0] }
        if p >= ps[ps.count - 1] { return ys[ys.count - 1] }

        var i = 0
        while i < ps.count - 1 && p > ps[i + 1] { i += 1 }

        let h = ps[i + 1] - ps[i]
        let t = (p - ps[i]) / h
        let t2 = t * t
        let t3 = t2 * t
        let h00 =  2 * t3 - 3 * t2 + 1
        let h10 =      t3 - 2 * t2 + t
        let h01 = -2 * t3 + 3 * t2
        let h11 =      t3 -     t2
        return h00 * ys[i] + h10 * h * ms[i] + h01 * ys[i + 1] + h11 * h * ms[i + 1]
    }

    override init(frame: CGRect) {
        self.bodyContent = ChatBubbleStackView()
        self.dormantBlur = UIVisualEffectView(effect: nil)
        self.dormantLabel = UILabel()
        self.scalingSurface = ScalingSurface()
        self.blurAnimator = UIViewPropertyAnimator(duration: 1, curve: .linear)
        super.init(frame: frame)

        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let topFadeMask = CAGradientLayer()
        topFadeMask.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,
            UIColor.black.cgColor
        ]
        topFadeMask.locations = [0.0, NSNumber(value: Float(Self.topFadeBoundary(0)))]
        topFadeMask.startPoint = CGPoint(x: 0.5, y: 0)
        topFadeMask.endPoint = CGPoint(x: 0.5, y: 1)
        layer.mask = topFadeMask

        scalingSurface.layer.anchorPoint = Self.scaleAnchor

        bodyContent.translatesAutoresizingMaskIntoConstraints = false
        dormantBlur.translatesAutoresizingMaskIntoConstraints = false

        dormantLabel.translatesAutoresizingMaskIntoConstraints = false
        dormantLabel.alpha = 0
        dormantLabel.font = Theme.Typography.destinationDate
        dormantLabel.textColor = Theme.Text.secondary
        dormantLabel.numberOfLines = 0
        dormantLabel.textAlignment = .center

        addSubview(scalingSurface)
        scalingSurface.addSubview(bodyContent)
        addSubview(dormantBlur)
        addSubview(dormantLabel)

        NSLayoutConstraint.activate([
            bodyContent.topAnchor.constraint(equalTo: scalingSurface.topAnchor),
            bodyContent.leadingAnchor.constraint(equalTo: scalingSurface.leadingAnchor),
            bodyContent.trailingAnchor.constraint(equalTo: scalingSurface.trailingAnchor),
            bodyContent.bottomAnchor.constraint(equalTo: scalingSurface.bottomAnchor),

            dormantBlur.topAnchor.constraint(equalTo: topAnchor),
            dormantBlur.leadingAnchor.constraint(equalTo: leadingAnchor),
            dormantBlur.trailingAnchor.constraint(equalTo: trailingAnchor),
            dormantBlur.bottomAnchor.constraint(equalTo: bottomAnchor),

            dormantLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dormantLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            dormantLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            dormantLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -20)
        ])

        // UIBlurEffect(.regular) produces a uniform Gaussian blur across the
        // effect view's bounds — not edge-priority. UIViewPropertyAnimator's
        // scrubbing trick (fractionComplete on a paused animator transitioning
        // effect nil → UIBlurEffect) is the only public API for continuous
        // blur intensity. The closure runs once at addAnimations to capture
        // the target effect; subsequent fractionComplete writes scrub between
        // the captured endpoints without re-running the closure.
        blurAnimator.addAnimations { [weak dormantBlur] in
            dormantBlur?.effect = UIBlurEffect(style: .regular)
        }
        blurAnimator.pausesOnCompletion = true

        // Internal subscriber 1: derive scale from p and write the surface
        // transform. The surface itself never knows about scale — it only
        // publishes p. This subscriber is structurally identical to the blur
        // subscriber; either can be removed/replaced without touching the SSoT.
        scalingSurface.subscribe { [weak self] p in
            guard let self else { return }
            let s = Self.scaleCurve(p)
            CATransaction.withSuppressedActions {
                self.scalingSurface.layer.transform = CATransform3DMakeScale(s, s, 1)
            }
        }

        // Internal subscriber 2: derive blur from p and scrub the animator.
        // Adding a third consumer (Track B bounds, label cross-fade, anything)
        // is still a subscribe call — the seam is preserved across the refactor.
        scalingSurface.subscribe { [weak self] p in
            self?.blurAnimator.fractionComplete = Self.blurCurve(p)
        }

        scalingSurface.subscribe { [weak self] p in
            guard let mask = self?.layer.mask as? CAGradientLayer else { return }
            CATransaction.withSuppressedActions {
                mask.locations = [0.0, NSNumber(value: Float(Self.topFadeBoundary(p)))]
            }
        }

        // Internal subscriber 4 (item A5/A8 — content dissolve + D1 body-out).
        //
        // The dissolve was originally applied to CSV.alpha to fade blur+content
        // together. With D1, the dormantLabel is now a child of panel (not CSV)
        // and needs to be controllable independently of the dissolve. So the
        // dissolve is applied to bodyContent AND dormantBlur separately, with
        // CSV.alpha staying at 1.0 (neutral container).
        //
        // The visual effect is unchanged: both bodyContent and dormantBlur ride
        // the same contentDissolveAlpha curve to the same floor (then to 0 in
        // the D1 body-out segment), producing identical end-of-A composite
        // (verified vs v23 banked values).
        scalingSurface.subscribe { [weak self] p in
            guard let self else { return }
            let a = Self.contentDissolveAlpha(p)
            self.bodyContent.alpha = a
            self.dormantBlur.alpha = a
            // dormantLabel.alpha is set by SandboxViewController's subscriber
            // (it's reparented to panel).
            // CSV.alpha (self.alpha) stays at 1.0.
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ContentScalerView is code-only; no NSCoder support")
    }

    // Manual layout for scalingSurface — Auto Layout's frame setter doesn't
    // reliably honor a non-default anchorPoint when bounds was zero at the
    // moment anchorPoint was assigned. Setting bounds + position by hand makes
    // the (frame, position, anchor) translation explicit.
    override func layoutSubviews() {
        super.layoutSubviews()
        scalingSurface.bounds = CGRect(origin: .zero, size: bounds.size)
        scalingSurface.layer.position = CGPoint(
            x: Self.scaleAnchor.x * bounds.width,
            y: Self.scaleAnchor.y * bounds.height
        )
        if let mask = layer.mask {
            CATransaction.withSuppressedActions {
                mask.frame = bounds
            }
        }
    }

    func configure(with conversation: Conversation, metadataHidden: Bool = false) {
        bodyContent.configure(with: conversation, metadataHidden: metadataHidden)
        dormantLabel.text = conversation.curatedSummary
    }

    func setProgress(_ p: CGFloat) {
        scalingSurface.setProgress(min(1, max(0, p)))
    }

    func subscribe(_ handler: @escaping (CGFloat) -> Void) {
        scalingSurface.subscribe(handler)
    }
}

// MARK: - ScalingSurface
//
// Owns the canonical p (normalized gesture progress, 0=chat-rest, 1=cell-rest).
// setProgress(_:) writes p and notifies subscribers. The surface itself does
// NOT compute or apply scale, blur, or any derived quantity — those are
// subscriber concerns. Adding a new consumer is purely a subscribe call.

@MainActor
private final class ScalingSurface: UIView {

    private(set) var progress: CGFloat = 0
    private var subscribers: [(CGFloat) -> Void] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("ScalingSurface is code-only; no NSCoder support")
    }

    func setProgress(_ p: CGFloat) {
        progress = p
        for handler in subscribers { handler(p) }
    }

    func subscribe(_ handler: @escaping (CGFloat) -> Void) {
        subscribers.append(handler)
        handler(progress)
    }
}

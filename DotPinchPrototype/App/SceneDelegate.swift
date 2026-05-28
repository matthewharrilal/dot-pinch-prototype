import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    // Flip to `false` to restore V2RootViewController as the app root.
    private static let sandboxMode = true

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = Theme.Page.surface
        window.rootViewController = V2RootViewController()
//        window.rootViewController = Self.sandboxMode
//            ? SandboxViewController()
//            : V2RootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }
}

// MARK: - SandboxViewController
//
// Drives the Track A primitive in isolation: a ContentScalerView with real
// chat content + a UIPinchGestureRecognizer feeding a single scalar to
// setScale(_:). No bounds animation, no blur, no cross-fade — those land later
// when this primitive is lifted into CellView.

@MainActor
final class GradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }
    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }
}

@MainActor
final class SandboxViewController: UIViewController {

    private let gradientView = GradientView()
    private let pinkMask = UIView()
    private let greyMask = UIView()
    private let panel = UIView()
    private let scaler = ContentScalerView()
    private let debugReadout = UILabel()
    private var gestureStartProgress: CGFloat = 0

    // Panel contraction constraints (mutated by the Track B subscriber).
    private var panelWidth: NSLayoutConstraint!
    private var panelHeight: NSLayoutConstraint!
    private var panelBottom: NSLayoutConstraint!

    private static let pinchFullScale: CGFloat = 0.3
    private static let logScaleSpan: CGFloat = -log(pinchFullScale)

    // Provisional sandbox geometry — calibrated for iPhone 16 / iOS 18 + the
    // reference's most-recent-conversation case (low slot). The mechanism is
    // agnostic: panel contracts toward whatever slot the cell has. The real
    // list at migration supplies the slot per conversation; the low-slot
    // appearance here is the stand-in, not a hardcoded rule.
    private static let viewportW: CGFloat = 393
    private static let viewportH: CGFloat = 852
    private static let safeAreaTopInset: CGFloat = 59
    private static let safeAreaBottomInset: CGFloat = 34
    private static let safeAreaH: CGFloat = viewportH - safeAreaTopInset - safeAreaBottomInset
    private static let cellWidth: CGFloat = 350    // (reference target ~352pt = 89.5% of viewport)
    private static let cellHeight: CGFloat = 226   // W/H ≈ 1.549 (reference target aspect ~1.56 — within 1% ✓)
    // Item C4 — cell rest slot position. cellBottomLift moved 50 → 195pt so the
    // cell-rest cell sits at y=77.1% of viewport (matching reference frame_0060's
    // "Today" card bottom position, sampled median across frames 0055-0060).
    // Was: cell.bot at 94.1% of viewport (cell jammed near screen bottom).
    // Now: cell.bot at 77.1% — lower-middle slot with pink field room below.
    // The contraction PATH is unchanged (eased Hermite shoulder values unchanged);
    // only the endpoint moves higher, so panel covers more distance per tH.
    private static let cellBottomLift: CGFloat = 195
    private static let cellCornerRadius: CGFloat = 28

    override func loadView() {
        super.loadView()
        view.backgroundColor = Theme.Page.surface
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        CATransaction.withSuppressedActions {
            pinkMask.layer.mask?.frame = pinkMask.bounds
            greyMask.layer.mask?.frame = greyMask.bounds
            panel.layer.shadowPath = UIBezierPath(
                roundedRect: panel.bounds,
                cornerRadius: panel.layer.cornerRadius
            ).cgPath
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        gradientView.translatesAutoresizingMaskIntoConstraints = false
        // Item E1' — gradient color distribution restructured to match the
        // reference's measured vertical color profile, now that the cell rests
        // at 77.1% of viewport (C4). Adds intermediate stops:
        //   0.00 (top y=0):   pure grey (V=73)
        //   0.50 (cell.top):  grey-medium (V=85) — keeps grey character above
        //                     the cell so the top edge contrasts with the
        //                     cell's surface fill (V=93, delta 8 → perceptible)
        //   0.55:             surface (5%-wide flat band just inside cell-top)
        //   0.85:             light-pink intermediate (S=16, V=77) — enables
        //                     non-linear pink saturation climb matching the
        //                     reference's S 11→16→24→29 profile
        //   1.00 (bot):       pure pink (V=80, S=29)
        // Below-cell pink visibility (S>=10) starts at Y≈77.5% (matching
        // reference's 77.4% with the C4 cell position).
        gradientView.gradientLayer.colors = [
            Theme.Page.top.cgColor,                    // 0.00: full grey
            Theme.Page.gradientGreyMid.cgColor,        // 0.50: grey-medium
            Theme.Page.surface.cgColor,                // 0.55: surface
            Theme.Page.gradientPinkLight.cgColor,      // 0.85: light pink
            Theme.Page.bottom.cgColor                  // 1.00: full pink
        ]
        gradientView.gradientLayer.locations = [0.0, 0.50, 0.55, 0.85, 1.0]
        gradientView.gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientView.gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        pinkMask.translatesAutoresizingMaskIntoConstraints = false
        pinkMask.backgroundColor = Theme.Page.surface
        // E3 climbing reveal: pinkMask gets a CAGradientLayer mask whose
        // location[0] controls the boundary between "opaque (pinkMask shows,
        // gradient hidden)" at the top and "transparent (pinkMask hidden,
        // gradient revealed)" at the bottom. As the boundary moves up (from
        // 1.0 → 0.0 via pinkMaskAlpha), pink reveals progressively from the
        // bottom of the mask area, climbing upward. Same mechanism family as
        // topFadeBoundary — proven C¹ shoulder-eased curve.
        let pinkReveal = CAGradientLayer()
        pinkReveal.colors = [
            UIColor.black.cgColor,                          // opaque: pinkMask shows
            UIColor.black.withAlphaComponent(0).cgColor     // transparent: pinkMask hidden, pink revealed
        ]
        pinkReveal.startPoint = CGPoint(x: 0.5, y: 0)
        pinkReveal.endPoint = CGPoint(x: 0.5, y: 1)
        pinkReveal.locations = [1.0, 1.0]  // initial: all clamped to opaque (no reveal)
        pinkMask.layer.mask = pinkReveal

        greyMask.translatesAutoresizingMaskIntoConstraints = false
        greyMask.backgroundColor = Theme.Page.surface
        // E3 climbing-down reveal: symmetric to pink. greyMask's mask has
        // transparent at top, opaque at bottom — the transparent boundary
        // moves DOWN as p increases (greyMaskAlpha 1 → 0), revealing grey
        // from the top first.
        let greyReveal = CAGradientLayer()
        greyReveal.colors = [
            UIColor.black.withAlphaComponent(0).cgColor,    // transparent: greyMask hidden, grey revealed
            UIColor.black.cgColor                            // opaque: greyMask shows
        ]
        greyReveal.startPoint = CGPoint(x: 0.5, y: 0)
        greyReveal.endPoint = CGPoint(x: 0.5, y: 1)
        greyReveal.locations = [0.0, 0.0]  // initial: all clamped to opaque (no reveal)
        greyMask.layer.mask = greyReveal

        panel.translatesAutoresizingMaskIntoConstraints = false
        panel.backgroundColor = Theme.Page.surface
        panel.layer.cornerRadius = Self.cellCornerRadius
        panel.clipsToBounds = true
        panel.layer.shadowColor = Theme.Cell.shadowColor
        panel.layer.shadowOffset = Theme.Cell.shadowOffset
        panel.layer.shadowRadius = Theme.Cell.shadowRadius
        panel.layer.shadowOpacity = 0

        debugReadout.translatesAutoresizingMaskIntoConstraints = false
        debugReadout.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        debugReadout.textColor = Theme.Text.secondary
        debugReadout.textAlignment = .right
        debugReadout.numberOfLines = 0

        view.addSubview(gradientView)
        view.addSubview(pinkMask)
        view.addSubview(greyMask)
        view.addSubview(panel)
        panel.addSubview(scaler)
        // D1 — re-parent dormantLabel to panel (was inside CSV via panel→CSV→label).
        // The label's POSITION needs to ride the panel's contracting bounds so it
        // stays centered in the cell card at every p (single source of truth: cell
        // geometry comes from panel.bounds, not from duplicated cellHeight constants).
        // Its ALPHA is independent of the dissolve which now applies to bodyContent
        // and dormantBlur (not CSV.alpha). System font for the placeholder per the
        // primitive-vs-integration line (serif/F3 is integration).
        scaler.dormantLabel.removeFromSuperview()
        scaler.dormantLabel.font = .systemFont(ofSize: 17, weight: .medium)
        panel.addSubview(scaler.dormantLabel)
        view.addSubview(debugReadout)

        panelWidth = panel.widthAnchor.constraint(equalToConstant: Self.viewportW)
        panelHeight = panel.heightAnchor.constraint(equalToConstant: Self.viewportH)
        panelBottom = panel.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        NSLayoutConstraint.activate([
            gradientView.topAnchor.constraint(equalTo: view.topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gradientView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gradientView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // greyMask covers the top grey band of the gradient (0.0–0.20 of viewport).
            greyMask.topAnchor.constraint(equalTo: view.topAnchor),
            greyMask.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            greyMask.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            greyMask.heightAnchor.constraint(equalToConstant: Self.viewportH * 0.20),

            // pinkMask covers the bottom pink band of the gradient (0.75–1.0 of viewport).
            pinkMask.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pinkMask.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pinkMask.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pinkMask.heightAnchor.constraint(equalToConstant: Self.viewportH * 0.25),

            panel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            panelBottom,
            panelWidth,
            panelHeight,

            scaler.widthAnchor.constraint(equalToConstant: Self.viewportW),
            scaler.heightAnchor.constraint(equalToConstant: Self.safeAreaH),
            scaler.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            scaler.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -Self.safeAreaBottomInset),

            // D1 — dormantLabel centered on panel; rides panel's contracting bounds.
            scaler.dormantLabel.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            scaler.dormantLabel.centerYAnchor.constraint(equalTo: panel.centerYAnchor),
            scaler.dormantLabel.leadingAnchor.constraint(greaterThanOrEqualTo: panel.leadingAnchor, constant: 20),
            scaler.dormantLabel.trailingAnchor.constraint(lessThanOrEqualTo: panel.trailingAnchor, constant: -20),

            debugReadout.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            debugReadout.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])

        if let first = DummyConversationLoader.load().first {
            scaler.configure(with: first, metadataHidden: true)
        }

        scaler.subscribe { [weak self, weak debugReadout] p in
            guard let scaler = self?.scaler else { return }
            debugReadout?.text = String(
                format: "p = %.3f\ns = %.3f\nblur = %.3f",
                p, scaler.scale, scaler.blurFraction
            )
        }

        scaler.subscribe { [weak self] p in
            guard let self else { return }
            let tH = ContentScalerView.panelHeightCurve(p)
            let tW = ContentScalerView.panelWidthCurve(p)
            self.panelWidth.constant = Self.viewportW + (Self.cellWidth - Self.viewportW) * tW
            self.panelHeight.constant = Self.viewportH + (Self.cellHeight - Self.viewportH) * tH
            self.panelBottom.constant = -Self.cellBottomLift * tH
            // E3 climbing reveal — set CAGradientLayer mask locations rather
            // than view.alpha. The same eased-shoulder curve we built for
            // pinkMaskAlpha/greyMaskAlpha is reinterpreted as the boundary
            // position of a moving gradient on the mask layer.
            let pinkBoundary = ContentScalerView.pinkMaskAlpha(p)
            let greyBoundary = ContentScalerView.greyMaskAlpha(p)
            if let pinkRevealLayer = self.pinkMask.layer.mask as? CAGradientLayer {
                CATransaction.withSuppressedActions {
                    // E3' transition-width sharpening (post-split verification).
                    // Previously locations = [boundary, 1.0]: alpha ramps linearly
                    // across the FULL mask area, leaving most of the mask half-
                    // opaque and veiling the underlying gradient pink. With the
                    // mask area at 25% of viewport but the area-below-cell only
                    // 22.9%, the geometric capacity was sufficient — the gap was
                    // pure veiling (measured: 100% transition-width, 0% reveal-
                    // extent contribution).
                    //
                    // New: locations = [boundary, boundary + transitionWidth],
                    // transitionWidth = 0.10. The transition band moves with the
                    // boundary as it climbs. At full reveal (boundary=0):
                    // locations = [0, 0.10] → top 10% of mask is gradient, bottom
                    // 90% is fully transparent. Pink visible in bottom 22.5% of
                    // viewport (within 0.1pp of reference 22.6%).
                    //
                    // The boundary position curve (the climbing timing and the
                    // p=0.50 eased onset) is UNCHANGED. This only changes the
                    // shape of the alpha ramp riding along the boundary.
                    let transitionWidth: CGFloat = 0.10
                    let topLoc = min(1.0, max(0.0, pinkBoundary))
                    let botLoc = min(1.0, max(0.0, pinkBoundary + transitionWidth))
                    pinkRevealLayer.locations = [NSNumber(value: Float(topLoc)), NSNumber(value: Float(botLoc))]
                }
            }
            if let greyRevealLayer = self.greyMask.layer.mask as? CAGradientLayer {
                CATransaction.withSuppressedActions {
                    // greyMask: boundary at locations[1] (top stop = transparent;
                    // bottom stop = opaque). As alpha goes 1→0, boundary goes 0→1
                    // (transparent zone grows downward, revealing grey from top).
                    let topBoundary = 1.0 - greyBoundary
                    greyRevealLayer.locations = [0.0, NSNumber(value: Float(topBoundary))]
                }
            }
        }

        // D1+D3 — label-in subscriber. Pure function of p, staggered after
        // body-out (which completes at p=0.91). Label fades in p=0.93→1.0.
        // The 0.02 gap between body-out and label-in is the "near-empty card"
        // beat per D3.
        scaler.subscribe { [weak scaler] p in
            scaler?.dormantLabel.alpha = ContentScalerView.labelInAlpha(p)
        }

        scaler.subscribe { [weak self] p in
            guard let self else { return }
            let m = ContentScalerView.shadowOpacityCurve(p)
            CATransaction.withSuppressedActions {
                self.panel.layer.shadowOpacity = Float(Theme.Cell.shadowOpacityCellRest * m)
            }
        }

        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)

        let states: [(Double, CGFloat, String)] = [
            (1.5,  0.00, "p00"),
            (4.0,  0.40, "p40"),
            (6.5,  0.44, "p44"),
            (9.0,  0.46, "p46"),
            (11.5, 0.48, "p48"),
            (14.0, 0.50, "p50"),
            (16.5, 0.52, "p52"),
            (19.0, 0.55, "p55"),
            (21.5, 0.60, "p60"),
            (24.0, 0.70, "p70"),
        ]
        for (t, p, _) in states {
            DispatchQueue.main.asyncAfter(deadline: .now() + t) { [weak self] in
                self?.scaler.setProgress(p)
            }
        }
    }

    @objc private func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .began:
            gestureStartProgress = scaler.progress
        case .changed:
            // pinch.scale ∈ (0, ∞); guard against log(≤0). Δp via natural log
            // ratio: pinch in (scale<1) drives p up, pinch out (scale>1) drives
            // p down by the same magnitude for the same ratio change.
            let pinchScale = max(0.001, recognizer.scale)
            let deltaP = -log(pinchScale) / Self.logScaleSpan
            scaler.setProgress(gestureStartProgress + deltaP)
        default:
            break
        }
    }
}

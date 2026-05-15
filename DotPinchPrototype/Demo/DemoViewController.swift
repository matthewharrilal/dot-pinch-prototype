//
//  DemoViewController.swift
//  DotPinchPrototype
//
//  The demo screen. One fullscreen conversation surface + one Today slot rect
//  rendered as a guide. Pinch-IN collapses the surface into the slot; pinch-OUT
//  expands it back to fullscreen.
//
//  Per the user's bare-bones direction: minimum feature surface, maximum
//  engineering depth. There is no scroll view of past-day cards here, no
//  affordance icon, no haptics — only the conversation surface and the slot,
//  plus the substrate that makes the morph behave correctly.
//

import UIKit

final class DemoViewController: UIViewController {

    private let container = PinchMorphContainerView()
    private let conversationSurface = ConversationContentView()
    private let slotGuide = UIView()
    private let statusLabel = UILabel()

    private var interaction: PinchToMemoryInteraction?

    private var fullscreenRect: CGRect = .zero
    private var slotRect: CGRect = .zero

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.92, alpha: 1)

        // The page background — extends behind everything. The conversation surface
        // has its own gradient too (it IS the page in the fullscreen state); when
        // collapsed, this neutral background is exposed around it.
        view.accessibilityIdentifier = "DemoRoot"

        // The morphing container — its sole job is to host the conversation surface
        // and route hit-testing through the presentation layer during morphs.
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Slot guide — visual marker for where the Today slot is. Always visible
        // (when conversation is fullscreen it's hidden BEHIND the conversation;
        // when conversation is collapsed it's behind the same surface but at
        // matching size). Tier 3 detail: this would be replaced by an actual
        // memory timeline cell in a fuller version.
        slotGuide.layer.borderColor = UIColor(white: 0.3, alpha: 0.4).cgColor
        slotGuide.layer.borderWidth = 1.5
        slotGuide.layer.cornerRadius = 16
        slotGuide.layer.cornerCurve = .continuous
        slotGuide.backgroundColor = UIColor(white: 1, alpha: 0.85)
        slotGuide.accessibilityIdentifier = "TodaySlotGuide"
        container.addSubview(slotGuide)

        // The conversation surface — the morphing surface itself.
        container.addSubview(conversationSurface)

        // Status label for visible test signal — shows pinch state and progress.
        // Tier 3 craft would hide this; for the prototype it's useful as test instrumentation
        // (Maestro flows assert on it, and a human eye-balling the test can see what's
        // happening frame by frame).
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = UIColor(white: 0.2, alpha: 0.7)
        statusLabel.numberOfLines = 2
        statusLabel.text = "fullscreen — ready"
        statusLabel.accessibilityIdentifier = "StatusLabel"
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Compute the source/destination rects based on actual view dimensions.
        // Both are in `container`'s coordinate space.
        let safeArea = view.safeAreaInsets

        fullscreenRect = CGRect(
            x: 0,
            y: safeArea.top + 32,
            width: view.bounds.width,
            height: view.bounds.height - safeArea.top - 32 - safeArea.bottom
        )

        // The Today slot rect — modeled after the trajectory verdict's measured end
        // position. In the recording, the today_card settled at [461, 593] in image
        // coords (394×877 image); scaled to viewport, ~y=580 with height ~165.
        let slotWidth = view.bounds.width - 32
        let slotHeight: CGFloat = 140
        slotRect = CGRect(
            x: 16,
            y: max(view.bounds.height * 0.55, safeArea.top + 80),
            width: slotWidth,
            height: slotHeight
        )

        slotGuide.frame = slotRect

        if interaction == nil {
            conversationSurface.frame = fullscreenRect
            installInteraction()
        }
    }

    private func installInteraction() {
        let inter = PinchToMemoryInteraction(fullscreen: fullscreenRect, collapsedSlot: slotRect)
        inter.onStateChange = { [weak self] state in
            self?.updateStatus(for: state)
        }
        conversationSurface.addInteraction(inter)
        self.interaction = inter
    }

    private func updateStatus(for state: PinchMorphState) {
        let h = state.bounds.height
        let progressOut = (h - fullscreenRect.height) / (slotRect.height - fullscreenRect.height)
        let p = clamp(progressOut, 0, 1)
        statusLabel.text = String(
            format: "morph: %.0f%%   y=%.0f  h=%.0f  cornerR=%.1f",
            p * 100, state.bounds.minY, state.bounds.height, state.cornerRadius
        )
    }
}

// Phase0Spike07AutoLayoutSolverCost.swift
//
// Measures per-tick Auto Layout solver cost when heightConstraint.constant
// mutates under a representative cell hierarchy (labels + scrollView with
// 20 bubbles + pillContainer). Acceptance: < 2ms/tick; > 5ms triggers
// bounds-mutation fallback. Proxy measurement, not a real-time 120Hz harness.

import XCTest
@testable import DotPinchPrototype

@MainActor
final class Phase0Spike07AutoLayoutSolverCost: XCTestCase {

    private let viewport = CGRect(x: 0, y: 0, width: 390, height: 844)
    private let naturalHeight: CGFloat = 300
    private let bubbleCount = 20

    /// Mutate heightConstraint.constant + layoutIfNeeded() to force the
    /// solver. Reports total cost across 120 mutations averaged by XCTest.
    func testHeightConstraintMutationCost() {
        let window = UIWindow(frame: viewport)
        let cell = makeWindowedCell()
        window.addSubview(cell)
        cell.translatesAutoresizingMaskIntoConstraints = false
        let heightConstraint = cell.heightAnchor.constraint(equalToConstant: naturalHeight)
        NSLayoutConstraint.activate([
            cell.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            cell.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            cell.topAnchor.constraint(equalTo: window.topAnchor),
            heightConstraint
        ])
        window.makeKeyAndVisible()
        window.layoutIfNeeded()

        var factor: CGFloat = 1.0
        let chatRestExt = viewport.height / naturalHeight  // 2.81

        let measureOptions = XCTMeasureOptions()
        measureOptions.iterationCount = 10

        measure(metrics: [XCTClockMetric()], options: measureOptions) {
            // Each iteration: 120 mutations representing 1 second of 120Hz gesture.
            for _ in 0..<120 {
                factor = factor >= chatRestExt ? 1.0 : factor + 0.01
                heightConstraint.constant = naturalHeight * factor
                window.layoutIfNeeded()
            }
        }
        // Each XCTClockMetric result is total wall time for 120 mutations.
        // Per-tick cost = measured / 120.
    }

    /// Build a cell with labels at top, pillContainer at bottom, scrollView
    /// in the middle filled with bubbles.
    private func makeWindowedCell() -> UIView {
        let cell = UIView()
        cell.backgroundColor = .systemBackground
        cell.layer.cornerRadius = 25

        // Labels (date + topic preview + today indicator)
        let labelStack = UIStackView()
        labelStack.axis = .vertical
        labelStack.spacing = 4
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        for text in ["Mon, Jul 1", "Daily exercise nudge", "Today"] {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 17, weight: .regular)
            labelStack.addArrangedSubview(label)
        }
        cell.addSubview(labelStack)

        // Composer pill
        let pillContainer = UIView()
        pillContainer.translatesAutoresizingMaskIntoConstraints = false
        pillContainer.backgroundColor = .secondarySystemBackground
        pillContainer.layer.cornerRadius = 22
        let placeholder = UILabel()
        placeholder.text = "Share with Dot…"
        placeholder.font = .systemFont(ofSize: 16)
        placeholder.textColor = .placeholderText
        placeholder.translatesAutoresizingMaskIntoConstraints = false
        pillContainer.addSubview(placeholder)
        cell.addSubview(pillContainer)

        // Scroll view with bubbles
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        let bubbleStack = UIStackView()
        bubbleStack.axis = .vertical
        bubbleStack.spacing = 8
        bubbleStack.translatesAutoresizingMaskIntoConstraints = false
        for i in 0..<bubbleCount {
            let bubble = UIView()
            bubble.backgroundColor = (i % 2 == 0) ? .systemBlue : .systemGray5
            bubble.layer.cornerRadius = 18
            bubble.translatesAutoresizingMaskIntoConstraints = false
            let bubbleLabel = UILabel()
            bubbleLabel.text = "Message \(i): Good morning! Just a quick check-in."
            bubbleLabel.font = .systemFont(ofSize: 15)
            bubbleLabel.numberOfLines = 0
            bubbleLabel.translatesAutoresizingMaskIntoConstraints = false
            bubble.addSubview(bubbleLabel)
            NSLayoutConstraint.activate([
                bubbleLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
                bubbleLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
                bubbleLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
                bubbleLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8)
            ])
            bubbleStack.addArrangedSubview(bubble)
        }
        scrollView.addSubview(bubbleStack)
        cell.addSubview(scrollView)

        NSLayoutConstraint.activate([
            // labelStack at top
            labelStack.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 20),
            labelStack.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -20),
            labelStack.topAnchor.constraint(equalTo: cell.topAnchor, constant: 16),
            // pillContainer at bottom
            pillContainer.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 16),
            pillContainer.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -16),
            pillContainer.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -12),
            pillContainer.heightAnchor.constraint(equalToConstant: 44),
            placeholder.leadingAnchor.constraint(equalTo: pillContainer.leadingAnchor, constant: 20),
            placeholder.centerYAnchor.constraint(equalTo: pillContainer.centerYAnchor),
            // scrollView between labels and pill
            scrollView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -16),
            scrollView.topAnchor.constraint(equalTo: labelStack.bottomAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: pillContainer.topAnchor, constant: -8),
            // bubble stack inside scrollView
            bubbleStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            bubbleStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            bubbleStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            bubbleStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            bubbleStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        return cell
    }
}

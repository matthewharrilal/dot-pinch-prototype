// Production root view controller. Hosts TimelineCanvas (V2 dual-axis
// mechanics) bound to ConversationStore via TimelineDataSourceAdapter, and
// presents a ChatViewController overlay when a cell reaches morph-reveal.

import UIKit

@MainActor
final class V2RootViewController: UIViewController {

    private let store: ConversationStore
    private let adapter: TimelineDataSourceAdapter
    private let timelineCanvas: TimelineCanvas
    private var activeChatVC: ChatViewController?
    private var revealBlurOverlay: UIVisualEffectView?

    // MARK: - Init

    init() {
        let conversations = DummyConversationLoader.load()
        self.store = ConversationStore(initialConversations: conversations)
        self.adapter = TimelineDataSourceAdapter(
            store: self.store,
            naturalCellHeight: CellLayoutTuning.naturalCellHeight
        )
        self.timelineCanvas = TimelineCanvas()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("V2RootViewController does not support NSCoder")
    }

    // MARK: - Lifecycle

    override func loadView() {
        super.loadView()
        view.backgroundColor = Theme.Page.surface
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        timelineCanvas.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(timelineCanvas)
        // Canvas extends edge-to-edge AND under the status bar so the page
        // gradient fills the screen; chat-rest cell's top corners hide
        // behind the status bar by design (§10.13 + §0.4). cornerRadius is
        // locked at 25pt and NOT animated.
        NSLayoutConstraint.activate([
            timelineCanvas.topAnchor.constraint(equalTo: view.topAnchor),
            timelineCanvas.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            timelineCanvas.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            timelineCanvas.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        timelineCanvas.dataSource = adapter
        timelineCanvas.reloadData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        timelineCanvas.addGestureRecognizer(tap)

        timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
            self?.revealChat(forCellAt: cellIndex)
        }
    }

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let viewportPoint = recognizer.location(in: timelineCanvas)
        let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
        guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
        guard activeChatVC == nil else { return }
        timelineCanvas.animateCameraToChatRest(forCellAt: idx)
    }

    private func revealChat(forCellAt index: Int) {
        guard activeChatVC == nil else { return }
        guard index < store.conversations.count else { return }
        let conversation = store.conversations[index]

        let chatVC = ChatViewController()
        addChild(chatVC)
        chatVC.view.translatesAutoresizingMaskIntoConstraints = false
        chatVC.view.alpha = 0
        view.addSubview(chatVC.view)
        NSLayoutConstraint.activate([
            chatVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            chatVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            chatVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            chatVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        chatVC.didMove(toParent: self)
        chatVC.configure(with: conversation)
        chatVC.view.layoutIfNeeded()
        activeChatVC = chatVC

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.alpha = 0
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        revealBlurOverlay = blur

        UIView.animate(withDuration: RevealTiming.blurFadeInDuration, delay: 0, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            blur.alpha = 1
        }, completion: nil)

        UIView.animate(withDuration: RevealTiming.crossFadeDuration, delay: RevealTiming.crossFadeDelay, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            chatVC.view.alpha = 1
            self.timelineCanvas.alpha = 0
        }, completion: nil)

        UIView.animate(withDuration: RevealTiming.blurFadeOutDuration, delay: RevealTiming.blurDwellDelay, options: [.curveEaseInOut, .allowUserInteraction], animations: {
            blur.alpha = 0
        }, completion: { _ in
            blur.removeFromSuperview()
            if self.revealBlurOverlay === blur { self.revealBlurOverlay = nil }
        })
    }
}

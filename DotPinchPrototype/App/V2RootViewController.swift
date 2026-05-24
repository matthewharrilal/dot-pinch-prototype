// Production root view controller. Hosts TimelineCanvas (V2 dual-axis
// mechanics) bound to ConversationStore via TimelineDataSourceAdapter, and
// presents a ChatViewController overlay when a cell reaches morph-reveal.

import UIKit

@MainActor
final class V2RootViewController: UIViewController {

    private let store: ConversationStore
    private let adapter: TimelineDataSourceAdapter
    private let animationController: AnimationController
    private let timelineCanvas: TimelineCanvas
    private lazy var revealCoordinator = RevealCoordinator(parent: self, canvas: timelineCanvas)

    // MARK: - Init

    init() {
        let conversations = DummyConversationLoader.load()
        self.store = ConversationStore(initialConversations: conversations)
        self.adapter = TimelineDataSourceAdapter(
            store: self.store,
            naturalCellHeight: CellLayoutTuning.naturalCellHeight
        )
        let controller = AnimationController()
        self.animationController = controller
        self.timelineCanvas = TimelineCanvas(controller: controller, tuning: .standard)
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
        timelineCanvas.pinToSuperview(of: view)

        timelineCanvas.dataSource = adapter
        timelineCanvas.reloadData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        timelineCanvas.addGestureRecognizer(tap)

        timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
            guard let self else { return }
            guard cellIndex < self.store.conversations.count else { return }
            guard !self.revealCoordinator.isPresenting else { return }
            self.revealCoordinator.present(conversation: self.store.conversations[cellIndex])
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSceneWillDeactivate),
            name: UIScene.willDeactivateNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Scene observers

    @objc private func handleSceneWillDeactivate() {
        timelineCanvas.cancelInFlightAnimations()
        revealCoordinator.cancelInFlight()
    }

    // MARK: - Gesture handling

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let viewportPoint = recognizer.location(in: timelineCanvas)
        let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
        guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
        guard !revealCoordinator.isPresenting else { return }
        timelineCanvas.animateCameraToChatRest(forCellAt: idx)
    }
}

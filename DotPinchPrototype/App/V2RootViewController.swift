// Production root view controller. Hosts TimelineCanvas (V2 dual-axis
// mechanics) bound to ConversationStore via TimelineDataSourceAdapter, and
// presents a ChatViewController overlay when a cell reaches morph-reveal.
// Owns scene-lifecycle observers (willDeactivate + didActivate) + memory
// warning observer, orchestrates chatContent install + handoff via
// RevealCoordinator per §A topology.

import UIKit

@MainActor
final class V2RootViewController: UIViewController {

    private let store: ConversationStore
    private let adapter: TimelineDataSourceAdapter
    private let animationController: AnimationController
    private let timelineCanvas: TimelineCanvas
    private lazy var revealCoordinator: RevealCoordinator = {
        let coordinator = RevealCoordinator(parent: self, canvas: timelineCanvas)
        return coordinator
    }()

    /// Per-conversation state controllers, keyed by conversation UUID.
    /// Bounded by cell pool's effective lifetime; entries released when cells
    /// are evicted from the keyed pool (via cell.teardownChatContent /
    /// teardownChatContentForMemoryPressure).
    private var stateControllers: [UUID: ConversationStateController] = [:]

    /// Per-conversation activity tracker (Phase 12). Default-installed but
    /// idle unless something calls setActive(_:true) — the wiring is in place
    /// for future backend integration without forcing demo theater now.
    private let activityTracker = ConversationActivityTracker()

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
        timelineCanvas.pinToSuperview(of: view)

        timelineCanvas.dataSource = adapter
        timelineCanvas.reloadData()

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.cancelsTouchesInView = false
        timelineCanvas.addGestureRecognizer(tap)

        timelineCanvas.onMorphRevealReady = { [weak self] cellIndex in
            self?.handleMorphRevealReady(cellIndex: cellIndex)
        }

        installSceneObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Scene + memory observers

    private func installSceneObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleSceneWillDeactivate),
            name: UIScene.willDeactivateNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleSceneDidActivate),
            name: UIScene.didActivateNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleActivityDidChange(_:)),
            name: ConversationActivityTracker.activityDidChangeNotification,
            object: activityTracker
        )
    }

    @objc private func handleActivityDidChange(_ note: Notification) {
        guard let id = note.userInfo?["id"] as? UUID,
              let active = note.userInfo?["active"] as? Bool
        else { return }

        // Find the cell currently rendering this conversation and update its
        // dots indicator. Cells not in instantiatedCells are off-screen; their
        // state will refresh on next dequeue via configure().
        for (_, cell) in timelineCanvas.instantiatedCells where cell.activeConversationID == id {
            cell.setActiveIndicatorVisible(active)
        }
    }

    @objc private func handleSceneWillDeactivate() {
        timelineCanvas.cancelInFlightAnimations()
        revealCoordinator.cancelInFlight()
    }

    @objc private func handleSceneDidActivate() {
        revealCoordinator.completeHandoffIfPending()
    }

    @objc private func handleMemoryWarning() {
        timelineCanvas.flushPoolForMemoryPressure()
        flushOrphanedStateControllers()
    }

    /// Remove stateControllers whose conversation is no longer in the keyed pool
    /// (cells evicted; chatContent + per-cell state controllers gone).
    private func flushOrphanedStateControllers() {
        let activeIDs = Set(timelineCanvas.cellPoolByConversationID.keys)
        stateControllers = stateControllers.filter { activeIDs.contains($0.key) }
    }

    // MARK: - MorphRevealReady (parallel layout + present orchestration)

    private func handleMorphRevealReady(cellIndex: Int) {
        guard cellIndex < store.conversations.count else { return }
        guard !revealCoordinator.isPresenting else { return }

        let conversation = store.conversations[cellIndex]
        let stateController = stateController(for: conversation)

        // If this cell has been visited before, its cell.chatContent retains
        // whatever the user last typed / scrolled. Pull that into the state
        // controller BEFORE present so bindToChatVCAtInstall writes the
        // up-to-date state into the freshly-instantiated chatVC. Without this
        // sync, the handoff would overwrite cell.chatContent's preserved text
        // with the (stale) stateController contents.
        syncExistingChatContentIntoStateController(
            cellIndex: cellIndex,
            stateController: stateController
        )

        revealCoordinator.stateController = stateController

        installChatContentInParallel(
            conversation: conversation,
            cellIndex: cellIndex,
            stateController: stateController
        )
        revealCoordinator.present(conversation: conversation)
    }

    private func syncExistingChatContentIntoStateController(
        cellIndex: Int,
        stateController: ConversationStateController
    ) {
        guard let cell = timelineCanvas.instantiatedCells[cellIndex],
              let chatContent = cell.chatContentContainer
        else { return }
        stateController.composerText = chatContent.composer.composerTextField.text ?? ""
        stateController.scrollOffset = chatContent.bubbleStack.scrollContentOffset
    }

    /// Install cell.chatContent + bind state controller in parallel with chatVC
    /// instantiation (per §6 / Mitigation B). Dispatched async so the layout
    /// cost is split across runloop ticks (per §8.1 doubled-layout mitigation).
    private func installChatContentInParallel(
        conversation: Conversation,
        cellIndex: Int,
        stateController: ConversationStateController
    ) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let cell = self.timelineCanvas.instantiatedCells[cellIndex]
            else { return }
            cell.installChatContentIfNeeded(
                conversation: conversation,
                parentVC: self,
                stateController: stateController
            )
        }
    }

    private func stateController(for conversation: Conversation) -> ConversationStateController {
        if let existing = stateControllers[conversation.id] {
            return existing
        }
        let controller = ConversationStateController(conversationID: conversation.id)
        stateControllers[conversation.id] = controller
        return controller
    }

    // MARK: - Gesture handling

    @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
        let viewportPoint = recognizer.location(in: timelineCanvas)
        let pagePoint = timelineCanvas.pagePointFromViewportPoint(viewportPoint)
        guard let idx = timelineCanvas.cellIndex(atPagePoint: pagePoint) else { return }
        guard !revealCoordinator.isPresenting else { return }
        guard timelineCanvas.activeCellIndex == nil else { return }
        timelineCanvas.animateCameraToChatRest(forCellAt: idx)
    }
}

// Contract that lets PinchToMemoryInteraction (Interaction layer) drive the
// morph surface without depending on ConversationContentView (Demo layer).

import CoreGraphics
import QuartzCore

public protocol TimelineCompressible: AnyObject {

    /// Drive the morph at a normalized progress in [0, 1].
    /// 0 = baseline (chat fullscreen).
    /// 1 = fully compressed (destination state).
    /// Implementations clamp progress internally and wrap render-tree writes
    /// in CATransaction.setDisableActions(true).
    func setTimelineCompression(_ progress: CGFloat)
}

import Foundation

@MainActor
protocol AnimatorProviding: AnyObject {
    var id: UUID { get }
    var state: AnimatorState { get }
    func updateAnimation(dt: TimeInterval)
    func reset()
}

@frozen
public enum AnimatorState: Equatable {
    case inactive
    case running
    case ended
}

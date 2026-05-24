enum EngagementState {
    case idle
    case engaged(completion: (() -> Void)?)
    case stopping
}

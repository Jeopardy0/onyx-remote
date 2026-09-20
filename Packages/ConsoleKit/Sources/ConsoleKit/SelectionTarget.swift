public enum SelectionTarget: Hashable, Sendable {
    case fixtures([Int])
    case group(Int)
    case all
    case none
}

/// Drives the connection chip in the top bar. Never silently fail — a
/// dropped connection or a rejected send should move here, not vanish.
public enum ConnectionState: Sendable, Equatable {
    case connected
    case connecting
    case offline(reason: String?)

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

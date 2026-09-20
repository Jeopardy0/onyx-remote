/// Inbound state from the console. Everything here must correspond to
/// something an adapter actually confirmed — the app must never claim more
/// than what's in `docs/ONYX_INTEGRATION.md` is really sent back.
public enum ConsoleFeedback: Sendable {
    /// Mirrors the console's own command-line text/status — the app never
    /// predicts this locally (see integration doc §1.3).
    case commandLine(text: String, statusText: String, isLive: Bool)
    case keyLED(NXKKey, isOn: Bool)
    case playback(PlaybackFeedback)
    case highlight(isOn: Bool)
    case acknowledged(ConsoleAction)
}

public struct PlaybackFeedback: Sendable, Equatable {
    public var id: Int
    public var name: String?
    public var level: Double?
    public var isRunning: Bool?

    public init(id: Int, name: String? = nil, level: Double? = nil, isRunning: Bool? = nil) {
        self.id = id
        self.name = name
        self.level = level
        self.isRunning = isRunning
    }
}

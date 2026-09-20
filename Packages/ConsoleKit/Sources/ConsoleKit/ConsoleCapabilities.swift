/// What a given `ConsoleAdapter` can actually do. The UI reads these to hide
/// or disable controls a particular console/adapter can't support, instead
/// of assuming every adapter behaves like Onyx.
public struct ConsoleCapabilities: Sendable, Equatable {
    public var liveFeedback: Bool
    public var readPatch: Bool
    public var writePatch: Bool
    public var commandLine: Bool
    public var playbackControl: Bool

    public init(liveFeedback: Bool, readPatch: Bool, writePatch: Bool, commandLine: Bool, playbackControl: Bool) {
        self.liveFeedback = liveFeedback
        self.readPatch = readPatch
        self.writePatch = writePatch
        self.commandLine = commandLine
        self.playbackControl = playbackControl
    }

    /// Everything on — used by the mock so every screen is exercisable in M0.
    public static let full = ConsoleCapabilities(
        liveFeedback: true, readPatch: true, writePatch: true, commandLine: true, playbackControl: true
    )

    /// No console reachable at all.
    public static let none = ConsoleCapabilities(
        liveFeedback: false, readPatch: false, writePatch: false, commandLine: false, playbackControl: false
    )
}

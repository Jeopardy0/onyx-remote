import Foundation
import PatchKit

/// A fully in-memory `ConsoleAdapter` so every screen is developable and
/// testable without a real Onyx console. Simulates command-line echo,
/// playback Go/Release, Highlight-based Locate, and connection drops.
public actor MockConsoleAdapter: ConsoleAdapter {
    public nonisolated let capabilities: ConsoleCapabilities

    public private(set) var connectionState: ConnectionState = .connecting
    public private(set) var patch: Patch
    public private(set) var playbacks: [Int: SamplePlayback]

    private var continuations: [UUID: AsyncStream<ConsoleFeedback>.Continuation] = [:]
    private var commandLineBuffer = ""

    public init(patch: Patch = SampleShow.patch, capabilities: ConsoleCapabilities = .full) {
        self.patch = patch
        self.capabilities = capabilities
        self.playbacks = Dictionary(uniqueKeysWithValues: SampleShow.playbacks.map { ($0.id, $0) })
    }

    public func connect() async {
        connectionState = .connecting
        try? await Task.sleep(for: .milliseconds(300))
        connectionState = .connected
    }

    public func disconnect() async {
        connectionState = .offline(reason: nil)
    }

    /// Test/demo hook for the "simulate a dropped connection" requirement —
    /// a real adapter would reach this state on its own; the mock needs to
    /// be told, since there's no real socket to fail.
    public func simulateDrop(reason: String = "Connection lost") {
        connectionState = .offline(reason: reason)
    }

    public func currentPatch() async -> Patch? {
        patch
    }

    public func feedbackStream() -> AsyncStream<ConsoleFeedback> {
        let (stream, continuation) = AsyncStream.makeStream(of: ConsoleFeedback.self)
        let id = UUID()
        continuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            guard let self else { return }
            Task { await self.removeContinuation(id) }
        }
        return stream
    }

    public func send(_ action: ConsoleAction) async {
        switch action {
        case .select(let target):
            broadcast(.commandLine(text: describe(target), statusText: "Live", isLive: true))
        case .setValue(let parameter, let value):
            broadcast(.commandLine(text: "@ \(parameter.name) \(Int(value))", statusText: "Live", isLive: true))
        case .record:
            broadcast(.commandLine(text: "RECORD", statusText: "Live", isLive: true))
        case .update:
            broadcast(.commandLine(text: "UPDATE", statusText: "Live", isLive: true))
        case .clear:
            commandLineBuffer = ""
            broadcast(.commandLine(text: "", statusText: "FREE", isLive: true))
        case .locate(let fixtureIDs):
            guard !fixtureIDs.isEmpty else { break }
            broadcast(.highlight(isOn: true))
        case .go(let playbackID):
            goPlayback(playbackID)
        case .release(let playbackID):
            releasePlayback(playbackID)
        case .pressKey(let key):
            guard key.hasDocumentedOSCAddress else { return }
            handleKey(key)
        }
        broadcast(.acknowledged(action))
    }

    // MARK: - Simulation helpers

    private func describe(_ target: SelectionTarget) -> String {
        switch target {
        case .fixtures(let ids) where ids.count == 1:
            return "\(ids[0])"
        case .fixtures(let ids):
            return ids.map(String.init).joined(separator: " + ")
        case .group(let id):
            return "GROUP \(id)"
        case .all:
            return "."
        case .none:
            return "0"
        }
    }

    private func handleKey(_ key: NXKKey) {
        switch key {
        case .enter:
            broadcast(.commandLine(text: commandLineBuffer, statusText: "Live", isLive: true))
            commandLineBuffer = ""
        case .clear:
            commandLineBuffer = ""
            broadcast(.commandLine(text: "", statusText: "FREE", isLive: true))
        case .backspace:
            if !commandLineBuffer.isEmpty { commandLineBuffer.removeLast() }
            broadcast(.commandLine(text: commandLineBuffer, statusText: "Live", isLive: true))
        case .highLight:
            broadcast(.highlight(isOn: true))
        default:
            if !commandLineBuffer.isEmpty { commandLineBuffer += " " }
            commandLineBuffer += key.label
            broadcast(.commandLine(text: commandLineBuffer, statusText: "Live", isLive: true))
        }
        broadcast(.keyLED(key, isOn: true))
    }

    private func goPlayback(_ id: Int) {
        guard var playback = playbacks[id] else { return }
        playback.state = .running(cue: 1)
        playback.level = 1.0
        playbacks[id] = playback
        broadcast(.playback(PlaybackFeedback(id: id, name: playback.name, level: playback.level, isRunning: true)))
    }

    private func releasePlayback(_ id: Int) {
        guard var playback = playbacks[id] else { return }
        playback.state = .stopped
        playback.level = 0
        playbacks[id] = playback
        broadcast(.playback(PlaybackFeedback(id: id, name: playback.name, level: 0, isRunning: false)))
    }

    private func broadcast(_ feedback: ConsoleFeedback) {
        for continuation in continuations.values {
            continuation.yield(feedback)
        }
    }

    private func removeContinuation(_ id: UUID) {
        continuations.removeValue(forKey: id)
    }
}

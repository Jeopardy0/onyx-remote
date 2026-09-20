import ConsoleKit
import Observation
import PatchKit

/// Bridges an async-actor `ConsoleAdapter` into plain `@Observable` state
/// SwiftUI can bind to. This is the only place in the app target that talks
/// to a `ConsoleAdapter` directly — screens go through `AppModel`.
@MainActor
@Observable
final class ConsoleSession {
    let capabilities: ConsoleCapabilities

    private(set) var connectionState: ConnectionState = .connecting
    private(set) var commandLineText: String = ""
    private(set) var commandLineStatus: String = "FREE"
    private(set) var highlightOn: Bool = false
    private(set) var playbacks: [Int: SamplePlayback]

    private let adapter: any ConsoleAdapter
    private var feedbackTask: Task<Void, Never>?
    private var pollTask: Task<Void, Never>?

    init(adapter: any ConsoleAdapter) {
        self.adapter = adapter
        self.capabilities = adapter.capabilities
        self.playbacks = Dictionary(uniqueKeysWithValues: SampleShow.playbacks.map { ($0.id, $0) })

        Task { await adapter.connect() }

        feedbackTask = Task { [weak self] in
            guard let self else { return }
            let stream = await adapter.feedbackStream()
            for await feedback in stream {
                self.apply(feedback)
            }
        }

        // ConsoleAdapter exposes connectionState as an actor-isolated
        // property rather than a stream (see ConsoleKit/ConsoleAdapter.swift);
        // polling is simple and good enough for a chip that only needs to
        // reflect state within a few hundred ms.
        pollTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                let state = await adapter.connectionState
                if self.connectionState != state {
                    self.connectionState = state
                }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    deinit {
        feedbackTask?.cancel()
        pollTask?.cancel()
    }

    func send(_ action: ConsoleAction) {
        Task { await adapter.send(action) }
    }

    func currentPatch() async -> Patch? {
        await adapter.currentPatch()
    }

    private func apply(_ feedback: ConsoleFeedback) {
        switch feedback {
        case .commandLine(let text, let status, _):
            commandLineText = text
            if !status.isEmpty { commandLineStatus = status }
        case .highlight(let isOn):
            highlightOn = isOn
        case .playback(let playbackFeedback):
            if var playback = playbacks[playbackFeedback.id] {
                if let level = playbackFeedback.level { playback.level = level }
                if let isRunning = playbackFeedback.isRunning {
                    playback.state = isRunning ? .running(cue: 1) : .stopped
                }
                playbacks[playbackFeedback.id] = playback
            }
        case .keyLED, .acknowledged:
            break
        }
    }
}

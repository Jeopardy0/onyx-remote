#if canImport(Network)
import ConsoleKit
import Foundation
import PatchKit

/// The real Onyx `ConsoleAdapter`. M1 scope only: keypad key presses,
/// Locate via Highlight, and per-playback Go/Release via Playback Pages
/// (see docs/ONYX_INTEGRATION.md §1.4 for why Playback Pages rather than the
/// main playback block). Selection/value-entry/record/update land in M3.
///
/// Apple-only (`Network.framework` via `OnyxUDPTransport`); cannot be
/// exercised outside Xcode/a real console — see docs/PLAN.md M1 acceptance.
public actor OnyxConsoleAdapter: ConsoleAdapter {
    public nonisolated let capabilities = ConsoleCapabilities(
        liveFeedback: true,
        readPatch: false, // No verified OSC/CITP patch read path yet — see integration doc §4.
        writePatch: false,
        commandLine: true,
        playbackControl: true // Per the OSC mapping PDF this requires an Onyx playback license.
    )

    public private(set) var connectionState: ConnectionState = .offline(reason: nil)

    private let transport: OnyxUDPTransport
    private var feedbackContinuations: [UUID: AsyncStream<ConsoleFeedback>.Continuation] = [:]
    private var monitorTask: Task<Void, Never>?

    public init(host: String, port: UInt16) {
        self.transport = OnyxUDPTransport(host: host, port: port)
    }

    public func connect() async {
        connectionState = .connecting
        await transport.start()
        monitorTask?.cancel()
        monitorTask = Task { [weak self] in
            await self?.monitorTransport()
        }
    }

    public func disconnect() async {
        monitorTask?.cancel()
        monitorTask = nil
        await transport.stop()
        connectionState = .offline(reason: nil)
    }

    public func feedbackStream() -> AsyncStream<ConsoleFeedback> {
        let (stream, continuation) = AsyncStream.makeStream(of: ConsoleFeedback.self)
        let id = UUID()
        feedbackContinuations[id] = continuation
        continuation.onTermination = { [weak self] _ in
            Task { await self?.removeContinuation(id) }
        }
        return stream
    }

    public func send(_ action: ConsoleAction) async {
        switch action {
        case .pressKey(let key):
            guard let address = OnyxAddressBook.executeAddress(for: key) else { return }
            await sendButtonPress(address)
            broadcast(.acknowledged(action))

        case .go(let playbackID):
            let location = OnyxAddressBook.playbackPageLocation(forPlaybackID: playbackID)
            await sendButtonPress(OnyxAddressBook.playbackPageAddress(page: location.page, button: location.button, action: .go))
            broadcast(.acknowledged(action))

        case .release(let playbackID):
            let location = OnyxAddressBook.playbackPageLocation(forPlaybackID: playbackID)
            await sendButtonPress(OnyxAddressBook.playbackPageAddress(page: location.page, button: location.button, action: .release))
            broadcast(.acknowledged(action))

        case .locate(let fixtureIDs):
            guard !fixtureIDs.isEmpty else { return }
            await sendButtonPress(OnyxAddressBook.highlight)
            broadcast(.acknowledged(action))

        case .select, .setValue, .record, .update, .clear:
            // Not implemented until M3 (docs/PLAN.md) — these compose from
            // keypad digit presses per integration doc §1.3/§1.6, not a
            // single OSC message. Left unsent rather than guessed.
            break
        }
    }

    // MARK: - Transport plumbing

    private func monitorTransport() async {
        async let stateWatch: Void = watchTransportState()
        async let dataWatch: Void = watchIncomingDatagrams()
        _ = await (stateWatch, dataWatch)
    }

    private func watchTransportState() async {
        for await state in await transport.stateUpdates {
            if Task.isCancelled { return }
            switch state {
            case .ready: connectionState = .connected
            case .connecting: connectionState = .connecting
            case .idle: connectionState = .offline(reason: nil)
            case .failed(let reason): connectionState = .offline(reason: reason)
            }
        }
    }

    private func watchIncomingDatagrams() async {
        for await data in await transport.receivedDatagrams {
            if Task.isCancelled { return }
            guard let message = try? OSCCodec.decode(data), let feedback = Self.feedback(from: message) else { continue }
            broadcast(feedback)
        }
    }

    private func sendButtonPress(_ address: String) async {
        // OSC Execute addresses model a physical button: 1 on key-down, 0 on
        // key-up (integration doc §1.2) — a single message is not a press.
        await transport.send(OSCCodec.encode(OSCMessage(address: address, arguments: [.int32(1)])))
        try? await Task.sleep(for: .milliseconds(60))
        await transport.send(OSCCodec.encode(OSCMessage(address: address, arguments: [.int32(0)])))
    }

    private func removeContinuation(_ id: UUID) {
        feedbackContinuations.removeValue(forKey: id)
    }

    private func broadcast(_ feedback: ConsoleFeedback) {
        for continuation in feedbackContinuations.values {
            continuation.yield(feedback)
        }
    }

    private static func feedback(from message: OSCMessage) -> ConsoleFeedback? {
        switch message.address {
        case OnyxAddressBook.commandLineText:
            if case .some(.string(let text)) = message.arguments.first {
                return .commandLine(text: text, statusText: "", isLive: true)
            }
        case OnyxAddressBook.highlight:
            if case .some(.int32(let value)) = message.arguments.first {
                return .highlight(isOn: value != 0)
            }
        default:
            break
        }
        return nil
    }
}
#endif

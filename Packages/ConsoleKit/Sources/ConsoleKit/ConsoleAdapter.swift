import PatchKit

/// The one seam the UI is allowed to talk through. Only `OnyxKit` (or any
/// future console package) knows how an action actually reaches hardware;
/// everything here is protocol-agnostic.
///
/// Modeled as an `Actor` requirement so adapters can safely own mutable
/// connection state (sockets, reconnect timers, feedback caches) without the
/// UI needing to reason about thread-safety itself.
public protocol ConsoleAdapter: Actor {
    nonisolated var capabilities: ConsoleCapabilities { get }

    var connectionState: ConnectionState { get }

    /// Live inbound state (command line mirror, LEDs, playback feedback).
    /// Adapters without `liveFeedback` still vend a stream — it simply never
    /// yields anything, so UI code doesn't need to special-case capability
    /// checks at every call site.
    func feedbackStream() -> AsyncStream<ConsoleFeedback>

    func connect() async
    func disconnect() async

    /// Send one UI-originated action. Adapters must not throw away a send
    /// silently — failures should be reflected in `connectionState` or a
    /// `ConsoleFeedback` the UI can show.
    func send(_ action: ConsoleAction) async

    /// Current local patch, for adapters with `readPatch`/`writePatch`. The
    /// local `Patch` model in `PatchKit` remains the source of truth even
    /// when this is non-nil — this is a snapshot, not a live subscription.
    func currentPatch() async -> Patch?
}

public extension ConsoleAdapter {
    func currentPatch() async -> Patch? { nil }
}

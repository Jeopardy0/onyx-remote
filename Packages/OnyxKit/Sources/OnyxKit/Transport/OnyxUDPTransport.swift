#if canImport(Network)
import Foundation
import Network

/// Raw UDP transport for OSC datagrams. Knows nothing about OSC or Onyx
/// addresses — just connects, sends bytes, and yields received bytes, with
/// automatic reconnect/backoff on failure so the app never has to guess
/// whether a send actually went anywhere.
///
/// Apple-only (`Network.framework`); wrapped in `#if canImport(Network)` so
/// the rest of `OnyxKit` (the OSC codec, the address book) still builds and
/// tests on Linux CI. This file itself cannot be exercised outside Xcode —
/// it must be verified against a real console per docs/PLAN.md M1.
public actor OnyxUDPTransport {
    public enum State: Equatable, Sendable {
        case idle
        case connecting
        case ready
        case failed(String)
    }

    public private(set) var state: State = .idle

    private let host: NWEndpoint.Host
    private let port: NWEndpoint.Port
    private var connection: NWConnection?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0

    private let stateContinuation: AsyncStream<State>.Continuation
    public let stateUpdates: AsyncStream<State>

    private let datagramContinuation: AsyncStream<Data>.Continuation
    public let receivedDatagrams: AsyncStream<Data>

    public init(host: String, port: UInt16) {
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port) ?? 8000

        let (stateStream, stateCont) = AsyncStream.makeStream(of: State.self)
        self.stateUpdates = stateStream
        self.stateContinuation = stateCont

        let (dataStream, dataCont) = AsyncStream.makeStream(of: Data.self)
        self.receivedDatagrams = dataStream
        self.datagramContinuation = dataCont
    }

    public func start() {
        guard connection == nil else { return }
        setState(.connecting)

        let connection = NWConnection(host: host, port: port, using: .udp)
        self.connection = connection

        connection.stateUpdateHandler = { [weak self] newState in
            Task { await self?.handleConnectionState(newState) }
        }
        connection.start(queue: .global(qos: .userInitiated))
        receiveNext(on: connection)
    }

    public func stop() {
        reconnectTask?.cancel()
        reconnectTask = nil
        connection?.cancel()
        connection = nil
        setState(.idle)
    }

    public func send(_ data: Data) {
        connection?.send(content: data, completion: .contentProcessed { [weak self] error in
            guard let error else { return }
            Task { await self?.handleSendFailure(error) }
        })
    }

    // MARK: - Internals

    private func setState(_ newState: State) {
        state = newState
        stateContinuation.yield(newState)
    }

    private func handleConnectionState(_ newState: NWConnection.State) {
        switch newState {
        case .ready:
            reconnectAttempt = 0
            setState(.ready)
        case .failed(let error):
            setState(.failed(error.debugDescription))
            scheduleReconnect()
        case .waiting(let error):
            setState(.failed(error.debugDescription))
        default:
            break
        }
    }

    private func handleSendFailure(_ error: NWError) {
        setState(.failed(error.debugDescription))
        scheduleReconnect()
    }

    private func scheduleReconnect() {
        guard reconnectTask == nil else { return }
        let attempt = reconnectAttempt
        reconnectAttempt += 1
        let delaySeconds = min(30.0, pow(2.0, Double(attempt)))

        reconnectTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delaySeconds))
            guard !Task.isCancelled else { return }
            await self?.restart()
        }
    }

    private func restart() {
        reconnectTask = nil
        connection?.cancel()
        connection = nil
        start()
    }

    private func receiveNext(on connection: NWConnection) {
        connection.receiveMessage { [weak self] data, _, _, error in
            guard let self else { return }
            if let data, !data.isEmpty {
                Task { await self.yieldReceived(data) }
            }
            if error == nil {
                self.receiveNext(on: connection)
            }
        }
    }

    private func yieldReceived(_ data: Data) {
        datagramContinuation.yield(data)
    }
}
#endif

import XCTest
@testable import ConsoleKit

final class MockConsoleAdapterTests: XCTestCase {
    /// Pulls feedback events until one matches `match`, ignoring any
    /// interleaved events (e.g. `.keyLED`/`.acknowledged`) whose exact
    /// ordering relative to the event under test isn't part of the contract.
    private func nextMatching(
        _ iterator: inout AsyncStream<ConsoleFeedback>.AsyncIterator,
        _ match: (ConsoleFeedback) -> Bool
    ) async -> ConsoleFeedback? {
        while let feedback = await iterator.next() {
            if match(feedback) { return feedback }
        }
        return nil
    }

    func testConnectTransitionsToConnected() async {
        let adapter = MockConsoleAdapter()
        await adapter.connect()
        let state = await adapter.connectionState
        XCTAssertEqual(state, .connected)
    }

    func testSimulateDropSetsOfflineState() async {
        let adapter = MockConsoleAdapter()
        await adapter.connect()
        await adapter.simulateDrop(reason: "Network unreachable")
        let state = await adapter.connectionState
        XCTAssertEqual(state, .offline(reason: "Network unreachable"))
    }

    func testPressingDigitsAndEnterEchoesCommandLine() async {
        let adapter = MockConsoleAdapter()
        let stream = await adapter.feedbackStream()
        var iterator = stream.makeAsyncIterator()

        await adapter.send(.pressKey(.digit(1)))
        guard case .commandLine(let text, _, _) = await nextMatching(&iterator, {
            if case .commandLine = $0 { return true } else { return false }
        }) else {
            return XCTFail("expected command line feedback")
        }
        XCTAssertEqual(text, "1")

        await adapter.send(.pressKey(.enter))
        guard case .commandLine(let confirmedText, _, _) = await nextMatching(&iterator, {
            if case .commandLine = $0 { return true } else { return false }
        }) else {
            return XCTFail("expected command line feedback")
        }
        XCTAssertEqual(confirmedText, "1")
    }

    func testUndocumentedKeyIsIgnored() async {
        let adapter = MockConsoleAdapter()
        let stream = await adapter.feedbackStream()
        var iterator = stream.makeAsyncIterator()

        // swapProg has no documented OSC address (see NXKKey.hasDocumentedOSCAddress),
        // so the mock must not emit any feedback for it. Follow it with a
        // documented key and confirm THAT is the first thing to arrive.
        await adapter.send(.pressKey(.swapProg))
        await adapter.send(.pressKey(.digit(5)))

        guard case .commandLine(let text, _, _) = await nextMatching(&iterator, {
            if case .commandLine = $0 { return true } else { return false }
        }) else {
            return XCTFail("expected command line feedback")
        }
        XCTAssertEqual(text, "5")
    }

    func testGoMarksPlaybackRunning() async {
        let adapter = MockConsoleAdapter()
        let stream = await adapter.feedbackStream()
        var iterator = stream.makeAsyncIterator()

        await adapter.send(.go(playbackID: 2))
        guard case .playback(let feedback) = await iterator.next() else {
            return XCTFail("expected playback feedback")
        }
        XCTAssertEqual(feedback.id, 2)
        XCTAssertEqual(feedback.isRunning, true)
    }

    func testReleaseMarksPlaybackStopped() async {
        let adapter = MockConsoleAdapter()
        let stream = await adapter.feedbackStream()
        var iterator = stream.makeAsyncIterator()

        await adapter.send(.go(playbackID: 2))
        _ = await iterator.next() // playback running
        _ = await iterator.next() // acknowledged

        await adapter.send(.release(playbackID: 2))
        guard case .playback(let feedback) = await iterator.next() else {
            return XCTFail("expected playback feedback")
        }
        XCTAssertEqual(feedback.isRunning, false)
        XCTAssertEqual(feedback.level, 0)
    }

    func testLocateBroadcastsHighlightOn() async {
        let adapter = MockConsoleAdapter()
        let stream = await adapter.feedbackStream()
        var iterator = stream.makeAsyncIterator()

        await adapter.send(.locate(fixtureIDs: [1, 2]))
        guard case .highlight(let isOn) = await iterator.next() else {
            return XCTFail("expected highlight feedback")
        }
        XCTAssertTrue(isOn)
    }

    func testSampleShowPatchMatchesDesignReferenceCounts() async {
        let adapter = MockConsoleAdapter()
        let patch = await adapter.currentPatch()
        XCTAssertEqual(patch?.fixtures.count, 16)
        // Sum of every fixture's footprint is 210 (matching the "210/512 used"
        // caption in docs/design/patch-universe-map.jpg), but the intentional
        // Strobe 1 / Spot Mover 4 overlap (8 channels, 137-144) is double
        // counted in that raw sum — the de-duplicated distinct-channel count
        // PatchKit actually reports for the usage bar is 8 less.
        XCTAssertEqual(patch?.occupiedChannelCount(inUniverse: 1), 202)
        XCTAssertEqual(patch?.conflicts.count, 1)
    }
}

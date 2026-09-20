import XCTest
@testable import PatchKit

final class ConflictDetectorTests: XCTestCase {
    private func fixture(_ id: Int, universe: Int, address: Int, footprint: Int) -> Fixture {
        Fixture(id: id, name: "F\(id)", profileID: "led-wash", category: .wash, modeName: "8-ch", footprint: footprint, universe: universe, address: address)
    }

    func testNoConflictsWhenRangesDoNotOverlap() {
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 8), fixture(2, universe: 1, address: 9, footprint: 8)]
        XCTAssertTrue(ConflictDetector.conflicts(in: fixtures).isEmpty)
    }

    func testDetectsOverlapWithinSameUniverse() {
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 24), fixture(2, universe: 1, address: 17, footprint: 8)]
        let conflicts = ConflictDetector.conflicts(in: fixtures)
        XCTAssertEqual(conflicts.count, 1)
        XCTAssertEqual(conflicts[0].fixtureID, 1)
        XCTAssertEqual(conflicts[0].overlappingFixtureID, 2)
        XCTAssertEqual(conflicts[0].overlap, ChannelRange(start: 17, length: 8))
    }

    func testNoConflictAcrossDifferentUniversesEvenWithSameAddress() {
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 8), fixture(2, universe: 2, address: 1, footprint: 8)]
        XCTAssertTrue(ConflictDetector.conflicts(in: fixtures).isEmpty)
    }

    func testExactlyAdjacentRangesDoNotConflict() {
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 8), fixture(2, universe: 1, address: 9, footprint: 8)]
        XCTAssertTrue(ConflictDetector.conflicts(in: fixtures).isEmpty)
    }

    func testOccupiedChannelCountCountsOverlapOnce() {
        // 24-ch fixture at 1 and an 8-ch fixture fully inside it at 17-24:
        // union of channels used is still exactly 24, not 32.
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 24), fixture(2, universe: 1, address: 17, footprint: 8)]
        XCTAssertEqual(ConflictDetector.occupiedChannelCount(in: fixtures, universe: 1), 24)
    }

    func testOccupiedChannelCountIgnoresOtherUniverses() {
        let fixtures = [fixture(1, universe: 1, address: 1, footprint: 8), fixture(2, universe: 2, address: 1, footprint: 16)]
        XCTAssertEqual(ConflictDetector.occupiedChannelCount(in: fixtures, universe: 1), 8)
    }
}

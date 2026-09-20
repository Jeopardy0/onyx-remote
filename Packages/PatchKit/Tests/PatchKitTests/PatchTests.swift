import XCTest
@testable import PatchKit

final class PatchTests: XCTestCase {
    private func fixture(_ id: Int, universe: Int = 1, address: Int, footprint: Int = 8) -> Fixture {
        Fixture(id: id, name: "F\(id)", profileID: "led-wash", category: .wash, modeName: "8-ch", footprint: footprint, universe: universe, address: address)
    }

    func testAddFixtureRejectsDuplicateID() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        XCTAssertThrowsError(try patch.addFixture(fixture(1, address: 9))) { error in
            XCTAssertEqual(error as? PatchError, .fixtureIDAlreadyExists(1))
        }
    }

    func testAddFixtureRejectsAddressOutOfRange() {
        var patch = Patch()
        XCTAssertThrowsError(try patch.addFixture(fixture(1, address: 510, footprint: 8)))
    }

    func testReaddressMovesFixtureToNewUniverseAndAddress() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        try patch.readdress(id: 1, universe: 2, address: 100)
        let moved = try XCTUnwrap(patch.fixture(withID: 1))
        XCTAssertEqual(moved.universe, 2)
        XCTAssertEqual(moved.address, 100)
    }

    func testReaddressUnknownFixtureThrows() {
        var patch = Patch()
        XCTAssertThrowsError(try patch.readdress(id: 99, universe: 1, address: 1)) { error in
            XCTAssertEqual(error as? PatchError, .fixtureNotFound(99))
        }
    }

    func testRemoveFixtureUnpatchesIt() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        try patch.removeFixture(id: 1)
        XCTAssertNil(patch.fixture(withID: 1))
    }

    func testRenumberRejectsCollidingID() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        try patch.addFixture(fixture(2, address: 9))
        XCTAssertThrowsError(try patch.renumber(id: 1, to: 2)) { error in
            XCTAssertEqual(error as? PatchError, .fixtureIDAlreadyExists(2))
        }
    }

    func testRenumberSucceedsToFreeID() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        try patch.renumber(id: 1, to: 5)
        XCTAssertNil(patch.fixture(withID: 1))
        XCTAssertNotNil(patch.fixture(withID: 5))
    }

    func testDuplicateFixturePlacesCopyAtNextFreeAddressWithNewID() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        let copy = try patch.duplicateFixture(id: 1)
        XCTAssertEqual(copy.id, 2)
        XCTAssertEqual(copy.address, 9)
        XCTAssertEqual(copy.universe, 1)
    }

    func testConflictsSurfaceViaPatch() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1, footprint: 24))
        try patch.addFixture(fixture(2, address: 17, footprint: 8))
        XCTAssertEqual(patch.conflicts.count, 1)
        XCTAssertEqual(patch.conflicts(inUniverse: 2).count, 0)
    }

    func testCodableRoundTrip() throws {
        var patch = Patch()
        try patch.addFixture(fixture(1, address: 1))
        patch.addCustomProfile(FixtureProfile(id: "custom-1", name: "My Fixture", category: .other, modes: [FixtureMode(name: "4-ch", channelCount: 4)]))

        let data = try JSONEncoder().encode(patch)
        let decoded = try JSONDecoder().decode(Patch.self, from: data)
        XCTAssertEqual(decoded, patch)
    }
}

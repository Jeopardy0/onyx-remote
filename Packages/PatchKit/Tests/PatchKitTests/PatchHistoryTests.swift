import XCTest
@testable import PatchKit

final class PatchHistoryTests: XCTestCase {
    private func fixture(_ id: Int, address: Int) -> Fixture {
        Fixture(id: id, name: "F\(id)", profileID: "led-wash", category: .wash, modeName: "8-ch", footprint: 8, universe: 1, address: address)
    }

    func testUndoRevertsLastEdit() throws {
        var history = PatchHistory()
        try history.apply { try $0.addFixture(fixture(1, address: 1)) }
        XCTAssertEqual(history.current.fixtures.count, 1)

        XCTAssertTrue(history.undo())
        XCTAssertEqual(history.current.fixtures.count, 0)
    }

    func testRedoReappliesUndoneEdit() throws {
        var history = PatchHistory()
        try history.apply { try $0.addFixture(fixture(1, address: 1)) }
        _ = history.undo()

        XCTAssertTrue(history.redo())
        XCTAssertEqual(history.current.fixtures.count, 1)
    }

    func testNewEditClearsRedoStack() throws {
        var history = PatchHistory()
        try history.apply { try $0.addFixture(fixture(1, address: 1)) }
        _ = history.undo()
        try history.apply { try $0.addFixture(fixture(2, address: 9)) }

        XCTAssertFalse(history.canRedo)
        XCTAssertEqual(history.current.fixtures.map(\.id), [2])
    }

    func testUndoOnEmptyHistoryReturnsFalse() {
        var history = PatchHistory()
        XCTAssertFalse(history.undo())
    }

    func testFailedEditDoesNotRecordUndoEntry() throws {
        var history = PatchHistory()
        try history.apply { try $0.addFixture(fixture(1, address: 1)) }
        XCTAssertThrowsError(try history.apply { try $0.addFixture(fixture(1, address: 9)) })
        // The failed apply should not have pushed a spurious undo entry.
        XCTAssertTrue(history.canUndo)
        XCTAssertTrue(history.undo())
        XCTAssertFalse(history.canUndo)
    }
}

import XCTest
@testable import PatchKit

final class AutoAddressTests: XCTestCase {
    func testFirstFitOnEmptyUniverse() {
        XCTAssertEqual(AutoAddress.firstFit(existing: [], footprint: 8), 1)
    }

    func testFirstFitAfterExistingFixture() {
        let existing = [ChannelRange(start: 1, length: 8)]
        XCTAssertEqual(AutoAddress.firstFit(existing: existing, footprint: 8), 9)
    }

    func testFirstFitFillsGapBetweenFixtures() {
        // Fixture at 1-8, then a fixture at 33-40, leaving a 24-channel gap.
        let existing = [ChannelRange(start: 1, length: 8), ChannelRange(start: 33, length: 8)]
        XCTAssertEqual(AutoAddress.firstFit(existing: existing, footprint: 16), 9)
    }

    func testFirstFitReturnsNilWhenFootprintExceedsCapacity() {
        XCTAssertNil(AutoAddress.firstFit(existing: [], footprint: 600))
    }

    func testFirstFitReturnsNilWhenNoGapLargeEnough() {
        // Universe packed solid from 1-512 in 8-channel blocks except a
        // 4-channel gap at the very end — not enough room for an 8-ch fixture.
        let existing = [ChannelRange(start: 1, length: 508)]
        XCTAssertNil(AutoAddress.firstFit(existing: existing, footprint: 8))
    }

    func testFirstFitExactlyFillsRemainingSpace() {
        let existing = [ChannelRange(start: 1, length: 500)]
        XCTAssertEqual(AutoAddress.firstFit(existing: existing, footprint: 12), 501)
    }

    func testNextFreeSlotRollsOverToNextUniverseWhenFull() {
        let existing: [Int: [ChannelRange]] = [1: [ChannelRange(start: 1, length: 512)]]
        let slot = AutoAddress.nextFreeSlot(existingByUniverse: existing, startingUniverse: 1, footprint: 8)
        XCTAssertEqual(slot?.universe, 2)
        XCTAssertEqual(slot?.address, 1)
    }

    func testNextFreeSlotStaysOnStartingUniverseWhenRoomExists() {
        let existing: [Int: [ChannelRange]] = [1: [ChannelRange(start: 1, length: 8)]]
        let slot = AutoAddress.nextFreeSlot(existingByUniverse: existing, startingUniverse: 1, footprint: 8)
        XCTAssertEqual(slot?.universe, 1)
        XCTAssertEqual(slot?.address, 9)
    }

    func testNextFreeSlotReturnsNilWhenEveryUniverseIsFull() {
        let existing: [Int: [ChannelRange]] = [
            1: [ChannelRange(start: 1, length: 512)],
            2: [ChannelRange(start: 1, length: 512)]
        ]
        let slot = AutoAddress.nextFreeSlot(existingByUniverse: existing, startingUniverse: 1, footprint: 8, maxUniverse: 2)
        XCTAssertNil(slot)
    }

    func testSequentialSlotsPackWithinOneUniverse() {
        let slots = AutoAddress.sequentialSlots(
            count: 4,
            footprint: 8,
            startingUniverse: 1,
            startingAddress: 1,
            existingByUniverse: [:]
        )
        XCTAssertEqual(slots.map(\.universe), [1, 1, 1, 1])
        XCTAssertEqual(slots.map(\.address), [1, 9, 17, 25])
    }

    func testSequentialSlotsRollOverUniverseMidBatch() {
        // Only 8 channels free at the end of universe 1; a batch of 4x8-ch
        // fixtures should place one in universe 1 and roll the rest into 2.
        let existing: [Int: [ChannelRange]] = [1: [ChannelRange(start: 1, length: 504)]]
        let slots = AutoAddress.sequentialSlots(
            count: 4,
            footprint: 8,
            startingUniverse: 1,
            startingAddress: nil,
            existingByUniverse: existing
        )
        XCTAssertEqual(slots.map(\.universe), [1, 2, 2, 2])
        XCTAssertEqual(slots[0].address, 505)
        XCTAssertEqual(slots[1].address, 1)
    }

    func testSequentialSlotsStopsWhenForcedStartDoesNotFit() {
        let existing: [Int: [ChannelRange]] = [1: [ChannelRange(start: 100, length: 8)]]
        let slots = AutoAddress.sequentialSlots(
            count: 3,
            footprint: 8,
            startingUniverse: 1,
            startingAddress: 100,
            existingByUniverse: existing
        )
        XCTAssertTrue(slots.isEmpty)
    }
}

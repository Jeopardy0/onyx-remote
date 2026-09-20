import XCTest
import ConsoleKit
@testable import OnyxKit

final class OnyxAddressBookTests: XCTestCase {
    func testDigitKeysMapToDocumentedRange() {
        XCTAssertEqual(OnyxAddressBook.executeAddress(for: .digit(0)), "/Mx/button/5200")
        XCTAssertEqual(OnyxAddressBook.executeAddress(for: .digit(9)), "/Mx/button/5209")
    }

    func testEnterAndClearMapToKeypadAddresses() {
        XCTAssertEqual(OnyxAddressBook.executeAddress(for: .enter), "/Mx/button/5213")
        XCTAssertEqual(OnyxAddressBook.executeAddress(for: .clear), "/Mx/button/5103")
    }

    func testHighlightKeySharesAddressWithProgrammerHighlight() {
        XCTAssertEqual(OnyxAddressBook.executeAddress(for: .highLight), OnyxAddressBook.highlight)
        XCTAssertEqual(OnyxAddressBook.highlight, "/Mx/button/6001")
    }

    func testSwapProgHasNoAddressBecauseItIsUndocumented() {
        XCTAssertNil(OnyxAddressBook.executeAddress(for: .swapProg))
        XCTAssertFalse(NXKKey.swapProg.hasDocumentedOSCAddress)
    }

    func testEveryDocumentedKeyResolvesToAnAddress() {
        for key in NXKKey.allCases where key.hasDocumentedOSCAddress {
            XCTAssertNotNil(OnyxAddressBook.executeAddress(for: key), "\(key) claims a documented address but none is registered")
        }
    }

    func testPlaybackPageLocationFillsPagesOfEight() {
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 1).page, 1)
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 1).button, 0)
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 8).page, 1)
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 8).button, 7)
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 9).page, 2)
        XCTAssertEqual(OnyxAddressBook.playbackPageLocation(forPlaybackID: 9).button, 0)
    }

    func testPlaybackPageAddressMatchesDocumentedSyntax() {
        // /Mx/playback/page1/0/go — from the mapping PDF's own example.
        XCTAssertEqual(OnyxAddressBook.playbackPageAddress(page: 1, button: 0, action: .go), "/Mx/playback/page1/0/go")
        XCTAssertEqual(OnyxAddressBook.playbackPageAddress(page: 5, button: 9, action: .release), "/Mx/playback/page5/9/release")
    }
}

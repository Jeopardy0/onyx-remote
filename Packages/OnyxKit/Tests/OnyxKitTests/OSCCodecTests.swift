import XCTest
@testable import OnyxKit

final class OSCCodecTests: XCTestCase {
    func testEncodeAddressIsNullPaddedToFourByteBoundary() {
        // "/Mx" is 3 bytes; + 1 null = 4, already a multiple of 4, so OSC
        // still requires a full 4-byte null block per spec (no partial
        // padding) — total should be 8 bytes (4 for the string, 4 more nulls)
        // only when the string+terminator isn't already aligned. For "/Mx"
        // (3 chars + 1 null = 4), no extra padding is needed.
        let message = OSCMessage(address: "/Mx", arguments: [])
        let data = OSCCodec.encode(message)
        // "/Mx\0" (4 bytes) + ",\0\0\0" (empty type tag, 4 bytes) = 8 bytes.
        XCTAssertEqual(data, Data("/Mx\0,\0\0\0".utf8))
    }

    func testEncodeIntArgumentMatchesButtonPressExample() {
        // /Mx/button/4201 1  — a key-down Execute message from
        // docs/ONYX_INTEGRATION.md §1.4.
        let message = OSCMessage(address: "/Mx/button/4201", arguments: [.int32(1)])
        let data = OSCCodec.encode(message)
        let decoded = try! OSCCodec.decode(data)
        XCTAssertEqual(decoded, message)
    }

    func testRoundTripEveryArgumentType() throws {
        let message = OSCMessage(
            address: "/Mx/fader/4203",
            arguments: [.int32(-1), .float32(127.5), .string("white")]
        )
        let data = OSCCodec.encode(message)
        let decoded = try OSCCodec.decode(data)
        XCTAssertEqual(decoded, message)
    }

    func testEncodedSizeIsAlwaysAMultipleOfFour() {
        let message = OSCMessage(address: "/Mx/commandLine/0002/text", arguments: [.string("1 THRU 10 @ FULL")])
        let data = OSCCodec.encode(message)
        XCTAssertEqual(data.count % 4, 0)
    }

    func testDecodeThrowsOnMissingNullTerminator() {
        let malformed = Data([0x2F, 0x4D, 0x78]) // "/Mx" with no null terminator at all
        XCTAssertThrowsError(try OSCCodec.decode(malformed)) { error in
            XCTAssertEqual(error as? OSCCodecError, .missingNullTerminator)
        }
    }

    func testDecodeThrowsOnMissingTypeTagComma() {
        // Address "/x" padded, followed by a type tag that doesn't start with ','
        var data = Data("/x\0\0".utf8)
        data.append(Data("bad\0".utf8))
        XCTAssertThrowsError(try OSCCodec.decode(data)) { error in
            XCTAssertEqual(error as? OSCCodecError, .missingTypeTagComma)
        }
    }

    func testDecodeThrowsOnUnsupportedTypeTag() {
        var data = Data("/x\0\0".utf8)
        data.append(Data(",b\0\0".utf8)) // "b" (blob) is not a type we support
        XCTAssertThrowsError(try OSCCodec.decode(data)) { error in
            XCTAssertEqual(error as? OSCCodecError, .unsupportedTypeTag("b"))
        }
    }

    func testDecodeThrowsOnTruncatedIntArgument() {
        var data = Data("/x\0\0".utf8)
        data.append(Data(",i\0\0".utf8))
        data.append(Data([0x00, 0x01])) // only 2 of the required 4 bytes
        XCTAssertThrowsError(try OSCCodec.decode(data)) { error in
            XCTAssertEqual(error as? OSCCodecError, .unexpectedEndOfData)
        }
    }

    func testNegativeAndZeroIntsRoundTrip() throws {
        for value: Int32 in [0, 1, -1, Int32.min, Int32.max] {
            let message = OSCMessage(address: "/Mx/button/5210", arguments: [.int32(value)])
            let decoded = try OSCCodec.decode(OSCCodec.encode(message))
            XCTAssertEqual(decoded, message)
        }
    }

    func testFloatFaderValueRoundTrips() throws {
        // /Mx/fader/2202 — GRAND MASTER LEVEL, documented range 0-255.
        let message = OSCMessage(address: "/Mx/fader/2202", arguments: [.float32(191.5)])
        let decoded = try OSCCodec.decode(OSCCodec.encode(message))
        XCTAssertEqual(decoded, message)
    }
}

import Foundation

public enum OSCCodecError: Error, Equatable, Sendable {
    case missingNullTerminator
    case missingTypeTagComma
    case unsupportedTypeTag(Character)
    case unexpectedEndOfData
}

/// Encodes and decodes OSC 1.0 messages (address + type-tagged argument
/// list), per the spec at opensoundcontrol.org — independent of any
/// transport, so it's testable on any platform including Linux CI.
public enum OSCCodec {
    public static func encode(_ message: OSCMessage) -> Data {
        var data = Data()
        data.append(paddedOSCString(message.address))

        var typeTag = ","
        typeTag.append(contentsOf: message.arguments.map(\.typeTag))
        data.append(paddedOSCString(typeTag))

        for argument in message.arguments {
            switch argument {
            case .int32(let value):
                data.append(bigEndianBytes(of: value))
            case .float32(let value):
                data.append(bigEndianBytes(of: value.bitPattern))
            case .string(let value):
                data.append(paddedOSCString(value))
            }
        }
        return data
    }

    public static func decode(_ data: Data) throws -> OSCMessage {
        var offset = data.startIndex
        let address = try readOSCString(data, offset: &offset)

        let typeTag = try readOSCString(data, offset: &offset)
        guard typeTag.first == "," else { throw OSCCodecError.missingTypeTagComma }
        let typeChars = typeTag.dropFirst()

        var arguments: [OSCArgument] = []
        for typeChar in typeChars {
            switch typeChar {
            case "i":
                arguments.append(.int32(try readInt32(data, offset: &offset)))
            case "f":
                let bits = UInt32(bitPattern: try readInt32(data, offset: &offset))
                arguments.append(.float32(Float(bitPattern: bits)))
            case "s":
                arguments.append(.string(try readOSCString(data, offset: &offset)))
            default:
                throw OSCCodecError.unsupportedTypeTag(typeChar)
            }
        }
        return OSCMessage(address: address, arguments: arguments)
    }

    // MARK: - Primitives

    private static func paddedOSCString(_ string: String) -> Data {
        var bytes = Array(string.utf8)
        bytes.append(0)
        while bytes.count % 4 != 0 { bytes.append(0) }
        return Data(bytes)
    }

    private static func bigEndianBytes(of value: Int32) -> Data {
        var bigEndian = value.bigEndian
        return Data(bytes: &bigEndian, count: 4)
    }

    private static func bigEndianBytes(of value: UInt32) -> Data {
        var bigEndian = value.bigEndian
        return Data(bytes: &bigEndian, count: 4)
    }

    private static func readOSCString(_ data: Data, offset: inout Data.Index) throws -> String {
        guard let nullIndex = data[offset...].firstIndex(of: 0) else {
            throw OSCCodecError.missingNullTerminator
        }
        let stringBytes = data[offset..<nullIndex]
        let string = String(decoding: stringBytes, as: UTF8.self)

        // Advance past the string + at least one null, then to the next
        // 4-byte boundary relative to the start of the whole buffer.
        let consumedFromStart = (nullIndex - data.startIndex) + 1
        let padded = consumedFromStart + ((4 - consumedFromStart % 4) % 4)
        let nextOffset = data.startIndex.advanced(by: padded)
        guard nextOffset <= data.endIndex else { throw OSCCodecError.unexpectedEndOfData }
        offset = nextOffset
        return string
    }

    private static func readInt32(_ data: Data, offset: inout Data.Index) throws -> Int32 {
        guard data.distance(from: offset, to: data.endIndex) >= 4 else {
            throw OSCCodecError.unexpectedEndOfData
        }
        let bytes = data[offset..<data.index(offset, offsetBy: 4)]
        let bigEndian = bytes.withUnsafeBytes { $0.loadUnaligned(as: Int32.self) }
        offset = data.index(offset, offsetBy: 4)
        return Int32(bigEndian: bigEndian)
    }
}

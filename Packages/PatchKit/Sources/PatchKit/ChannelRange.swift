/// An inclusive 1...512 DMX channel range occupied by one fixture in one universe.
public struct ChannelRange: Hashable, Sendable {
    public var start: Int
    public var length: Int

    public init(start: Int, length: Int) {
        self.start = start
        self.length = length
    }

    public var end: Int { start + length - 1 }

    public func overlaps(_ other: ChannelRange) -> Bool {
        start <= other.end && other.start <= end
    }

    public func contains(_ channel: Int) -> Bool {
        channel >= start && channel <= end
    }
}

/// One selectable channel mode of a fixture profile, e.g. "8-ch" vs "12-ch" for an LED Wash.
public struct FixtureMode: Codable, Hashable, Sendable, Identifiable {
    public var name: String
    public var channelCount: Int

    public var id: String { name }

    public init(name: String, channelCount: Int) {
        self.name = name
        self.channelCount = channelCount
    }
}

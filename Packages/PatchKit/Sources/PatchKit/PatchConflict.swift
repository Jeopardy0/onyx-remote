/// Two fixtures whose channel ranges overlap in the same universe.
public struct PatchConflict: Hashable, Sendable, Identifiable {
    public var universe: Int
    public var fixtureID: Int
    public var overlappingFixtureID: Int
    public var overlap: ChannelRange

    public var id: String { "\(universe):\(min(fixtureID, overlappingFixtureID)):\(max(fixtureID, overlappingFixtureID))" }

    public init(universe: Int, fixtureID: Int, overlappingFixtureID: Int, overlap: ChannelRange) {
        self.universe = universe
        self.fixtureID = fixtureID
        self.overlappingFixtureID = overlappingFixtureID
        self.overlap = overlap
    }
}

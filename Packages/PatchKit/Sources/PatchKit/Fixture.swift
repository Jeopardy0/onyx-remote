/// A single patched fixture. `id` is the Onyx-style numeric fixture ID shown
/// to the user (e.g. "115"), never a letter-prefixed ID — Onyx addresses
/// fixtures numerically (see docs/ONYX_INTEGRATION.md).
public struct Fixture: Codable, Hashable, Sendable, Identifiable {
    public var id: Int
    public var name: String
    public var profileID: String
    public var category: FixtureCategory
    public var modeName: String
    public var footprint: Int
    public var universe: Int
    public var address: Int

    public init(
        id: Int,
        name: String,
        profileID: String,
        category: FixtureCategory,
        modeName: String,
        footprint: Int,
        universe: Int,
        address: Int
    ) {
        self.id = id
        self.name = name
        self.profileID = profileID
        self.category = category
        self.modeName = modeName
        self.footprint = footprint
        self.universe = universe
        self.address = address
    }

    public var channelRange: ChannelRange {
        ChannelRange(start: address, length: footprint)
    }
}

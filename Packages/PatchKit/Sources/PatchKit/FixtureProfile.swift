/// A fixture library entry (or a user-authored custom profile) that patched
/// `Fixture` instances reference by `profileID`. Library profiles ship with
/// the app; custom profiles are entered manually per the "Support custom
/// fixture profiles" requirement and are persisted alongside the patch.
public struct FixtureProfile: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var category: FixtureCategory
    public var modes: [FixtureMode]
    public var isCustom: Bool

    public init(id: String, name: String, category: FixtureCategory, modes: [FixtureMode], isCustom: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.modes = modes
        self.isCustom = isCustom
    }

    public func mode(named name: String) -> FixtureMode? {
        modes.first { $0.name == name }
    }
}

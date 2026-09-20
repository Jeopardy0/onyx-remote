/// The local patch document — source of truth for the Patch screen. Works
/// fully offline; syncing to a console is layered on top by whoever holds a
/// `ConsoleAdapter`, never the other way around.
public struct Patch: Codable, Hashable, Sendable {
    public var fixtures: [Fixture]
    public var customProfiles: [FixtureProfile]

    public init(fixtures: [Fixture] = [], customProfiles: [FixtureProfile] = []) {
        self.fixtures = fixtures
        self.customProfiles = customProfiles
    }

    public var universes: [Int] {
        Set(fixtures.map(\.universe)).sorted()
    }

    public func fixtures(inUniverse universe: Int) -> [Fixture] {
        fixtures.filter { $0.universe == universe }.sorted { $0.address < $1.address }
    }

    public func fixture(withID id: Int) -> Fixture? {
        fixtures.first { $0.id == id }
    }

    public var conflicts: [PatchConflict] {
        ConflictDetector.conflicts(in: fixtures)
    }

    public func conflicts(inUniverse universe: Int) -> [PatchConflict] {
        conflicts.filter { $0.universe == universe }
    }

    public func occupiedChannelCount(inUniverse universe: Int) -> Int {
        ConflictDetector.occupiedChannelCount(in: fixtures, universe: universe)
    }

    /// Sum of every patched fixture's footprint in a universe. Unlike
    /// `occupiedChannelCount`, this does not de-duplicate an overlap between
    /// conflicting fixtures — it's what the usage bar shows (how many
    /// channels have been *claimed*, conflicts included), while
    /// `occupiedChannelCount` answers how much of the address space is
    /// actually spoken for.
    public func totalFootprint(inUniverse universe: Int) -> Int {
        fixtures(inUniverse: universe).reduce(0) { $0 + $1.footprint }
    }

    public func channelRanges(inUniverse universe: Int, excluding excludedID: Int? = nil) -> [ChannelRange] {
        fixtures
            .filter { $0.universe == universe && $0.id != excludedID }
            .map(\.channelRange)
    }

    public func nextFreeAddress(inUniverse universe: Int, footprint: Int) -> Int? {
        AutoAddress.firstFit(existing: channelRanges(inUniverse: universe), footprint: footprint)
    }

    // MARK: - Mutation

    @discardableResult
    public mutating func addFixture(_ fixture: Fixture) throws -> Fixture {
        guard self.fixture(withID: fixture.id) == nil else {
            throw PatchError.fixtureIDAlreadyExists(fixture.id)
        }
        guard fixture.address >= 1, fixture.channelRange.end <= AutoAddress.universeCapacity else {
            throw PatchError.addressOutOfRange(universe: fixture.universe, address: fixture.address, footprint: fixture.footprint)
        }
        fixtures.append(fixture)
        return fixture
    }

    public mutating func removeFixture(id: Int) throws {
        guard let index = fixtures.firstIndex(where: { $0.id == id }) else {
            throw PatchError.fixtureNotFound(id)
        }
        fixtures.remove(at: index)
    }

    /// Re-address an existing fixture (`115 @ 401 ENTER`-equivalent). Does
    /// not check for conflicts — conflicts are surfaced separately so the UI
    /// can show them rather than silently refusing the edit.
    public mutating func readdress(id: Int, universe: Int, address: Int) throws {
        guard let index = fixtures.firstIndex(where: { $0.id == id }) else {
            throw PatchError.fixtureNotFound(id)
        }
        guard address >= 1, address + fixtures[index].footprint - 1 <= AutoAddress.universeCapacity else {
            throw PatchError.addressOutOfRange(universe: universe, address: address, footprint: fixtures[index].footprint)
        }
        fixtures[index].universe = universe
        fixtures[index].address = address
    }

    /// Renumber a fixture's ID (`MOVE 1 @ 5 ENTER`-equivalent).
    public mutating func renumber(id: Int, to newID: Int) throws {
        guard fixtures.contains(where: { $0.id == id }) else {
            throw PatchError.fixtureNotFound(id)
        }
        guard fixture(withID: newID) == nil else {
            throw PatchError.fixtureIDAlreadyExists(newID)
        }
        guard let index = fixtures.firstIndex(where: { $0.id == id }) else { return }
        fixtures[index].id = newID
    }

    /// Duplicate a fixture at the first free address in the same universe,
    /// auto-assigning the next unused fixture ID.
    @discardableResult
    public mutating func duplicateFixture(id: Int) throws -> Fixture {
        guard let source = fixture(withID: id) else {
            throw PatchError.fixtureNotFound(id)
        }
        guard let address = nextFreeAddress(inUniverse: source.universe, footprint: source.footprint) else {
            throw PatchError.doesNotFit(universe: source.universe, footprint: source.footprint)
        }
        let newID = (fixtures.map(\.id).max() ?? 0) + 1
        var copy = source
        copy.id = newID
        copy.address = address
        fixtures.append(copy)
        return copy
    }

    public mutating func addCustomProfile(_ profile: FixtureProfile) {
        var custom = profile
        custom.isCustom = true
        customProfiles.removeAll { $0.id == custom.id }
        customProfiles.append(custom)
    }
}

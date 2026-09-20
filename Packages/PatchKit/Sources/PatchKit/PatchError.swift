public enum PatchError: Error, Equatable, Sendable {
    case fixtureNotFound(Int)
    case fixtureIDAlreadyExists(Int)
    case addressOutOfRange(universe: Int, address: Int, footprint: Int)
    case doesNotFit(universe: Int, footprint: Int)
}

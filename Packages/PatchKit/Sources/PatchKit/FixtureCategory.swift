/// Broad category used for map coloring and group filters (All/Washes/Movers/Bars).
/// Does not carry color values — that's a presentation concern for the app layer.
public enum FixtureCategory: String, Codable, CaseIterable, Sendable {
    case wash
    case mover
    case bar
    case other
}

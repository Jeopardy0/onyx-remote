/// The four parameter groups shown as tabs on the Program screen.
public enum ParameterGroup: String, Codable, CaseIterable, Sendable {
    case intensity, color, position, beam
}

/// A single addressable parameter within a group, e.g. `.position("Pan")`.
/// Names are free strings (not an enum) because the actual parameter list is
/// fixture-profile-dependent in Onyx; the app never hardcodes a universal set.
public struct ParameterID: Codable, Hashable, Sendable {
    public var group: ParameterGroup
    public var name: String

    public init(group: ParameterGroup, name: String) {
        self.group = group
        self.name = name
    }

    public static let intensity = ParameterID(group: .intensity, name: "Intensity")
    public static let pan = ParameterID(group: .position, name: "Pan")
    public static let tilt = ParameterID(group: .position, name: "Tilt")
}

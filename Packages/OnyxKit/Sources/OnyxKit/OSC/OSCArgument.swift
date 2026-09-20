/// One OSC 1.0 argument value. Only the three types the Onyx mapping PDF
/// actually uses (int, float, string/color-as-string) are modeled — see
/// docs/ONYX_INTEGRATION.md §1.2.
public enum OSCArgument: Equatable, Sendable {
    case int32(Int32)
    case float32(Float)
    case string(String)

    var typeTag: Character {
        switch self {
        case .int32: return "i"
        case .float32: return "f"
        case .string: return "s"
        }
    }
}

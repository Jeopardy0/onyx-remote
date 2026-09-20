enum AppTab: String, CaseIterable, Identifiable {
    case patch = "Patch"
    case program = "Program"
    case keypad = "Keypad"
    case cues = "Cues"

    var id: String { rawValue }
}

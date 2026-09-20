import PatchKit
import SwiftUI

extension FixtureCategory {
    var color: Color {
        switch self {
        case .wash: return Palette.FixtureType.wash
        case .mover: return Palette.FixtureType.mover
        case .bar: return Palette.FixtureType.bar
        case .other: return Palette.FixtureType.other
        }
    }

    var label: String {
        switch self {
        case .wash: return "Washes"
        case .mover: return "Movers"
        case .bar: return "Bars"
        case .other: return "Other"
        }
    }
}

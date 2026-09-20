/// A small built-in starter library so "Add fixtures" has something to show
/// before a real Onyx fixture-library export is available (see Open
/// Questions #6 in docs/PLAN.md). Not meant to be exhaustive — custom
/// profiles cover everything else until then.
public enum StandardFixtureLibrary {
    public static let profiles: [FixtureProfile] = [
        FixtureProfile(
            id: "led-wash",
            name: "LED Wash",
            category: .wash,
            modes: [FixtureMode(name: "8-ch", channelCount: 8), FixtureMode(name: "12-ch", channelCount: 12)]
        ),
        FixtureProfile(
            id: "spot-mover",
            name: "Spot Mover",
            category: .mover,
            modes: [FixtureMode(name: "16-ch", channelCount: 16), FixtureMode(name: "24-ch", channelCount: 24)]
        ),
        FixtureProfile(
            id: "led-bar",
            name: "LED Bar (custom)",
            category: .bar,
            modes: [FixtureMode(name: "12-ch", channelCount: 12)]
        ),
        FixtureProfile(
            id: "strobe",
            name: "Strobe",
            category: .other,
            modes: [FixtureMode(name: "16-ch", channelCount: 16)]
        ),
        FixtureProfile(
            id: "haze-unit",
            name: "Haze Unit",
            category: .other,
            modes: [FixtureMode(name: "2-ch", channelCount: 2)]
        )
    ]

    public static func profile(id: String) -> FixtureProfile? {
        profiles.first { $0.id == id }
    }
}

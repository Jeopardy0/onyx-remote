import PatchKit

/// Static sample data for `MockConsoleAdapter`, deliberately matching the
/// numbers in the design reference screenshots (16 fixtures in Universe 1,
/// 210/512 used, Strobe 1 overlapping Spot Mover 4 on channels 137-144) so
/// M0's screenshots line up with `docs/design/`.
public enum SampleShow {
    public static var patch: Patch {
        var patch = Patch()
        let fixtures: [Fixture] = [
            fixture(1, "W1", .wash, "led-wash", "8-ch", 8, 1),
            fixture(2, "W2", .wash, "led-wash", "8-ch", 8, 9),
            fixture(3, "W3", .wash, "led-wash", "8-ch", 8, 17),
            fixture(4, "W4", .wash, "led-wash", "8-ch", 8, 25),
            fixture(5, "W5", .wash, "led-wash", "8-ch", 8, 33),
            fixture(6, "W6", .wash, "led-wash", "8-ch", 8, 41),
            fixture(7, "M1", .mover, "spot-mover", "24-ch", 24, 49),
            fixture(8, "M2", .mover, "spot-mover", "24-ch", 24, 73),
            fixture(9, "M3", .mover, "spot-mover", "24-ch", 24, 97),
            fixture(10, "M4", .mover, "spot-mover", "24-ch", 24, 121),
            fixture(15, "S1", .other, "strobe", "16-ch", 16, 137), // overlaps M4 on 137-144, intentionally, matching docs/design
            fixture(11, "B1", .bar, "led-bar", "12-ch", 12, 161),
            fixture(12, "B2", .bar, "led-bar", "12-ch", 12, 173),
            fixture(13, "B3", .bar, "led-bar", "12-ch", 12, 185),
            fixture(14, "B4", .bar, "led-bar", "12-ch", 12, 197),
            fixture(16, "H1", .other, "haze-unit", "2-ch", 2, 209)
        ]
        for fixture in fixtures {
            _ = try? patch.addFixture(fixture)
        }
        return patch
    }

    private static func fixture(
        _ id: Int, _ name: String, _ category: FixtureCategory, _ profileID: String,
        _ mode: String, _ footprint: Int, _ address: Int, universe: Int = 1
    ) -> Fixture {
        Fixture(id: id, name: name, profileID: profileID, category: category, modeName: mode, footprint: footprint, universe: universe, address: address)
    }

    public static let playbacks: [SamplePlayback] = [
        SamplePlayback(id: 1, name: "Opening Look", cueCount: 6, state: .running(cue: 3), level: 1.0),
        SamplePlayback(id: 2, name: "Band Wash", cueCount: 4, state: .stopped, level: 0),
        SamplePlayback(id: 3, name: "Blackout", cueCount: 1, state: .stopped, level: 0),
        SamplePlayback(id: 4, name: "Haze", cueCount: 2, state: .running(cue: 1), level: 0.4),
        SamplePlayback(id: 5, name: "Strobe Hits", cueCount: 8, state: .stopped, level: 0),
        SamplePlayback(id: 6, name: "Walk-in", cueCount: 3, state: .stopped, level: 0),
        SamplePlayback(id: 7, name: "Ballad", cueCount: 5, state: .stopped, level: 0),
        SamplePlayback(id: 8, name: "Finale", cueCount: 7, state: .stopped, level: 0)
    ]

    public static let selectedCuelist = SampleCuelist(
        playbackID: 1,
        name: "Opening Look",
        cues: [
            SampleCue(number: 1, name: "Preset", time: 0.0, tag: nil),
            SampleCue(number: 2, name: "House to half", time: 3.0, tag: nil),
            SampleCue(number: 3, name: "Band in", time: 2.0, tag: .now),
            SampleCue(number: 4, name: "Verse 1", time: 4.0, tag: .next),
            SampleCue(number: 5, name: "Chorus", time: 1.5, tag: nil),
            SampleCue(number: 6, name: "Blackout", time: 5.0, tag: nil)
        ]
    )
}

public struct SamplePlayback: Identifiable, Sendable, Hashable {
    public enum State: Sendable, Hashable {
        case stopped
        case running(cue: Int)
    }

    public var id: Int
    public var name: String
    public var cueCount: Int
    public var state: State
    public var level: Double
}

public struct SampleCuelist: Sendable, Hashable {
    public var playbackID: Int
    public var name: String
    public var cues: [SampleCue]
}

public struct SampleCue: Identifiable, Sendable, Hashable {
    public enum Tag: Sendable, Hashable { case now, next }

    public var number: Int
    public var name: String
    public var time: Double
    public var tag: Tag?

    public var id: Int { number }
}

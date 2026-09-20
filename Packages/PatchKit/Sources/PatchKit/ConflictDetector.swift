/// Pure conflict detection: given a set of fixtures, find every pair whose
/// channel ranges overlap within the same universe. No I/O, no console
/// dependency — this is the function unit tests exercise directly.
public enum ConflictDetector {
    public static func conflicts(in fixtures: [Fixture]) -> [PatchConflict] {
        var results: [PatchConflict] = []
        let byUniverse = Dictionary(grouping: fixtures, by: \.universe)
        for (universe, group) in byUniverse {
            let sorted = group.sorted { $0.address < $1.address }
            for i in sorted.indices {
                for j in sorted.indices where j > i {
                    let a = sorted[i]
                    let b = sorted[j]
                    let rangeA = a.channelRange
                    let rangeB = b.channelRange
                    guard rangeA.overlaps(rangeB) else { continue }
                    let overlapStart = max(rangeA.start, rangeB.start)
                    let overlapEnd = min(rangeA.end, rangeB.end)
                    let overlap = ChannelRange(start: overlapStart, length: overlapEnd - overlapStart + 1)
                    results.append(
                        PatchConflict(universe: universe, fixtureID: a.id, overlappingFixtureID: b.id, overlap: overlap)
                    )
                }
            }
        }
        return results.sorted { $0.universe == $1.universe ? $0.overlap.start < $1.overlap.start : $0.universe < $1.universe }
    }

    /// Distinct DMX channels actually spoken for in a universe, counting an
    /// overlapping channel once (so a conflict never inflates the usage bar
    /// past reality).
    public static func occupiedChannelCount(in fixtures: [Fixture], universe: Int) -> Int {
        var occupied = Set<Int>()
        for fixture in fixtures where fixture.universe == universe {
            let range = fixture.channelRange
            occupied.formUnion(range.start...range.end)
        }
        return occupied.count
    }
}

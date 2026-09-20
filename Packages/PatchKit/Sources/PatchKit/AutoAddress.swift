/// Pure auto-addressing: first-fit placement within a universe, with
/// rollover into subsequent universes when a run of fixtures doesn't fit in
/// the space remaining. No dependency on `Patch` — takes plain ranges so it
/// stays trivially unit testable.
public enum AutoAddress {
    public static let universeCapacity = 512

    /// The first DMX start address (1-based) where `footprint` contiguous
    /// channels fit without overlapping any range in `existing`, or `nil` if
    /// it doesn't fit anywhere in `capacity` channels.
    public static func firstFit(existing: [ChannelRange], footprint: Int, capacity: Int = universeCapacity) -> Int? {
        guard footprint > 0, footprint <= capacity else { return nil }
        var candidate = 1
        for range in existing.sorted(by: { $0.start < $1.start }) {
            if candidate + footprint - 1 < range.start {
                return candidate
            }
            candidate = max(candidate, range.end + 1)
        }
        return candidate + footprint - 1 <= capacity ? candidate : nil
    }

    /// Searches `startingUniverse` first, then increasing universe numbers up
    /// to `maxUniverse`, for the first universe where `footprint` fits.
    /// Models the "universe rollover" case: a batch of fixtures that doesn't
    /// fit in the remaining space of the current universe spills into the next.
    public static func nextFreeSlot(
        existingByUniverse: [Int: [ChannelRange]],
        startingUniverse: Int,
        footprint: Int,
        capacity: Int = universeCapacity,
        maxUniverse: Int = 64
    ) -> (universe: Int, address: Int)? {
        guard startingUniverse >= 1 else { return nil }
        var universe = startingUniverse
        while universe <= maxUniverse {
            let existing = existingByUniverse[universe] ?? []
            if let address = firstFit(existing: existing, footprint: footprint, capacity: capacity) {
                return (universe, address)
            }
            universe += 1
        }
        return nil
    }

    /// Placement for `count` new fixtures of the same footprint, filling
    /// sequentially from `startingUniverse`/`startingAddress` (or first-fit if
    /// `startingAddress` is nil), rolling into later universes as needed.
    /// Returns fewer than `count` slots if universes run out before
    /// `maxUniverse`.
    public static func sequentialSlots(
        count: Int,
        footprint: Int,
        startingUniverse: Int,
        startingAddress: Int?,
        existingByUniverse: [Int: [ChannelRange]],
        capacity: Int = universeCapacity,
        maxUniverse: Int = 64
    ) -> [(universe: Int, address: Int)] {
        guard count > 0, footprint > 0 else { return [] }
        var placed: [Int: [ChannelRange]] = existingByUniverse
        var results: [(universe: Int, address: Int)] = []
        var universe = startingUniverse
        var forcedAddress = startingAddress

        while results.count < count && universe <= maxUniverse {
            let existing = placed[universe] ?? []
            let candidate: Int?
            if let forced = forcedAddress {
                let range = ChannelRange(start: forced, length: footprint)
                let fits = range.end <= capacity && !existing.contains(where: { $0.overlaps(range) })
                candidate = fits ? forced : nil
            } else {
                candidate = firstFit(existing: existing, footprint: footprint, capacity: capacity)
            }

            guard let address = candidate else {
                // Forced address didn't fit in this universe at all — stop
                // rather than silently moving it, so the caller can surface
                // a conflict instead of a surprise placement.
                if forcedAddress != nil { break }
                universe += 1
                continue
            }

            results.append((universe, address))
            placed[universe, default: []].append(ChannelRange(start: address, length: footprint))
            forcedAddress = nil

            if results.count < count {
                // Next fixture continues packing the same universe first-fit,
                // rolling forward once it no longer fits.
                let stillFits = firstFit(existing: placed[universe] ?? [], footprint: footprint, capacity: capacity) != nil
                if !stillFits {
                    universe += 1
                }
            }
        }
        return results
    }
}

import PatchKit
import SwiftUI

struct UniverseSidebar: View {
    @Environment(AppModel.self) private var model

    private var universes: [Int] {
        let patched = model.patch.universes
        return patched.isEmpty ? [1] : patched
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("UNIVERSES")
                .font(Typography.sectionHeader)
                .foregroundStyle(Palette.muted)

            VStack(spacing: Spacing.sm) {
                ForEach(universes, id: \.self) { universe in
                    UniverseRow(
                        universe: universe,
                        isSelected: model.selectedUniverse == universe,
                        used: model.patch.totalFootprint(inUniverse: universe),
                        hasConflict: !model.patch.conflicts(inUniverse: universe).isEmpty
                    )
                    .onTapGesture { model.selectedUniverse = universe }
                }
            }

            Spacer()

            Text("FIXTURE TYPES")
                .font(Typography.sectionHeader)
                .foregroundStyle(Palette.muted)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                LegendRow(color: Palette.FixtureType.wash, label: "LED Wash")
                LegendRow(color: Palette.FixtureType.mover, label: "Spot Mover")
                LegendRow(color: Palette.FixtureType.bar, label: "LED Bar")
                LegendRow(color: Palette.FixtureType.other, label: "Other")
            }
        }
        .padding(Spacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
    }
}

private struct UniverseRow: View {
    let universe: Int
    let isSelected: Bool
    let used: Int
    let hasConflict: Bool

    private let capacity = AutoAddress.universeCapacity

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text("Universe \(universe)")
                    .font(Typography.sans(14, weight: .medium))
                    .foregroundStyle(Palette.text)
                Spacer()
                if hasConflict {
                    Circle().fill(Palette.danger).frame(width: 8, height: 8)
                }
            }
            ProgressView(value: Double(used), total: Double(capacity))
                .tint(hasConflict ? Palette.danger : Palette.accent)
            Text("\(used) / \(capacity)")
                .font(Typography.mono(11))
                .foregroundStyle(Palette.muted)
        }
        .padding(Spacing.sm)
        .background(isSelected ? Palette.raised : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(isSelected ? Palette.accent : Color.clear, lineWidth: 1)
        )
    }
}

private struct LegendRow: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
        }
    }
}

import PatchKit
import SwiftUI

struct FixtureTilesSidebar: View {
    @Environment(AppModel.self) private var model

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.sm) {
                Text("Fixtures").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(model.selectedFixtureIDs.count) selected").font(Typography.caption).foregroundStyle(Palette.muted)
            }

            LazyVGrid(columns: columns, spacing: Spacing.sm) {
                ForEach(model.patch.fixtures.sorted { $0.id < $1.id }) { fixture in
                    FixtureTile(fixture: fixture, isSelected: model.selectedFixtureIDs.contains(fixture.id))
                        .onTapGesture { model.toggleFixtureSelection(fixture.id) }
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                groupChip("All", isSelected: model.selectedGroupFilter == nil) { model.selectGroup(nil) }
                groupChip("Washes", isSelected: model.selectedGroupFilter == .wash) { model.selectGroup(.wash) }
                groupChip("Movers", isSelected: model.selectedGroupFilter == .mover) { model.selectGroup(.mover) }
                groupChip("Bars", isSelected: model.selectedGroupFilter == .bar) { model.selectGroup(.bar) }
            }

            HStack(spacing: Spacing.sm) {
                textButton("Odd") { selectAlternating(offset: 0) }
                textButton("Even") { selectAlternating(offset: 1) }
                textButton("Clear") { model.clearSelection() }
            }
        }
        .padding(Spacing.lg)
        .frame(width: 260, alignment: .top)
        .background(Palette.surface)
    }

    private func selectAlternating(offset: Int) {
        let group = model.fixturesForCurrentGroupFilter()
        model.selectedFixtureIDs = Set(group.enumerated().filter { $0.offset % 2 == offset }.map { $0.element.id })
    }

    private func groupChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.caption)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 28)
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.muted)
                .background(isSelected ? Palette.accent : Palette.raised)
                .clipShape(Capsule())
        }
    }

    private func textButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.caption)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .foregroundStyle(Palette.text)
                .background(Palette.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

private struct FixtureTile: View {
    let fixture: Fixture
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 2) {
            Text(fixture.name)
                .font(Typography.sans(14, weight: .semibold))
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text)
            Text("\(fixture.id)")
                .font(Typography.mono(11))
                .foregroundStyle(isSelected ? Palette.onAccent.opacity(0.7) : Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.minTouchTarget)
        .background(isSelected ? fixture.category.color : Palette.raised)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(isSelected ? Palette.accent : Color.clear, lineWidth: 2)
        )
    }
}

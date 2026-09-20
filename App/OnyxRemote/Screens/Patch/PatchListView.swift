import PatchKit
import SwiftUI

struct PatchListView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 1) {
                ForEach(model.patch.fixtures(inUniverse: model.selectedUniverse)) { fixture in
                    row(for: fixture)
                }
            }
        }
    }

    private func row(for fixture: Fixture) -> some View {
        let isSelected = model.selectedFixtureIDForInspector == fixture.id
        return HStack {
            Circle().fill(fixture.category.color).frame(width: 10, height: 10)
            Text(fixture.name)
                .font(Typography.sans(15, weight: .medium))
                .foregroundStyle(Palette.text)
                .frame(width: 60, alignment: .leading)
            Text("ID \(fixture.id)")
                .font(Typography.mono(13))
                .foregroundStyle(Palette.muted)
                .frame(width: 70, alignment: .leading)
            Text(fixture.modeName)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
            Spacer()
            Text("\(fixture.address)–\(fixture.channelRange.end)")
                .font(Typography.mono(14))
                .foregroundStyle(Palette.text)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: Metrics.minTouchTarget)
        .background(isSelected ? Palette.raised : Palette.surface)
        .contentShape(Rectangle())
        .onTapGesture { model.selectedFixtureIDForInspector = fixture.id }
    }
}

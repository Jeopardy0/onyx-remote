import PatchKit
import SwiftUI

struct ConflictBanner: View {
    @Environment(AppModel.self) private var model
    let conflict: PatchConflict

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Palette.danger)
            Text("Fixture \(conflict.fixtureID) overlaps \(conflict.overlappingFixtureID) on channels \(conflict.overlap.start)–\(conflict.overlap.end)")
                .font(Typography.body)
                .foregroundStyle(Palette.text)
            Spacer()
            Button("Move to \(suggestedAddress)") {
                moveToFirstFit()
            }
            .font(Typography.sans(14, weight: .semibold))
            .padding(.horizontal, Spacing.md)
            .frame(height: 36)
            .foregroundStyle(Palette.onAccent)
            .background(Palette.accent)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(Spacing.md)
        .background(Palette.danger.opacity(0.12))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: 1)
        }
    }

    private var suggestedAddress: Int {
        guard let fixture = model.patch.fixture(withID: conflict.overlappingFixtureID) else { return conflict.overlap.end + 1 }
        let others = model.patch.channelRanges(inUniverse: fixture.universe, excluding: fixture.id)
        return AutoAddress.firstFit(existing: others, footprint: fixture.footprint) ?? conflict.overlap.end + 1
    }

    private func moveToFirstFit() {
        let address = suggestedAddress
        model.edit { patch in
            try patch.readdress(id: conflict.overlappingFixtureID, universe: conflict.universe, address: address)
        }
    }
}

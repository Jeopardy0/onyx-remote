import PatchKit
import SwiftUI

struct FixtureInspector: View {
    @Environment(AppModel.self) private var model
    let fixture: Fixture

    @State private var showingDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack {
                Circle().fill(fixture.category.color).frame(width: 12, height: 12)
                Text(fixture.name).font(Typography.title).foregroundStyle(Palette.text)
            }

            infoRow("ID", "\(fixture.id)")
            infoRow("Type", fixture.category.label)
            infoRow("Mode", fixture.modeName)
            infoRow("Footprint", "\(fixture.footprint) ch")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("DMX ADDRESS").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                HStack(spacing: Spacing.md) {
                    stepperButton(systemName: "minus") { adjustAddress(by: -1) }
                    Text("\(fixture.address)")
                        .font(Typography.bigMonoReadout)
                        .foregroundStyle(Palette.text)
                        .frame(maxWidth: .infinity)
                    stepperButton(systemName: "plus") { adjustAddress(by: 1) }
                }
                Text("channels \(fixture.address)–\(fixture.channelRange.end)")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.muted)
            }

            Button {
                model.locateSelected()
            } label: {
                Text("Locate fixture")
                    .font(Typography.sans(15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.minTouchTarget)
                    .foregroundStyle(Palette.onAccent)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            }

            HStack(spacing: Spacing.md) {
                Button("Duplicate") {
                    model.edit { patch in try patch.duplicateFixture(id: fixture.id) }
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Delete") {
                    showingDeleteConfirmation = true
                }
                .buttonStyle(SecondaryButtonStyle(tint: Palette.danger))
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Palette.surface)
        .confirmationDialog("Delete \(fixture.name)?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                model.edit { patch in try patch.removeFixture(id: fixture.id) }
                model.selectedFixtureIDForInspector = nil
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(Typography.caption).foregroundStyle(Palette.muted)
            Spacer()
            Text(value).font(Typography.sans(14, weight: .medium)).foregroundStyle(Palette.text)
        }
    }

    private func stepperButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .bold))
                .frame(width: Metrics.minTouchTarget, height: Metrics.minTouchTarget)
                .foregroundStyle(Palette.text)
                .background(Palette.raised)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
    }

    private func adjustAddress(by delta: Int) {
        let newAddress = max(1, fixture.address + delta)
        model.edit { patch in
            try patch.readdress(id: fixture.id, universe: fixture.universe, address: newAddress)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Palette.text

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Typography.sans(14, weight: .medium))
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.minTouchTarget)
            .foregroundStyle(tint)
            .background(Palette.raised)
            .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

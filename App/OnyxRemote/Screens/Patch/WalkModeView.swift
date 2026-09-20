import PatchKit
import SwiftUI

/// Rig-check flow: one fixture at a time, huge ID/address, Locate primary,
/// walk order on the right with checked/current/todo state.
struct WalkModeView: View {
    @Environment(AppModel.self) private var model
    @State private var checked: Set<Int> = []
    @State private var flagged: Set<Int> = []

    private var fixtures: [Fixture] {
        model.patch.fixtures(inUniverse: model.selectedUniverse)
    }

    private var currentFixture: Fixture? {
        guard fixtures.indices.contains(model.walkIndex) else { return nil }
        return fixtures[model.walkIndex]
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: Spacing.lg) {
                ProgressView(value: Double(checked.count), total: Double(max(fixtures.count, 1)))
                    .tint(Palette.accent)

                if let fixture = currentFixture {
                    VStack(spacing: Spacing.md) {
                        Text(fixture.name)
                            .font(Typography.mono(64, weight: .medium))
                            .foregroundStyle(Palette.FixtureType.mover)

                        Text("SET THE FIXTURE'S DISPLAY TO")
                            .font(Typography.sectionHeader)
                            .foregroundStyle(Palette.muted)

                        Text(String(format: "%03d", fixture.address))
                            .font(Typography.mono(56, weight: .medium))
                            .foregroundStyle(Palette.text)

                        Text("Universe \(fixture.universe) · channels \(fixture.address)–\(fixture.channelRange.end)")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.muted)

                        if flagged.contains(fixture.id) {
                            Label("Flagged", systemImage: "flag.fill")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.danger)
                        } else {
                            Label("No conflicts", systemImage: "checkmark.circle.fill")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.success)
                        }
                    }
                    .padding(Spacing.xl)
                    .frame(maxWidth: .infinity)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))

                    HStack(spacing: Spacing.md) {
                        Button {
                            model.selectedFixtureIDForInspector = fixture.id
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

                        walkButton("Test channels") { }
                        walkButton("Flag problem", tint: Palette.danger) { flagged.insert(fixture.id) }
                    }

                    HStack(spacing: Spacing.md) {
                        walkButton("Previous") {
                            model.walkIndex = max(0, model.walkIndex - 1)
                        }
                        Button {
                            checked.insert(fixture.id)
                            model.walkIndex = min(fixtures.count - 1, model.walkIndex + 1)
                        } label: {
                            Text("Checked — next fixture")
                                .font(Typography.sans(15, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .frame(height: Metrics.minTouchTarget)
                                .foregroundStyle(.white)
                                .background(Palette.success)
                                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                        }
                    }
                } else {
                    Text("No fixtures patched in this universe")
                        .foregroundStyle(Palette.muted)
                }

                Spacer()
            }
            .padding(Spacing.lg)

            Divider().overlay(Palette.border)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("WALK ORDER").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    ForEach(Array(fixtures.enumerated()), id: \.element.id) { index, fixture in
                        HStack {
                            Image(systemName: iconName(index: index, fixture: fixture))
                                .foregroundStyle(iconColor(index: index, fixture: fixture))
                            Text(fixture.name).font(Typography.sans(14)).foregroundStyle(Palette.text)
                            Spacer()
                            Text("\(fixture.address)").font(Typography.mono(12)).foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }
            }
            .padding(Spacing.lg)
            .frame(width: 220)
        }
    }

    private func iconName(index: Int, fixture: Fixture) -> String {
        if flagged.contains(fixture.id) { return "exclamationmark.circle.fill" }
        if checked.contains(fixture.id) { return "checkmark.circle.fill" }
        if index == model.walkIndex { return "circle.inset.filled" }
        return "circle"
    }

    private func iconColor(index: Int, fixture: Fixture) -> Color {
        if flagged.contains(fixture.id) { return Palette.danger }
        if checked.contains(fixture.id) { return Palette.success }
        if index == model.walkIndex { return Palette.accent }
        return Palette.muted
    }

    private func walkButton(_ title: String, tint: Color = Palette.raised, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.sans(15, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.minTouchTarget)
                .foregroundStyle(Palette.text)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
    }
}

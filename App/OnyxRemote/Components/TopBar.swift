import SwiftUI

struct TopBar: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: Spacing.lg) {
            HStack(spacing: Spacing.sm) {
                ForEach(AppTab.allCases) { tab in
                    TabButton(tab: tab, isSelected: model.selectedTab == tab) {
                        model.selectedTab = tab
                    }
                }
            }

            Spacer()

            ConnectionChip(state: model.session.connectionState)

            Button(action: model.undo) {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .labelStyle(.iconOnly)
                    .frame(width: Metrics.minTouchTarget, height: Metrics.minTouchTarget)
            }
            .disabled(!model.canUndo)
            .foregroundStyle(model.canUndo ? Palette.text : Palette.muted)
        }
        .padding(.horizontal, Spacing.lg)
        .frame(height: Metrics.topBarHeight)
        .background(Palette.surface)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Palette.border).frame(height: 1)
        }
    }
}

private struct TabButton: View {
    let tab: AppTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tab.rawValue)
                .font(Typography.sans(15, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text)
                .padding(.horizontal, Spacing.md)
                .frame(height: 36)
                .background(isSelected ? Palette.accent : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .accessibilityIdentifier("tab.\(tab.rawValue)")
    }
}

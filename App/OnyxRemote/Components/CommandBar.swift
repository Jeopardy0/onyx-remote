import SwiftUI

enum CommandBarPrimary {
    case record
    case update
}

/// Shared bottom bar for Program/Position/Keypad: command line mirror,
/// keypad shortcut, Clear, Update, Record.
struct CommandBar: View {
    @Environment(AppModel.self) private var model
    var primary: CommandBarPrimary = .record

    var body: some View {
        HStack(spacing: Spacing.md) {
            Text("> " + (model.session.commandLineText.isEmpty ? " " : model.session.commandLineText))
                .font(Typography.commandLine)
                .foregroundStyle(Palette.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.md)
                .frame(height: Metrics.minTouchTarget)
                .background(Palette.raised)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))

            Button {
                model.selectedTab = .keypad
            } label: {
                Image(systemName: "square.grid.3x3.fill")
                    .frame(width: Metrics.minTouchTarget, height: Metrics.minTouchTarget)
                    .foregroundStyle(Palette.text)
                    .background(Palette.raised)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            }

            commandButton("Clear", tint: Palette.raised, textColor: Palette.text) {
                model.clearProgrammer()
            }
            commandButton("Update", tint: primary == .update ? Palette.accent : Palette.raised, textColor: primary == .update ? Palette.onAccent : Palette.text) {
                model.update()
            }
            commandButton("Record", tint: primary == .record ? Palette.accent : Palette.raised, textColor: primary == .record ? Palette.onAccent : Palette.text) {
                model.record()
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
    }

    private func commandButton(_ title: String, tint: Color, textColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.sans(15, weight: .semibold))
                .padding(.horizontal, Spacing.lg)
                .frame(height: Metrics.minTouchTarget)
                .foregroundStyle(textColor)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
    }
}

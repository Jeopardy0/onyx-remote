import ConsoleKit
import SwiftUI

private struct KeypadCell {
    let key: NXKKey
    let span: Int
}

/// Replicates the NX K key layout exactly: function block, edit block, and
/// numeric block with the wide keys on the right. See docs/ONYX_INTEGRATION.md
/// §1.7 for which keys have a documented OSC address.
struct NXKKeypadGrid: View {
    @Environment(AppModel.self) private var model
    @State private var pressedKey: NXKKey?

    private static let rows: [[KeypadCell]] = [
        [.init(key: .menu, span: 1), .init(key: .macro, span: 1), .init(key: .snapShot, span: 1), .init(key: .bank, span: 1), .init(key: .preview, span: 1), .init(key: .highLight, span: 1)],
        [.init(key: .fade, span: 1), .init(key: .delay, span: 1), .init(key: .swapProg, span: 1), .init(key: .link, span: 1), .init(key: .last, span: 1), .init(key: .next, span: 1)],
        [.init(key: .edit, span: 2), .init(key: .undo, span: 2), .init(key: .clear, span: 2)],
        [.init(key: .copy, span: 2), .init(key: .move, span: 2), .init(key: .delete, span: 2)],
        [.init(key: .slash, span: 1), .init(key: .dash, span: 1), .init(key: .plus, span: 1), .init(key: .backspace, span: 1), .init(key: .record, span: 2)],
        [.init(key: .digit(7), span: 1), .init(key: .digit(8), span: 1), .init(key: .digit(9), span: 1), .init(key: .thru, span: 1), .init(key: .update, span: 2)],
        [.init(key: .digit(4), span: 1), .init(key: .digit(5), span: 1), .init(key: .digit(6), span: 1), .init(key: .full, span: 1), .init(key: .load, span: 2)],
        [.init(key: .digit(1), span: 1), .init(key: .digit(2), span: 1), .init(key: .digit(3), span: 1), .init(key: .at, span: 1), .init(key: .group, span: 2)],
        [.init(key: .digit(0), span: 1), .init(key: .dot, span: 1), .init(key: .enter, span: 2), .init(key: .cue, span: 2)]
    ]

    var body: some View {
        Grid(horizontalSpacing: Spacing.sm, verticalSpacing: Spacing.sm) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                GridRow {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        keyButton(cell.key)
                            .gridCellColumns(cell.span)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color(hex: 0x33383F)) // "gray body" the keys sit on
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }

    private func keyButton(_ key: NXKKey) -> some View {
        let isDocumented = key.hasDocumentedOSCAddress
        return Button {
            pressedKey = key
            model.pressKey(key)
        } label: {
            VStack(spacing: 6) {
                Text(key.label)
                    .font(Typography.sans(13, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(isDocumented ? Palette.text : Palette.muted)
                Circle()
                    .fill(pressedKey == key ? Palette.accent : Color.black.opacity(0.4))
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.6), lineWidth: 1)
            )
        }
        .disabled(!isDocumented)
        .opacity(isDocumented ? 1 : 0.5)
    }
}

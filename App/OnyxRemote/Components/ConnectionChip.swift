import ConsoleKit
import SwiftUI

struct ConnectionChip: View {
    let state: ConnectionState

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(Typography.caption)
                .foregroundStyle(Palette.muted)
        }
        .padding(.horizontal, Spacing.sm)
        .frame(height: 28)
        .background(Palette.raised)
        .clipShape(Capsule())
    }

    private var text: String {
        switch state {
        case .connected: return "Connected · Main Console"
        case .connecting: return "Connecting…"
        case .offline(let reason): return reason.map { "Offline · \($0)" } ?? "Offline"
        }
    }

    private var color: Color {
        switch state {
        case .connected: return Palette.success
        case .connecting: return Palette.accent
        case .offline: return Palette.danger
        }
    }
}

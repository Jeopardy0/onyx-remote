import ConsoleKit
import SwiftUI

struct IntensityTabView: View {
    @Environment(AppModel.self) private var model
    @State private var intensity: Double = 100

    var body: some View {
        HStack(spacing: Spacing.xxl) {
            VStack(spacing: Spacing.sm) {
                Text("\(Int(intensity))%").font(Typography.mono(28, weight: .medium)).foregroundStyle(Palette.text)
                VerticalFader(value: $intensity)
                    .frame(width: 64)
                    .onChange(of: intensity) { _, newValue in
                        model.setValue(.intensity, newValue)
                    }
            }
            .frame(height: 320)

            VStack(spacing: Spacing.md) {
                quickButton("Full") { intensity = 100 }
                quickButton("75%") { intensity = 75 }
                quickButton("50%") { intensity = 50 }
                quickButton("0%") { intensity = 0 }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func quickButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.sans(15, weight: .medium))
                .frame(width: 100, height: Metrics.minTouchTarget)
                .foregroundStyle(Palette.text)
                .background(Palette.raised)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
    }
}

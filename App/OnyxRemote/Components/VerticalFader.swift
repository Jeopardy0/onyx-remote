import SwiftUI

/// A simple drag-to-set vertical fader, 0...100. Used for Intensity and the
/// Color tab's intensity fader.
struct VerticalFader: View {
    @Binding var value: Double
    var tint: Color = Palette.accent

    var body: some View {
        GeometryReader { geometry in
            let filledHeight = geometry.size.height * CGFloat(value / 100)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6).fill(Palette.raised)
                RoundedRectangle(cornerRadius: 6)
                    .fill(tint)
                    .frame(height: filledHeight)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    let fraction = 1 - (drag.location.y / geometry.size.height)
                    value = min(100, max(0, Double(fraction) * 100))
                }
            )
        }
    }
}

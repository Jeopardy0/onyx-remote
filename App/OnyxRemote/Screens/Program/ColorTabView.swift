import ConsoleKit
import SwiftUI

struct ColorTabView: View {
    @Environment(AppModel.self) private var model
    @State private var hue: Double = 0.08
    @State private var saturation: Double = 0.84
    @State private var intensity: Double = 75

    private let recentColors: [Color] = [
        Color(hex: 0xF2A93B), Color(hex: 0xFF6B5E), Color(hex: 0xFF4FA3), Color(hex: 0x8A5CFF),
        Color(hex: 0x3B82F6), Color(hex: 0x2FD5C8), Color(hex: 0x4CC38A), Color(hex: 0xFFF3D6)
    ]

    private let palettes = ["Warm white", "Cool white", "Deep blue", "Magenta", "Amber", "Red"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top, spacing: Spacing.xxl) {
                ColorWheel(hue: $hue, saturation: $saturation)
                    .frame(width: 260, height: 260)
                    .onChange(of: hue) { _, _ in pushColor() }
                    .onChange(of: saturation) { _, _ in pushColor() }

                VStack(alignment: .leading, spacing: Spacing.md) {
                    Text("RECENT COLORS").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Spacing.sm) {
                        ForEach(Array(recentColors.enumerated()), id: \.offset) { _, color in
                            RoundedRectangle(cornerRadius: 8).fill(color).frame(height: 40)
                        }
                    }

                    HStack {
                        Text("Hue").font(Typography.caption).foregroundStyle(Palette.muted)
                        Spacer()
                        Text("\(Int(hue * 360))°").font(Typography.mono(14)).foregroundStyle(Palette.text)
                    }
                    HStack {
                        Text("Saturation").font(Typography.caption).foregroundStyle(Palette.muted)
                        Spacer()
                        Text("\(Int(saturation * 100))%").font(Typography.mono(14)).foregroundStyle(Palette.text)
                    }
                }

                VStack(spacing: Spacing.sm) {
                    Text("\(Int(intensity))%").font(Typography.mono(16, weight: .medium)).foregroundStyle(Palette.text)
                    VerticalFader(value: $intensity)
                        .frame(width: 48)
                        .onChange(of: intensity) { _, newValue in
                            model.setValue(.intensity, newValue)
                        }
                }
                .frame(height: 240)
            }

            Text("COLOR PALETTES").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
            HStack(spacing: Spacing.sm) {
                ForEach(palettes, id: \.self) { palette in
                    Text(palette)
                        .font(Typography.caption)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(Palette.text)
                        .background(Palette.raised)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                }
                Button {
                } label: {
                    Label("Save", systemImage: "plus")
                        .font(Typography.caption)
                        .frame(width: 60, height: 44)
                        .foregroundStyle(Palette.accent)
                        .background(Palette.raised)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
    }

    private func pushColor() {
        model.setValue(ParameterID(group: .color, name: "Hue"), hue * 360)
        model.setValue(ParameterID(group: .color, name: "Saturation"), saturation * 100)
    }
}

private struct ColorWheel: View {
    @Binding var hue: Double
    @Binding var saturation: Double

    var body: some View {
        GeometryReader { geometry in
            let radius = min(geometry.size.width, geometry.size.height) / 2
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                Circle()
                    .fill(AngularGradient(gradient: Gradient(colors: rainbow), center: .center))
                Circle()
                    .fill(RadialGradient(gradient: Gradient(colors: [.white, .white.opacity(0)]), center: .center, startRadius: 0, endRadius: radius))
                Circle()
                    .stroke(Palette.border, lineWidth: 1)
                Circle()
                    .fill(Color(hue: hue, saturation: saturation, brightness: 1))
                    .frame(width: 22, height: 22)
                    .overlay(Circle().stroke(.white, lineWidth: 2))
                    .position(knobPosition(center: center, radius: radius))
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0).onChanged { drag in
                    let dx = Double(drag.location.x - center.x)
                    let dy = Double(drag.location.y - center.y)
                    let distance = min(Double(radius), (dx * dx + dy * dy).squareRoot())
                    var angle = atan2(dy, dx) / (2 * Double.pi)
                    if angle < 0 { angle += 1 }
                    hue = angle
                    saturation = distance / Double(radius)
                }
            )
        }
    }

    private var rainbow: [Color] {
        stride(from: 0.0, through: 1.0, by: 1.0 / 12.0).map { Color(hue: $0, saturation: 1, brightness: 1) }
    }

    private func knobPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = hue * 2 * Double.pi
        let distance = saturation * Double(radius)
        let x = center.x + CGFloat(cos(angle) * distance)
        let y = center.y + CGFloat(sin(angle) * distance)
        return CGPoint(x: x, y: y)
    }
}

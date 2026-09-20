import ConsoleKit
import PatchKit
import SwiftUI

/// Pan/tilt pad for every selected fixture, current one emphasized, plus a
/// previous/next stepper, large-readout sliders, and a palette Update
/// banner. Exact values go through the Keypad — encoders here only send
/// relative nudges (see docs/ONYX_INTEGRATION.md §1.8).
struct PositionTabView: View {
    @Environment(AppModel.self) private var model
    @State private var currentIndex = 0
    @State private var pan: Double = 180
    @State private var tilt: Double = 90
    @State private var editingPaletteName = "Center Stage"

    private let palettes = ["Center Stage", "Downstage L", "Downstage R", "Band", "Audience"]

    private var fixtures: [Fixture] { model.selectedFixtures }

    private var current: Fixture? {
        fixtures.indices.contains(currentIndex) ? fixtures[currentIndex] : fixtures.first
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            HStack(alignment: .top, spacing: Spacing.xxl) {
                PanTiltPad(fixtures: fixtures, currentID: current?.id)
                    .frame(width: 320, height: 320)

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    HStack {
                        Button { step(-1) } label: { Image(systemName: "chevron.left") }
                            .frame(width: Metrics.minTouchTarget, height: Metrics.minTouchTarget)
                        VStack {
                            Text(current?.name ?? "—").font(Typography.sans(16, weight: .semibold)).foregroundStyle(Palette.text)
                            if let current {
                                Text("Spot Mover · \(currentIndex + 1) of \(fixtures.count)")
                                    .font(Typography.caption).foregroundStyle(Palette.muted)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        Button { step(1) } label: { Image(systemName: "chevron.right") }
                            .frame(width: Metrics.minTouchTarget, height: Metrics.minTouchTarget)
                    }
                    .foregroundStyle(Palette.text)

                    sliderRow(title: "PAN", value: $pan, range: 0...540, unit: "°", parameter: .pan)
                    sliderRow(title: "TILT", value: $tilt, range: 0...270, unit: "°", parameter: .tilt)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Editing \(editingPaletteName)").font(Typography.sans(14, weight: .semibold)).foregroundStyle(Palette.text)
                            Text("Not saved to the palette yet").font(Typography.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Button("Update") { model.update() }
                            .font(Typography.sans(14, weight: .semibold))
                            .padding(.horizontal, Spacing.md)
                            .frame(height: 36)
                            .foregroundStyle(Palette.onAccent)
                            .background(Palette.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(Spacing.md)
                    .background(Palette.raised)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Metrics.cornerRadius).stroke(Palette.accent, lineWidth: 1))

                    Text("POSITION PALETTES").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    HStack(spacing: Spacing.sm) {
                        ForEach(palettes, id: \.self) { palette in
                            VStack(spacing: 2) {
                                Text(palette).font(Typography.caption).foregroundStyle(Palette.text)
                                Text("4 fixtures").font(.system(size: 10)).foregroundStyle(Palette.muted)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(palette == editingPaletteName ? Palette.raised : Palette.raised.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(palette == editingPaletteName ? Palette.accent : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture { editingPaletteName = palette }
                        }
                    }
                }
            }
            Spacer()
            CommandBar(primary: .update)
        }
        .padding(.top, Spacing.lg)
        .padding(.horizontal, Spacing.lg)
    }

    private func step(_ delta: Int) {
        guard !fixtures.isEmpty else { return }
        currentIndex = (currentIndex + delta + fixtures.count) % fixtures.count
    }

    private func sliderRow(title: String, value: Binding<Double>, range: ClosedRange<Double>, unit: String, parameter: ParameterID) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(title).font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(Int(value.wrappedValue))\(unit)").font(Typography.mono(20, weight: .medium)).foregroundStyle(Palette.text)
            }
            Slider(value: value, in: range) { _ in
                model.setValue(parameter, value.wrappedValue)
            }
            .tint(Palette.accent)
            .frame(minHeight: Metrics.minTouchTarget)
        }
    }
}

private struct PanTiltPad: View {
    let fixtures: [Fixture]
    let currentID: Int?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Metrics.cornerRadius).fill(Palette.surface)
            GeometryReader { geometry in
                Path { path in
                    let step = geometry.size.width / 8
                    for i in 0...8 {
                        let x = CGFloat(i) * step
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    let stepY = geometry.size.height / 8
                    for i in 0...8 {
                        let y = CGFloat(i) * stepY
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(Palette.border, lineWidth: 0.5)

                ForEach(Array(fixtures.enumerated()), id: \.element.id) { index, fixture in
                    let point = position(for: index, in: geometry.size)
                    Circle()
                        .fill(fixture.id == currentID ? Palette.accent : Palette.FixtureType.mover)
                        .frame(width: fixture.id == currentID ? 18 : 10, height: fixture.id == currentID ? 18 : 10)
                        .position(point)
                }
            }
            .padding(Spacing.md)
        }
    }

    private func position(for index: Int, in size: CGSize) -> CGPoint {
        // Static placeholder layout for M0's mock data — real positions come
        // from live pan/tilt feedback once M1 wires it up.
        let spread = CGFloat(index) * 28 - CGFloat(fixtures.count) * 14
        return CGPoint(x: size.width / 2 + spread, y: size.height / 2)
    }
}

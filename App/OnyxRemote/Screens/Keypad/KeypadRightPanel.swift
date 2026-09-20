import ConsoleKit
import PatchKit
import SwiftUI

struct KeypadRightPanel: View {
    @Environment(AppModel.self) private var model
    @State private var encoderMode: EncoderMode = .parameter

    enum EncoderMode: String, CaseIterable { case parameter = "Parameter", screen = "Screen" }

    private let encoderTitles = ["Pan", "Tilt", "Pan fine", "Tilt fine"]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("COMMAND LINE").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    Spacer()
                    liveChip
                }
                Text("> " + (model.session.commandLineText.isEmpty ? " " : model.session.commandLineText))
                    .font(Typography.mono(20))
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Spacing.md)
                    .background(Palette.raised)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            }

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("SELECTED").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                FlowChips(fixtures: model.selectedFixtures)
            }

            HStack(spacing: Spacing.sm) {
                ForEach([ParameterGroup.intensity, .position, .color, .beam], id: \.self) { group in
                    Button {
                        model.selectedParameterGroup = group
                    } label: {
                        Text(group.rawValue.capitalized)
                            .font(Typography.caption)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .foregroundStyle(model.selectedParameterGroup == group ? Palette.onAccent : Palette.text)
                            .background(model.selectedParameterGroup == group ? Palette.accent : Palette.raised)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            Picker("Encoder mode", selection: $encoderMode) {
                ForEach(EncoderMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
                ForEach(encoderTitles, id: \.self) { title in
                    EncoderDial(title: title)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
        .frame(width: 320, alignment: .top)
        .background(Palette.surface)
    }

    private var liveChip: some View {
        HStack(spacing: 4) {
            Circle().fill(Palette.success).frame(width: 6, height: 6)
            Text("Live").font(Typography.caption).foregroundStyle(Palette.muted)
        }
    }
}

private struct FlowChips: View {
    let fixtures: [Fixture]

    var body: some View {
        HStack {
            ForEach(fixtures.prefix(6)) { fixture in
                Text("\(fixture.id) \(fixture.name)")
                    .font(Typography.caption)
                    .padding(.horizontal, Spacing.sm)
                    .frame(height: 28)
                    .foregroundStyle(Palette.text)
                    .background(Palette.raised)
                    .clipShape(Capsule())
            }
            if fixtures.isEmpty {
                Text("None").font(Typography.caption).foregroundStyle(Palette.muted)
            }
        }
    }
}

private struct EncoderDial: View {
    let title: String
    @State private var value: Double = 0

    var body: some View {
        VStack(spacing: Spacing.xs) {
            ZStack {
                Circle().stroke(Palette.border, lineWidth: 6)
                Circle()
                    .trim(from: 0, to: 0.65)
                    .stroke(Palette.accent, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .rotationEffect(.degrees(135))
                Circle().fill(Palette.accent).frame(width: 6, height: 6).offset(y: -28)
                Text("\(Int(value))").font(Typography.mono(16, weight: .medium)).foregroundStyle(Palette.text)
            }
            .frame(width: 72, height: 72)
            .gesture(
                DragGesture(minimumDistance: 1).onChanged { drag in
                    value = max(0, min(359, value - drag.translation.height))
                }
            )
            Text(title).font(Typography.caption).foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Palette.raised)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }
}

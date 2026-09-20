import ConsoleKit
import SwiftUI

/// The design spec doesn't detail Beam beyond "one of the four Program tabs"
/// — generic zoom/focus faders plus a gobo picker cover the common case
/// until specific fixture-profile beam parameters are wired up.
struct BeamTabView: View {
    @Environment(AppModel.self) private var model
    @State private var zoom: Double = 50
    @State private var focus: Double = 50
    @State private var selectedGobo = 0

    private let gobos = ["Open", "Breakup", "Dots", "Stars", "Linear", "Frost"]

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.xxl) {
            faderColumn(title: "Zoom", value: $zoom, parameter: ParameterID(group: .beam, name: "Zoom"))
            faderColumn(title: "Focus", value: $focus, parameter: ParameterID(group: .beam, name: "Focus"))

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("GOBO").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm) {
                    ForEach(Array(gobos.enumerated()), id: \.offset) { index, gobo in
                        Button {
                            selectedGobo = index
                            model.setValue(ParameterID(group: .beam, name: "Gobo"), Double(index))
                        } label: {
                            Text(gobo)
                                .font(Typography.sans(14, weight: .medium))
                                .frame(width: 110, height: Metrics.minTouchTarget)
                                .foregroundStyle(selectedGobo == index ? Palette.onAccent : Palette.text)
                                .background(selectedGobo == index ? Palette.accent : Palette.raised)
                                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func faderColumn(title: String, value: Binding<Double>, parameter: ParameterID) -> some View {
        VStack(spacing: Spacing.sm) {
            Text(title).font(Typography.sectionHeader).foregroundStyle(Palette.muted)
            Text("\(Int(value.wrappedValue))%").font(Typography.mono(20, weight: .medium)).foregroundStyle(Palette.text)
            VerticalFader(value: value)
                .frame(width: 56)
                .onChange(of: value.wrappedValue) { _, newValue in
                    model.setValue(parameter, newValue)
                }
        }
        .frame(height: 260)
    }
}

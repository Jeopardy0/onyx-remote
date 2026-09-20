import ConsoleKit
import SwiftUI

struct ProgramScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                FixtureTilesSidebar()
                Divider().overlay(Palette.border)
                VStack(spacing: 0) {
                    parameterGroupPicker
                    Group {
                        switch model.selectedParameterGroup {
                        case .intensity:
                            IntensityTabView()
                        case .color:
                            ColorTabView()
                        case .position:
                            PositionTabView()
                        case .beam:
                            BeamTabView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            CommandBar(primary: .record)
        }
        .background(Palette.background)
    }

    private var parameterGroupPicker: some View {
        HStack(spacing: Spacing.sm) {
            ForEach([ParameterGroup.intensity, .color, .position, .beam], id: \.self) { group in
                Button {
                    model.selectedParameterGroup = group
                } label: {
                    Text(group.rawValue.capitalized)
                        .font(Typography.sans(14, weight: model.selectedParameterGroup == group ? .semibold : .regular))
                        .padding(.horizontal, Spacing.md)
                        .frame(height: 36)
                        .foregroundStyle(model.selectedParameterGroup == group ? Palette.onAccent : Palette.text)
                        .background(model.selectedParameterGroup == group ? Palette.accent : Palette.raised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            Spacer()
        }
        .padding(Spacing.lg)
    }
}

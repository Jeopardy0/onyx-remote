import Observation
import PatchKit
import SwiftUI

struct PatchScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 0) {
            UniverseSidebar()
                .frame(width: 220)

            Divider().overlay(Palette.border)

            VStack(spacing: 0) {
                PatchScreenHeader()

                if let conflict = model.patch.conflicts(inUniverse: model.selectedUniverse).first {
                    ConflictBanner(conflict: conflict)
                }

                Group {
                    switch model.patchViewMode {
                    case .map:
                        PatchMapView()
                    case .list:
                        PatchListView()
                    case .walk:
                        WalkModeView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if model.patchViewMode != .walk, let selectedID = model.selectedFixtureIDForInspector,
               let fixture = model.patch.fixture(withID: selectedID) {
                Divider().overlay(Palette.border)
                FixtureInspector(fixture: fixture)
                    .frame(width: 260)
            }
        }
        .background(Palette.background)
        .sheet(isPresented: Bindable(model).showingAddFixtures) {
            AddFixturesSheet()
        }
    }
}

private struct PatchScreenHeader: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack {
            Picker("View", selection: Bindable(model).patchViewMode) {
                ForEach(PatchViewMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            Spacer()

            Button {
                model.showingAddFixtures = true
            } label: {
                Label("Add fixtures", systemImage: "plus")
                    .font(Typography.sans(15, weight: .semibold))
                    .padding(.horizontal, Spacing.md)
                    .frame(height: Metrics.minTouchTarget)
                    .foregroundStyle(Palette.onAccent)
                    .background(Palette.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
            }
        }
        .padding(Spacing.lg)
    }
}

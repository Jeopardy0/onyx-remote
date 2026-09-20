import SwiftUI

struct RootView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(spacing: 0) {
            TopBar()
            content
        }
        .background(Palette.background)
    }

    @ViewBuilder
    private var content: some View {
        switch model.selectedTab {
        case .patch:
            PatchScreen()
        case .program:
            ProgramScreen()
        case .keypad:
            KeypadScreen()
        case .cues:
            CuesScreen()
        }
    }
}

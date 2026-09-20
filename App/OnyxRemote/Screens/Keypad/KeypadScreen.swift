import SwiftUI

struct KeypadScreen: View {
    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                NXKKeypadGrid()
                    .padding(Spacing.lg)
            }
            Divider().overlay(Palette.border)
            KeypadRightPanel()
        }
        .background(Palette.background)
    }
}

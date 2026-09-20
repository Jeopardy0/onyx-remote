import PatchKit
import SwiftUI

/// 512 DMX slots per universe, drawn as 16 rows x 32 columns per the design
/// spec. Each fixture is a colored block labeled with its ID; channels
/// claimed by more than one fixture render as red hatching.
struct PatchMapView: View {
    @Environment(AppModel.self) private var model

    private let columns = 32
    private let rows = 16

    var body: some View {
        GeometryReader { geometry in
            let cellWidth = geometry.size.width / CGFloat(columns)
            let cellHeight = geometry.size.height / CGFloat(rows)
            let claims = channelClaims()

            Canvas { context, _ in
                for channel in 1...(rows * columns) {
                    let row = (channel - 1) / columns
                    let col = (channel - 1) % columns
                    let rect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
                    draw(channel: channel, in: rect, claims: claims, context: &context)
                }

                for fixture in model.patch.fixtures(inUniverse: model.selectedUniverse) {
                    drawLabel(for: fixture, cellWidth: cellWidth, cellHeight: cellHeight, columns: columns, context: &context)
                    if fixture.id == model.selectedFixtureIDForInspector {
                        drawSelectionOutline(for: fixture, cellWidth: cellWidth, cellHeight: cellHeight, columns: columns, context: &context)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(
                SpatialTapGesture().onEnded { value in
                    let col = Int(value.location.x / cellWidth)
                    let row = Int(value.location.y / cellHeight)
                    let channel = row * columns + col + 1
                    if let fixtureID = claims[channel]?.first {
                        model.selectedFixtureIDForInspector = fixtureID
                    }
                }
            )
        }
        .padding(Spacing.lg)
        .background(Palette.background)
    }

    private func channelClaims() -> [Int: [Int]] {
        var claims: [Int: [Int]] = [:]
        for fixture in model.patch.fixtures(inUniverse: model.selectedUniverse) {
            let range = fixture.channelRange
            for channel in range.start...range.end {
                claims[channel, default: []].append(fixture.id)
            }
        }
        return claims
    }

    private func draw(channel: Int, in rect: CGRect, claims: [Int: [Int]], context: inout GraphicsContext) {
        let fixtureIDs = claims[channel] ?? []
        context.stroke(Path(rect), with: .color(Palette.border), lineWidth: 0.5)

        guard let firstID = fixtureIDs.first, let fixture = model.patch.fixture(withID: firstID) else { return }

        if fixtureIDs.count > 1 {
            context.fill(Path(rect), with: .color(Palette.danger.opacity(0.35)))
            drawHatch(in: rect, context: &context)
        } else {
            context.fill(Path(rect), with: .color(fixture.category.color.opacity(0.55)))
        }
    }

    private func drawHatch(in rect: CGRect, context: inout GraphicsContext) {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        context.stroke(path, with: .color(Palette.danger), lineWidth: 1)
    }

    private func drawLabel(for fixture: Fixture, cellWidth: CGFloat, cellHeight: CGFloat, columns: Int, context: inout GraphicsContext) {
        let startChannel = fixture.address
        let row = (startChannel - 1) / columns
        let col = (startChannel - 1) % columns
        let origin = CGPoint(x: CGFloat(col) * cellWidth + 4, y: CGFloat(row) * cellHeight + 2)
        let text = Text(fixture.name).font(.system(size: min(cellHeight * 0.5, 11), weight: .semibold)).foregroundColor(Palette.text)
        context.draw(context.resolve(text), at: origin, anchor: .topLeading)
    }

    private func drawSelectionOutline(for fixture: Fixture, cellWidth: CGFloat, cellHeight: CGFloat, columns: Int, context: inout GraphicsContext) {
        let range = fixture.channelRange
        for channel in range.start...range.end {
            let row = (channel - 1) / columns
            let col = (channel - 1) % columns
            let rect = CGRect(x: CGFloat(col) * cellWidth, y: CGFloat(row) * cellHeight, width: cellWidth, height: cellHeight)
            context.stroke(Path(rect.insetBy(dx: 1, dy: 1)), with: .color(Palette.accent), lineWidth: 2)
        }
    }
}

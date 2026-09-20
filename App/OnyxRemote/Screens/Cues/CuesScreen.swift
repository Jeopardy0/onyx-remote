import ConsoleKit
import SwiftUI

struct CuesScreen: View {
    @Environment(AppModel.self) private var model

    private let perPage = 8
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var allPlaybacks: [SamplePlayback] {
        model.session.playbacks.values.sorted { $0.id < $1.id }
    }

    private var pageCount: Int {
        max(1, Int(ceil(Double(allPlaybacks.count) / Double(perPage))))
    }

    private var currentPagePlaybacks: [SamplePlayback] {
        let start = model.cuesPage * perPage
        let end = min(start + perPage, allPlaybacks.count)
        guard start < end else { return [] }
        return Array(allPlaybacks[start..<end])
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HStack {
                    Text("Playbacks").font(Typography.title).foregroundStyle(Palette.text)
                    Spacer()
                    Button { model.cuesPage = max(0, model.cuesPage - 1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Text("Page \(model.cuesPage + 1) of \(pageCount)").font(Typography.caption).foregroundStyle(Palette.muted)
                    Button { model.cuesPage = min(pageCount - 1, model.cuesPage + 1) } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .foregroundStyle(Palette.text)

                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(currentPagePlaybacks) { playback in
                        PlaybackTile(playback: playback)
                    }
                }
                Spacer()
            }
            .padding(Spacing.lg)

            Divider().overlay(Palette.border)

            SelectedCuelistPanel()
                .frame(width: 320)
        }
        .background(Palette.background)
    }
}

private struct PlaybackTile: View {
    @Environment(AppModel.self) private var model
    let playback: SamplePlayback

    private var isRunning: Bool {
        if case .running = playback.state { return true }
        return false
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("PB \(playback.id)").font(Typography.caption).foregroundStyle(Palette.muted)
                Spacer()
            }
            Text(playback.name).font(Typography.sans(15, weight: .semibold)).foregroundStyle(Palette.text)
            Text("\(playback.cueCount) cues").font(Typography.caption).foregroundStyle(Palette.muted)

            stateChip

            HStack {
                Text("Level").font(.system(size: 10)).foregroundStyle(Palette.muted)
                Spacer()
                Text("\(Int(playback.level * 100))%").font(Typography.mono(11)).foregroundStyle(Palette.muted)
            }
            ProgressView(value: playback.level).tint(Palette.success)

            Button { model.go(playbackID: playback.id) } label: {
                Text("GO")
                    .font(Typography.sans(15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: Metrics.minTouchTarget)
                    .foregroundStyle(.white)
                    .background(Palette.success)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Button { model.release(playbackID: playback.id) } label: {
                Text("Release")
                    .font(Typography.sans(14, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundStyle(Palette.text)
                    .background(Palette.raised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(Spacing.md)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.cornerRadius)
                .stroke(isRunning ? Palette.accent : Color.clear, lineWidth: 1)
        )
    }

    private var stateChip: some View {
        Group {
            switch playback.state {
            case .stopped:
                Text("Stopped").foregroundStyle(Palette.muted)
            case .running(let cue):
                Text("Running · Cue \(cue)").foregroundStyle(Palette.success)
            }
        }
        .font(Typography.caption)
        .padding(.horizontal, Spacing.sm)
        .frame(height: 22)
        .background(Palette.raised)
        .clipShape(Capsule())
    }
}

private struct SelectedCuelistPanel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CUE LIST").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                Text(model.selectedCuelist.name).font(Typography.title).foregroundStyle(Palette.text)
                Text("\(model.selectedCuelist.cues.count) cues · running").font(Typography.caption).foregroundStyle(Palette.muted)
            }

            ScrollView {
                LazyVStack(spacing: 1) {
                    ForEach(model.selectedCuelist.cues) { cue in
                        HStack {
                            Text("\(cue.number)").font(Typography.mono(13)).foregroundStyle(Palette.muted).frame(width: 20)
                            Text(cue.name).font(Typography.sans(14)).foregroundStyle(Palette.text)
                            Spacer()
                            if let tag = cue.tag {
                                Text(tag == .now ? "Now" : "Next")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .frame(height: 18)
                                    .foregroundStyle(tag == .now ? Palette.onAccent : Palette.text)
                                    .background(tag == .now ? Palette.accent : Palette.raised)
                                    .clipShape(Capsule())
                            }
                            Text(String(format: "%.1fs", cue.time)).font(Typography.mono(12)).foregroundStyle(Palette.muted)
                        }
                        .padding(.vertical, Spacing.sm)
                        .padding(.horizontal, Spacing.sm)
                        .background(cue.tag == .now ? Palette.raised : Color.clear)
                    }
                }
            }

            Spacer()

            HStack(spacing: Spacing.sm) {
                transportButton("Back", tint: Palette.raised, textColor: Palette.text) {}
                transportButton("GO", tint: Palette.success, textColor: .white) {
                    model.go(playbackID: model.selectedCuelist.playbackID)
                }
                transportButton("Pause", tint: Palette.raised, textColor: Palette.text) {}
            }
        }
        .padding(Spacing.lg)
        .background(Palette.surface)
    }

    private func transportButton(_ title: String, tint: Color, textColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Typography.sans(15, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: Metrics.minTouchTarget)
                .foregroundStyle(textColor)
                .background(tint)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
        }
    }
}

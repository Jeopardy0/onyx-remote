import PatchKit
import SwiftUI

struct AddFixturesSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedProfileID: String = StandardFixtureLibrary.profiles.first!.id
    @State private var selectedModeName: String = StandardFixtureLibrary.profiles.first!.modes.first!.name
    @State private var quantity: Int = 1
    @State private var universe: Int = 1
    @State private var useNextFreeAddress = true
    @State private var manualStartAddress: Int = 1

    private var library: [FixtureProfile] {
        StandardFixtureLibrary.profiles + model.patch.customProfiles
    }

    private var filteredProfiles: [FixtureProfile] {
        guard !searchText.isEmpty else { return library }
        return library.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var selectedProfile: FixtureProfile? {
        library.first { $0.id == selectedProfileID }
    }

    private var selectedMode: FixtureMode? {
        selectedProfile?.mode(named: selectedModeName)
    }

    private var footprint: Int { selectedMode?.channelCount ?? 1 }

    private var existingRanges: [Int: [ChannelRange]] {
        Dictionary(uniqueKeysWithValues: model.patch.universes.map { ($0, model.patch.channelRanges(inUniverse: $0)) })
    }

    private var previewSlots: [(universe: Int, address: Int)] {
        AutoAddress.sequentialSlots(
            count: quantity,
            footprint: footprint,
            startingUniverse: universe,
            startingAddress: useNextFreeAddress ? nil : manualStartAddress,
            existingByUniverse: existingRanges
        )
    }

    private var fits: Bool { previewSlots.count == quantity }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Add fixtures").font(Typography.title).foregroundStyle(Palette.text)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").foregroundStyle(Palette.muted)
                }
            }
            .padding(Spacing.lg)

            HStack(spacing: 0) {
                libraryList
                Divider().overlay(Palette.border)
                configurationPanel
            }

            Divider().overlay(Palette.border)

            HStack {
                Text(footerSummary).font(Typography.caption).foregroundStyle(Palette.muted)
                Spacer()
                Button("Cancel") { dismiss() }.buttonStyle(SecondaryButtonStyle())
                Button {
                    patchFixtures()
                } label: {
                    Text("Patch \(quantity) fixture\(quantity == 1 ? "" : "s")")
                        .font(Typography.sans(15, weight: .semibold))
                        .padding(.horizontal, Spacing.lg)
                        .frame(height: Metrics.minTouchTarget)
                        .foregroundStyle(Palette.onAccent)
                        .background(fits ? Palette.accent : Palette.muted)
                        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
                }
                .disabled(!fits)
            }
            .padding(Spacing.lg)
        }
        .background(Palette.surface)
        .onChange(of: selectedProfileID) {
            if let mode = selectedProfile?.modes.first { selectedModeName = mode.name }
        }
    }

    private var libraryList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("Search fixture library…", text: $searchText)
                .textFieldStyle(.plain)
                .padding(Spacing.sm)
                .background(Palette.raised)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundStyle(Palette.text)

            ScrollView {
                LazyVStack(spacing: Spacing.xs) {
                    ForEach(filteredProfiles) { profile in
                        Button {
                            selectedProfileID = profile.id
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(profile.name).font(Typography.sans(14, weight: .medium)).foregroundStyle(Palette.text)
                                Text(profile.modes.map(\.name).joined(separator: ", ") + " modes")
                                    .font(Typography.caption).foregroundStyle(Palette.muted)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(Spacing.sm)
                            .background(selectedProfileID == profile.id ? Palette.raised : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            Text("Import fixture file…").font(Typography.caption).foregroundStyle(Palette.accent)
        }
        .padding(Spacing.lg)
        .frame(width: 260)
    }

    private var configurationPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            if let profile = selectedProfile {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("MODE").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    Picker("Mode", selection: $selectedModeName) {
                        ForEach(profile.modes) { mode in
                            Text(mode.name).tag(mode.name)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }

            HStack(alignment: .top, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("HOW MANY").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    Stepper(value: $quantity, in: 1...64) {
                        Text("\(quantity)").font(Typography.mono(24, weight: .medium)).foregroundStyle(Palette.text)
                    }
                }
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("UNIVERSE").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    Stepper(value: $universe, in: 1...64) {
                        Text("\(universe)").font(Typography.mono(24, weight: .medium)).foregroundStyle(Palette.text)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("START ADDRESS").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                    Spacer()
                    Button("Next free") { useNextFreeAddress = true }
                        .font(Typography.caption)
                        .foregroundStyle(useNextFreeAddress ? Palette.onAccent : Palette.accent)
                        .padding(.horizontal, Spacing.sm)
                        .frame(height: 24)
                        .background(useNextFreeAddress ? Palette.accent : Color.clear)
                        .clipShape(Capsule())
                }
                if useNextFreeAddress {
                    Text(previewSlots.first.map { "\($0.address)" } ?? "—")
                        .font(Typography.mono(24, weight: .medium))
                        .foregroundStyle(Palette.text)
                } else {
                    Stepper(value: $manualStartAddress, in: 1...512) {
                        Text("\(manualStartAddress)").font(Typography.mono(24, weight: .medium)).foregroundStyle(Palette.text)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("PREVIEW · UNIVERSE \(universe)").font(Typography.sectionHeader).foregroundStyle(Palette.muted)
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4).fill(Palette.raised)
                        ForEach(Array(previewSlots.filter { $0.universe == universe }.enumerated()), id: \.offset) { _, slot in
                            let x = geometry.size.width * CGFloat(slot.address - 1) / 512
                            let width = max(2, geometry.size.width * CGFloat(footprint) / 512)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Palette.accent)
                                .frame(width: width)
                                .offset(x: x)
                        }
                    }
                }
                .frame(height: 20)
                HStack {
                    Text(fits ? "Fits, no conflicts" : "Doesn't fit — try a different universe or address")
                        .font(Typography.caption)
                        .foregroundStyle(fits ? Palette.success : Palette.danger)
                    Spacer()
                    Text("1").font(Typography.caption).foregroundStyle(Palette.muted)
                    Spacer()
                    Text("512").font(Typography.caption).foregroundStyle(Palette.muted)
                }
            }

            Spacer()
        }
        .padding(Spacing.lg)
    }

    private var footerSummary: String {
        guard let profile = selectedProfile, let mode = selectedMode else { return "" }
        guard let first = previewSlots.first, let last = previewSlots.last else { return "Doesn't fit" }
        let startChannel = first.address
        let endChannel = last.address + mode.channelCount - 1
        return "\(quantity) × \(profile.name), \(mode.name) · channels \(startChannel)-\(endChannel)"
    }

    private func patchFixtures() {
        guard let mode = selectedMode, fits else { return }
        let nextID = (model.patch.fixtures.map(\.id).max() ?? 0) + 1
        model.edit { patch in
            for (offset, slot) in previewSlots.enumerated() {
                let fixture = Fixture(
                    id: nextID + offset,
                    name: "\(selectedProfile?.name.prefix(1).uppercased() ?? "F")\(offset + 1)",
                    profileID: selectedProfileID,
                    category: selectedProfile?.category ?? .other,
                    modeName: mode.name,
                    footprint: mode.channelCount,
                    universe: slot.universe,
                    address: slot.address
                )
                try patch.addFixture(fixture)
            }
        }
        dismiss()
    }
}

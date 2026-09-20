import ConsoleKit
import Observation
import PatchKit

enum PatchViewMode: String, CaseIterable, Identifiable {
    case map = "Map"
    case list = "List"
    case walk = "Walk"

    var id: String { rawValue }
}

/// Top-level app state shared across every screen. Screens read/write this
/// directly rather than each owning a parallel copy of selection/patch state.
@MainActor
@Observable
final class AppModel {
    var selectedTab: AppTab = .patch

    let session: ConsoleSession
    private(set) var patchHistory: PatchHistory

    // Patch screen
    var patchViewMode: PatchViewMode = .map
    var selectedUniverse: Int = 1
    var selectedFixtureIDForInspector: Int?
    var showingAddFixtures = false
    var walkIndex: Int = 0

    // Program screen
    var selectedFixtureIDs: Set<Int> = []
    var selectedGroupFilter: FixtureCategory?
    var selectedParameterGroup: ParameterGroup = .intensity
    var lastSelectedFixtureID: Int?

    // Cues screen
    var cuesPage: Int = 0
    var selectedCuelist: SampleCuelist = SampleShow.selectedCuelist

    init(adapter: any ConsoleAdapter = MockConsoleAdapter()) {
        self.session = ConsoleSession(adapter: adapter)
        self.patchHistory = PatchHistory(current: SampleShow.patch)
    }

    var patch: Patch { patchHistory.current }

    var canUndo: Bool { patchHistory.canUndo }

    func undo() {
        _ = patchHistory.undo()
    }

    func edit(_ mutate: (inout Patch) throws -> Void) {
        try? patchHistory.apply(mutate)
    }

    // MARK: - Fixture selection (Program/Position/Keypad)

    var selectedFixtures: [Fixture] {
        patch.fixtures.filter { selectedFixtureIDs.contains($0.id) }.sorted { $0.id < $1.id }
    }

    func toggleFixtureSelection(_ id: Int) {
        if selectedFixtureIDs.contains(id) {
            selectedFixtureIDs.remove(id)
        } else {
            selectedFixtureIDs.insert(id)
        }
        lastSelectedFixtureID = id
        session.send(.select(.fixtures(Array(selectedFixtureIDs).sorted())))
    }

    func selectGroup(_ category: FixtureCategory?) {
        selectedGroupFilter = category
    }

    func fixturesForCurrentGroupFilter() -> [Fixture] {
        guard let category = selectedGroupFilter else { return patch.fixtures.sorted { $0.id < $1.id } }
        return patch.fixtures.filter { $0.category == category }.sorted { $0.id < $1.id }
    }

    func clearSelection() {
        selectedFixtureIDs.removeAll()
        session.send(.select(.none))
    }

    // MARK: - Actions the UI can send

    func locateSelected() {
        session.send(.locate(fixtureIDs: Array(selectedFixtureIDs)))
    }

    func record() {
        session.send(.record)
    }

    func update() {
        session.send(.update)
    }

    func clearProgrammer() {
        session.send(.clear)
    }

    func setValue(_ parameter: ParameterID, _ value: Double) {
        session.send(.setValue(parameter, value))
    }

    func pressKey(_ key: NXKKey) {
        session.send(.pressKey(key))
    }

    func go(playbackID: Int) {
        session.send(.go(playbackID: playbackID))
    }

    func release(playbackID: Int) {
        session.send(.release(playbackID: playbackID))
    }
}

import ConsoleKit

/// Every OSC address this app actually sends or listens for, transcribed
/// from `docs/ONYX_INTEGRATION.md`. Nothing here is invented — a case with
/// no documented address is simply absent, and callers must check
/// `NXKKey.hasDocumentedOSCAddress` before assuming `executeAddress(for:)`
/// returns something.
public enum OnyxAddressBook {
    // MARK: - Command line feedback (read-only; see integration doc §1.3)

    public static let commandLineStatusText = "/Mx/commandLine/0001/text"
    public static let commandLineText = "/Mx/commandLine/0002/text"

    // MARK: - Programmer / Highlight (integration doc §1.6)

    public static let highlight = "/Mx/button/6001"

    // MARK: - Global playback buttons (integration doc §1.4)
    //
    // These act on whichever playback/cuelist is currently "selected" on the
    // console. There is no documented OSC address to set that selection —
    // see docs/PLAN.md Open Question #1 — so `OnyxConsoleAdapter` does not
    // use these for now; they're kept here for when that's resolved.

    public static let globalSelect = "/Mx/button/5502"
    public static let globalRelease = "/Mx/button/5503"
    public static let globalSnap = "/Mx/button/5511"
    public static let globalBack = "/Mx/button/5512"
    public static let globalGo = "/Mx/button/5513"

    // MARK: - Playback Pages (integration doc §1.4) — self-describing,
    // license-gated, and the adapter's chosen mechanism for per-playback
    // Go/Release since it doesn't depend on the undocumented "select" step.

    public static func playbackPageAddress(page: Int, button: Int, action: PlaybackPageAction) -> String {
        "/Mx/playback/page\(page)/\(button)/\(action.rawValue)"
    }

    /// Maps a Cues-screen playback ID (1-based, matching `SampleShow.playbacks`)
    /// onto a Playback Pages (page, 0-based button) location. `perPage` mirrors
    /// the Cues screen's 4x2 (8-per-page) grid.
    public static func playbackPageLocation(forPlaybackID id: Int, perPage: Int = 8) -> (page: Int, button: Int) {
        let zeroBased = id - 1
        return (page: zeroBased / perPage + 1, button: zeroBased % perPage)
    }

    public enum PlaybackPageAction: String {
        case go, pause, release, select, snapGo = "snapgo", toggle, back
    }

    // MARK: - Keypad (integration doc §1.7)

    private static let keypadAddresses: [NXKKey: String] = {
        var map: [NXKKey: String] = [
            .menu: "/Mx/button/2003",
            .macro: "/Mx/button/2001",
            .preview: "/Mx/button/2002",
            .fade: "/Mx/button/4321",
            .delay: "/Mx/button/4322",
            .snapShot: "/Mx/button/4331",
            .bank: "/Mx/button/4332",
            .highLight: highlight,
            .edit: "/Mx/button/5101",
            .undo: "/Mx/button/5102",
            .clear: "/Mx/button/5103",
            .copy: "/Mx/button/5104",
            .move: "/Mx/button/5106",
            .delete: "/Mx/button/5107",
            .record: "/Mx/button/5401",
            .update: "/Mx/button/5402",
            .load: "/Mx/button/5411",
            .group: "/Mx/button/5412",
            .cue: "/Mx/button/5413",
            .dash: "/Mx/button/5210",
            .plus: "/Mx/button/5211",
            .dot: "/Mx/button/5212",
            .enter: "/Mx/button/5213",
            .slash: "/Mx/button/5214",
            .backspace: "/Mx/button/5215",
            .at: "/Mx/button/5216",
            .full: "/Mx/button/5301",
            .thru: "/Mx/button/5302",
            .last: "/Mx/button/6401",
            .next: "/Mx/button/6402",
            .link: "/Mx/button/6108"
            // .swapProg intentionally absent — not documented, see NXKKey.hasDocumentedOSCAddress.
        ]
        for digit in 0...9 {
            map[.digit(digit)] = "/Mx/button/\(5200 + digit)"
        }
        return map
    }()

    public static func executeAddress(for key: NXKKey) -> String? {
        keypadAddresses[key]
    }
}

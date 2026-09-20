/// Every physical key on the NX K keypad, laid out to match the six-column
/// grid in the design spec. `OnyxKit` maps each case to the OSC address in
/// docs/ONYX_INTEGRATION.md §1.7; cases with no documented address are still
/// modeled here so the UI can render (and disable) them rather than omit
/// them, per the "degrade gracefully, never guess" rule.
public enum NXKKey: Hashable, Sendable, CaseIterable {
    // Function block, row 1
    case menu, macro, snapShot, bank, preview, highLight
    // Function block, row 2
    case fade, delay, swapProg, link, last, next
    // Edit block
    case edit, undo, clear
    case copy, move, delete
    // Numeric block
    case digit(Int) // 0...9
    case dash, plus, dot, enter, slash, backspace, at
    case full, thru
    // Wide keys on the right of the numeric block
    case record, update, load, group, cue

    public static var allCases: [NXKKey] {
        [.menu, .macro, .snapShot, .bank, .preview, .highLight,
         .fade, .delay, .swapProg, .link, .last, .next,
         .edit, .undo, .clear, .copy, .move, .delete]
        + (0...9).map(NXKKey.digit)
        + [.dash, .plus, .dot, .enter, .slash, .backspace, .at, .full, .thru,
           .record, .update, .load, .group, .cue]
    }

    /// Short label as printed on the physical key.
    public var label: String {
        switch self {
        case .menu: return "Menu"
        case .macro: return "Macro"
        case .snapShot: return "Snap Shot"
        case .bank: return "Bank"
        case .preview: return "Preview"
        case .highLight: return "High Light"
        case .fade: return "Fade"
        case .delay: return "Delay"
        case .swapProg: return "Swap Prog"
        case .link: return "Link"
        case .last: return "Last"
        case .next: return "Next"
        case .edit: return "Edit"
        case .undo: return "Undo"
        case .clear: return "Clear"
        case .copy: return "Copy"
        case .move: return "Move"
        case .delete: return "Delete"
        case .digit(let value): return "\(value)"
        case .dash: return "-"
        case .plus: return "+"
        case .dot: return "."
        case .enter: return "Enter"
        case .slash: return "/"
        case .backspace: return "\u{2190}"
        case .at: return "@"
        case .full: return "Full"
        case .thru: return "Thru"
        case .record: return "Record"
        case .update: return "Update"
        case .load: return "Load"
        case .group: return "Group"
        case .cue: return "Cue"
        }
    }

    /// Whether `docs/ONYX_INTEGRATION.md` §1.7 documents an OSC address for
    /// this key. `OnyxKit` should refuse to send undocumented keys; the UI
    /// should render them disabled rather than silently no-op.
    public var hasDocumentedOSCAddress: Bool {
        switch self {
        case .swapProg:
            return false // Not present anywhere in the OSC mapping PDF — TODO(verify).
        default:
            return true
        }
    }
}

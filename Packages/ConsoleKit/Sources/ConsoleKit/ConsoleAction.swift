/// The generic action vocabulary the UI is allowed to send. Screens never
/// construct OSC (or any other wire protocol) directly — they only ever
/// produce one of these, and the active `ConsoleAdapter` decides how (or
/// whether) to realize it.
public enum ConsoleAction: Sendable {
    case select(SelectionTarget)
    case setValue(ParameterID, Double)
    case record
    case update
    case clear
    case locate(fixtureIDs: [Int])
    case go(playbackID: Int)
    case release(playbackID: Int)
    case pressKey(NXKKey)
}

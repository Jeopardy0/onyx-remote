/// Snapshot-based undo/redo for local patch edits. Patch is small enough
/// (hundreds of fixtures at most) that whole-value snapshots are simpler and
/// safer than an inverse-command log, and just as correct.
public struct PatchHistory: Sendable {
    private var undoStack: [Patch] = []
    private var redoStack: [Patch] = []
    public private(set) var current: Patch

    public init(current: Patch = Patch()) {
        self.current = current
    }

    public var canUndo: Bool { !undoStack.isEmpty }
    public var canRedo: Bool { !redoStack.isEmpty }

    /// Apply an edit to `current`, recording the prior state for undo.
    public mutating func apply(_ mutate: (inout Patch) throws -> Void) rethrows {
        let before = current
        var next = current
        try mutate(&next)
        undoStack.append(before)
        redoStack.removeAll()
        current = next
    }

    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = undoStack.popLast() else { return false }
        redoStack.append(current)
        current = previous
        return true
    }

    @discardableResult
    public mutating func redo() -> Bool {
        guard let next = redoStack.popLast() else { return false }
        undoStack.append(current)
        current = next
        return true
    }
}

import Foundation

/// A settings-only insertion marker. It is never a physical menu bar item.
struct NewMenuBarItemPlacement: Codable, Equatable {
    var section: MenuBarLayoutSection = .hidden
    var beforeItem: MenuBarItemKey?
    var atEnd = false

    func insertionIndex(in items: [MenuBarItemKey]) -> Int {
        if atEnd { return items.count }
        if let beforeItem, let index = items.firstIndex(of: beforeItem) { return index }
        // A missing anchor falls back to the start of the selected section.
        return 0
    }

    mutating func move(to section: MenuBarLayoutSection, before item: MenuBarItemKey?) {
        self.section = section
        beforeItem = item
        atEnd = item == nil
    }
}

/// Persisted identities distinguish newly installed items from returning ones.
struct MenuBarItemLedger: Codable, Equatable {
    private(set) var hasBaseline = false
    private(set) var knownItems = Set<MenuBarItemKey>()

    mutating func seedIfNeeded(with items: [MenuBarItemKey]) -> Bool {
        guard !hasBaseline, !items.isEmpty else { return false }
        knownItems.formUnion(items)
        hasBaseline = true
        return true
    }

    func unseen(in items: [MenuBarItemKey]) -> [MenuBarItemKey] {
        guard hasBaseline else { return [] }
        var emitted = Set<MenuBarItemKey>()
        return items.filter { !knownItems.contains($0) && emitted.insert($0).inserted }
    }

    mutating func acknowledge(_ item: MenuBarItemKey) {
        knownItems.insert(item)
    }
}

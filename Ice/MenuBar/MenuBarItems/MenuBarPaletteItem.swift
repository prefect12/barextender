import Foundation

struct MenuBarPaletteItem: Codable, Identifiable, Equatable {
    enum Kind: String, Codable { case spacer, group }
    struct MemberOrigin: Codable, Equatable {
        var item: MenuBarItemKey
        var section: MenuBarLayoutSection
        var beforeItem: MenuBarItemKey?
    }
    var id = UUID()
    var kind: Kind
    var name: String
    var width: Double = 20
    var members: [MenuBarItemKey] = []
    var origins: [MemberOrigin] = []

    var statusAutosaveName: String { "BX-\(kind.rawValue)-\(id.uuidString)" }
    var statusWidth: Double { width.isFinite ? min(160, max(8, width)) : 20 }
}

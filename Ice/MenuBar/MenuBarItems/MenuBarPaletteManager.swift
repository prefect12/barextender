import Cocoa
import Combine

@MainActor
final class MenuBarPaletteManager: NSObject, ObservableObject {
    @Published private(set) var items: [MenuBarPaletteItem] = []
    @Published var editingItem: MenuBarPaletteItem?
    @Published private(set) var isApplying = false
    @Published private(set) var errorMessage: String?
    private weak var appState: AppState?
    private var statusItems = [UUID: NSStatusItem]()
    private var currentGroup: UUID?

    init(appState: AppState) { self.appState = appState }

    func performSetup() {
        if let data = Defaults.data(forKey: .menuBarPaletteItems) {
            do { items = try JSONDecoder().decode([MenuBarPaletteItem].self, from: data) }
            catch { errorMessage = BarextenderLocalization.string("Could not read saved spacers and groups.") }
        }
        items.forEach(registerStatusItem)
    }

    func add(_ kind: MenuBarPaletteItem.Kind) {
        let item = MenuBarPaletteItem(kind: kind, name: BarextenderLocalization.string(kind == .spacer ? "Spacer" : "Group"))
        items.append(item)
        persist()
        registerStatusItem(item)
        editingItem = item
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard let appState,
                  let live = liveItem(for: item),
                  let hidden = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true).first(where: { $0.info == .hiddenControlItem }) else { return }
            do {
                try await appState.itemManager.slowMove(item: live, to: .rightOfItem(hidden))
                await appState.itemManager.refreshItems()
            } catch { self.errorMessage = error.localizedDescription }
        }
    }

    func configuration(for info: MenuBarItemInfo) -> MenuBarPaletteItem? {
        guard info.namespace == .ice else { return nil }
        return items.first { $0.statusAutosaveName == info.title }
    }

    private func registerStatusItem(_ item: MenuBarPaletteItem) {
        let status = statusItems[item.id] ?? NSStatusBar.system.statusItem(withLength: item.statusWidth)
        status.autosaveName = item.statusAutosaveName
        status.length = item.kind == .spacer ? item.statusWidth : NSStatusItem.variableLength
        if let button = status.button {
            button.image = item.kind == .spacer ? nil : NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: item.name)
            button.image?.isTemplate = true
            button.toolTip = item.name
            button.target = self
            button.action = #selector(activatePaletteItem)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.setAccessibilityLabel(item.name)
            button.setAccessibilityIdentifier(item.statusAutosaveName)
        }
        statusItems[item.id] = status
    }

    private func liveItem(for item: MenuBarPaletteItem) -> MenuBarItem? {
        MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true).first {
            $0.info.namespace == .ice && $0.info.title == item.statusAutosaveName
        }
    }

    @objc private func activatePaletteItem(_ sender: NSStatusBarButton) {
        guard let entry = statusItems.first(where: { $0.value.button === sender }),
              let item = items.first(where: { $0.id == entry.key }) else { return }
        if item.kind == .group, NSApp.currentEvent?.type != .rightMouseUp,
           NSApp.currentEvent?.modifierFlags.contains(.control) != true {
            showGroup(id: item.id)
            return
        }
        let menu = NSMenu(title: item.name)
        let edit = NSMenuItem(title: BarextenderLocalization.string("Edit…"), action: #selector(editPaletteItem), keyEquivalent: "")
        edit.target = self
        edit.representedObject = item.id.uuidString
        menu.addItem(edit)
        let remove = NSMenuItem(title: BarextenderLocalization.string("Remove"), action: #selector(removePaletteItem), keyEquivalent: "")
        remove.target = self
        remove.representedObject = item.id.uuidString
        menu.addItem(remove)
        menu.popUp(positioning: nil, at: CGPoint(x: 0, y: sender.bounds.minY), in: sender)
    }

    func showGroup(id: UUID) {
        guard let item = items.first(where: { $0.id == id && $0.kind == .group }),
              let appState, let screen = NSScreen.screenWithMouse ?? NSScreen.main else { return }
        let panel = appState.menuBarManager.iceBarPanel
        if panel.isVisible, currentGroup == id { panel.close(); currentGroup = nil; return }
        currentGroup = id
        let infos = item.members.map { MenuBarItemInfo(namespace: .init($0.namespace), title: $0.title) }
        Task { await panel.show(section: .alwaysHidden, on: screen, itemFilter: infos) }
    }

    @objc private func editPaletteItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String,
              let item = items.first(where: { $0.id.uuidString == id }), let appState else { return }
        appState.navigationState.settingsNavigationIdentifier = .menuBarLayout
        appState.settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        editingItem = item
    }

    @objc private func removePaletteItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String, let uuid = UUID(uuidString: id) else { return }
        Task { await remove(id: uuid) }
    }

    private func moveMember(_ key: MenuBarItemKey, to section: MenuBarLayoutSection, before anchor: MenuBarItemKey? = nil) async throws {
        guard let appState else { return }
        let live = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
        guard let item = live.first(where: { MenuBarNewItemManager.key(for: $0) == key }) else { return }
        let destination: MenuBarItemManager.MoveDestination
        if let anchor, let target = live.first(where: { MenuBarNewItemManager.key(for: $0) == anchor && $0.windowID != item.windowID }) {
            destination = .leftOfItem(target)
        } else {
            let controlInfo: MenuBarItemInfo = section == .alwaysHidden ? .alwaysHiddenControlItem : .hiddenControlItem
            guard let target = live.first(where: { $0.info == controlInfo }) else { throw CocoaError(.featureUnsupported) }
            destination = section == .visible ? .rightOfItem(target) : .leftOfItem(target)
        }
        try await appState.itemManager.slowMove(item: item, to: destination)
        appState.newItemManager.acknowledgeManualPlacement(of: item)
    }

    func save(_ edited: MenuBarPaletteItem) async {
        guard !isApplying, let index = items.firstIndex(where: { $0.id == edited.id }), let appState else { return }
        isApplying = true
        defer { isApplying = false }
        var staged = edited
        staged.name = staged.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !staged.name.isEmpty else { errorMessage = BarextenderLocalization.string("Enter a name."); return }
        staged.origins = items[index].origins
        if staged.kind == .group {
            if items.contains(where: { $0.id != staged.id && $0.kind == .group && !$0.members.filter(staged.members.contains).isEmpty }) {
                errorMessage = BarextenderLocalization.string("A menu bar item can belong to only one group.")
                return
            }
            for key in staged.members where !staged.origins.contains(where: { $0.item == key }) {
                let cache = appState.itemManager.itemCache
                guard let live = cache.allItems.first(where: { MenuBarNewItemManager.key(for: $0) == key }), let section = cache.section(for: live) else { continue }
                let siblings = cache.managedItems(for: section)
                let next = siblings.firstIndex(of: live).flatMap { siblings.indices.contains($0 + 1) ? MenuBarNewItemManager.key(for: siblings[$0 + 1]) : nil }
                staged.origins.append(.init(item: key, section: MenuBarNewItemManager.modelSection(section), beforeItem: next))
            }
            // Save recovery destinations before beginning native movement.
            items[index].origins = staged.origins
            persist()
            do {
                for origin in staged.origins.reversed() where !staged.members.contains(origin.item) {
                    try await moveMember(origin.item, to: origin.section, before: origin.beforeItem)
                }
                for key in staged.members { try await moveMember(key, to: .alwaysHidden) }
                staged.origins.removeAll { !staged.members.contains($0.item) }
            } catch { errorMessage = error.localizedDescription; await appState.itemManager.refreshItems(); return }
        }
        items[index] = staged
        persist()
        registerStatusItem(staged)
        errorMessage = nil
        editingItem = nil
        await appState.itemManager.refreshItems()
    }

    func remove(id: UUID) async {
        guard !isApplying, let item = items.first(where: { $0.id == id }) else { return }
        isApplying = true
        defer { isApplying = false }
        do {
            for origin in item.origins.reversed() { try await moveMember(origin.item, to: origin.section, before: origin.beforeItem) }
        } catch { errorMessage = error.localizedDescription; return }
        if let status = statusItems.removeValue(forKey: id) { NSStatusBar.system.removeStatusItem(status) }
        items.removeAll { $0.id == id }
        if editingItem?.id == id { editingItem = nil }
        if currentGroup == id { appState?.menuBarManager.iceBarPanel.close(); currentGroup = nil }
        persist()
        await appState?.itemManager.refreshItems()
    }

    private func persist() {
        do { Defaults.set(try JSONEncoder().encode(items), forKey: .menuBarPaletteItems) }
        catch { errorMessage = BarextenderLocalization.string("Could not save spacers and groups.") }
    }
}

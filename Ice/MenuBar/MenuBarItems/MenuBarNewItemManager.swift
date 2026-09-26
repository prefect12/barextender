import Cocoa
import Combine

@MainActor
final class MenuBarNewItemManager: ObservableObject {
    @Published private(set) var placement = NewMenuBarItemPlacement()
    @Published private(set) var errorMessage: String?
    private weak var appState: AppState?
    private var ledger = MenuBarItemLedger()
    private var cancellables = Set<AnyCancellable>()
    private var isPlacing = false
    private var attempts = [MenuBarItemKey: Int]()

    init(appState: AppState) { self.appState = appState }

    func performSetup() {
        if let data = Defaults.data(forKey: .newMenuBarItemPlacement) {
            do { placement = try JSONDecoder().decode(NewMenuBarItemPlacement.self, from: data) }
            catch { Logger.newItems.error("Could not decode insertion position: \(error)") }
        }
        if let data = Defaults.data(forKey: .menuBarItemLedger) {
            do { ledger = try JSONDecoder().decode(MenuBarItemLedger.self, from: data) }
            catch { Logger.newItems.error("Could not decode known item identities: \(error)") }
        }
        guard let appState else { return }
        appState.itemManager.$itemCache
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.placeNewItemsIfNeeded() }
            }
            .store(in: &cancellables)
        Timer.publish(every: 5, on: .main, in: .default).autoconnect()
            .sink { [weak self] _ in
                Task { await self?.placeNewItemsIfNeeded() }
            }
            .store(in: &cancellables)
    }

    static func key(for item: MenuBarItem) -> MenuBarItemKey {
        MenuBarItemKey(namespace: item.info.namespace.rawValue, title: item.info.title)
    }

    static func modelSection(_ name: MenuBarSection.Name) -> MenuBarLayoutSection {
        switch name { case .visible: .visible; case .hidden: .hidden; case .alwaysHidden: .alwaysHidden }
    }

    private var sectionName: MenuBarSection.Name {
        switch placement.section { case .visible: .visible; case .hidden: .hidden; case .alwaysHidden: .alwaysHidden }
    }

    func setPlacement(in section: MenuBarSection.Name, before item: MenuBarItem?) {
        var updated = placement
        updated.move(to: Self.modelSection(section), before: item.map(Self.key(for:)))
        do {
            let data = try JSONEncoder().encode(updated)
            Defaults.set(data, forKey: .newMenuBarItemPlacement)
            placement = updated
        } catch {
            errorMessage = BarextenderLocalization.string("Could not save the new menu bar item position.")
        }
    }

    /// The virtual marker borrows window metadata solely for the layout view.
    /// It is intercepted by the layout drag handler and can never reach slowMove.
    func layoutItems(_ items: [MenuBarItem], in section: MenuBarSection.Name) -> [MenuBarItem] {
        guard Self.modelSection(section) == placement.section,
              let windowID = appState?.menuBarManager.section(withName: .hidden)?.controlItem.window?.windowNumber,
              let window = WindowInfo(windowID: CGWindowID(windowID)) else { return items }
        var result = items
        let index = placement.insertionIndex(in: items.map(Self.key(for:)))
        result.insert(MenuBarItem(layoutMarkerWindow: window), at: index)
        return result
    }

    private func persistLedger() {
        do { Defaults.set(try JSONEncoder().encode(ledger), forKey: .menuBarItemLedger) }
        catch { Logger.newItems.error("Could not save known item identities: \(error)") }
    }

    /// A deliberate settings drag takes precedence over the automatic rule.
    func acknowledgeManualPlacement(of item: MenuBarItem) {
        guard !item.info.isSpecial else { return }
        ledger.acknowledge(Self.key(for: item))
        attempts[Self.key(for: item)] = nil
        persistLedger()
    }

    private func placeNewItemsIfNeeded() async {
        guard !isPlacing, let appState,
              appState.permissionsManager.accessibilityPermission.hasPermission,
              !appState.paletteManager.isApplying,
              !appState.itemManager.isMovingItem,
              !appState.itemManager.mouseHasRecentlyMoved else { return }
        let eligible = appState.itemManager.itemCache.managedItems.filter {
            $0.isMovable && $0.canBeHidden && !$0.info.isSpecial && $0.owningApplication != .current
        }
        let keys = eligible.map(Self.key(for:))
        if ledger.seedIfNeeded(with: keys) { persistLedger(); return }
        let unseen = ledger.unseen(in: keys)
        guard !unseen.isEmpty else { return }
        isPlacing = true
        defer { isPlacing = false }
        for key in unseen where attempts[key, default: 0] < 3 {
            // Refresh window frames between moves; the previous item may have shifted them.
            let live = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
            guard let item = live.first(where: { Self.key(for: $0) == key }),
                  let hidden = live.first(where: { $0.info == .hiddenControlItem }) else { continue }
            let always = live.first(where: { $0.info == .alwaysHiddenControlItem })
            let members = live.filter { candidate in
                guard candidate.info != .hiddenControlItem, candidate.info != .alwaysHiddenControlItem,
                      Self.key(for: candidate) != key else { return false }
                switch sectionName {
                case .visible: return candidate.frame.minX >= hidden.frame.maxX
                case .hidden: return candidate.frame.maxX <= hidden.frame.minX && (always.map { candidate.frame.minX >= $0.frame.maxX } ?? true)
                case .alwaysHidden: return always.map { candidate.frame.maxX <= $0.frame.minX } ?? false
                }
            }
            let index = placement.insertionIndex(in: members.map(Self.key(for:)))
            let destination: MenuBarItemManager.MoveDestination
            if index < members.count {
                destination = .leftOfItem(members[index])
            } else {
                switch sectionName {
                case .visible: destination = members.last.map { .rightOfItem($0) } ?? .rightOfItem(hidden)
                case .hidden: destination = .leftOfItem(hidden)
                case .alwaysHidden:
                    guard let always else { continue }
                    destination = .leftOfItem(always)
                }
            }
            attempts[key, default: 0] += 1
            do {
                try await appState.itemManager.slowMove(item: item, to: destination)
                ledger.acknowledge(key)
                persistLedger()
                errorMessage = nil
                Logger.newItems.info("Placed new item in \(self.sectionName.logString)")
            } catch {
                Logger.newItems.error("Failed to place a new item (attempt \(self.attempts[key, default: 0])): \(error)")
                errorMessage = BarextenderLocalization.string("Could not move a new menu bar item. Check Accessibility permission and try dragging it manually.")
            }
        }
        await appState.itemManager.refreshItems()
    }
}

private extension Logger {
    static let newItems = Logger(category: "NewMenuBarItems")
}

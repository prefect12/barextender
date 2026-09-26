import SwiftUI

struct MenuBarPaletteView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var manager: MenuBarPaletteManager

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Menu bar items palette").font(.system(size: 14))
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 30) {
                    Button("Add a Spacer") { manager.add(.spacer) }.tint(.green)
                    Button("Add a menu bar item group") { manager.add(.group) }.tint(.teal)
                }
                .buttonStyle(.borderedProminent)
                .disabled(manager.isApplying)
                if !manager.items.isEmpty {
                    ForEach(manager.items) { item in
                        HStack {
                            Image(systemName: item.kind == .spacer ? "arrow.left.and.right" : "square.stack.3d.up")
                            if item.kind == .group {
                                Button(item.name) { manager.showGroup(id: item.id) }.buttonStyle(.plain)
                            } else {
                                Text(item.name)
                            }
                            Spacer()
                            Button("Edit…") { manager.editingItem = item }
                            Button("Remove") { Task { await manager.remove(id: item.id) } }
                        }
                        .disabled(manager.isApplying)
                    }
                }
                if let error = manager.errorMessage {
                    Text(error).font(.callout).foregroundStyle(.orange)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
            .layoutBarStyle(appState: appState, averageColorInfo: appState.menuBarManager.averageColorInfo)
            .clipShape(RoundedRectangle(cornerRadius: 9))
        }
        .sheet(item: $manager.editingItem) { item in
            MenuBarPaletteEditor(manager: manager, item: item)
                .environmentObject(appState)
                .environment(\.locale, BarextenderLocalization.locale)
        }
    }
}

private struct MenuBarPaletteEditor: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var manager: MenuBarPaletteManager
    @State private var draft: MenuBarPaletteItem

    init(manager: MenuBarPaletteManager, item: MenuBarPaletteItem) {
        self.manager = manager
        _draft = State(initialValue: item)
    }

    private var candidates: [MenuBarItem] {
        appState.itemManager.itemCache.managedItems.filter {
            $0.isMovable && $0.canBeHidden && $0.owningApplication != .current
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey(draft.kind == .spacer ? "Edit Spacer" : "Edit Menu Bar Item Group")).font(.title2)
            TextField("Name", text: $draft.name)
            if draft.kind == .spacer {
                HStack {
                    Text("Spacer width")
                    Slider(value: $draft.width, in: 8...160, step: 2)
                    Text("\(Int(draft.statusWidth)) pt").monospacedDigit().frame(width: 55)
                }
            } else {
                Text("Group members").font(.headline)
                Text("Members are kept in Always Hidden and shown when you click this group.")
                    .font(.callout).foregroundStyle(.secondary)
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(candidates, id: \.windowID) { item in
                            let key = MenuBarNewItemManager.key(for: item)
                            Toggle(item.displayName, isOn: Binding(
                                get: { draft.members.contains(key) },
                                set: { enabled in
                                    draft.members.removeAll { $0 == key }
                                    if enabled { draft.members.append(key) }
                                }
                            ))
                            .disabled(manager.items.contains { $0.id != draft.id && $0.kind == .group && $0.members.contains(key) })
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 220)
            }
            if let error = manager.errorMessage {
                Text(error).foregroundStyle(.orange).font(.callout)
            }
            HStack {
                Spacer()
                Button("Cancel") { manager.editingItem = nil }.keyboardShortcut(.cancelAction)
                Button("Save") { Task { await manager.save(draft) } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 460)
        .disabled(manager.isApplying)
    }
}

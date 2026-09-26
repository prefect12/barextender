//
//  MenuBarLayoutSettingsPane.swift
//  Ice
//

import SwiftUI

struct MenuBarLayoutSettingsPane: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if !appState.permissionsManager.accessibilityPermission.hasPermission {
            missingAccessibilityPermission
        } else if !ScreenCapture.cachedCheckPermissions() {
            missingScreenRecordingPermission
        } else if appState.menuBarManager.isMenuBarHiddenBySystemUserDefaults {
            cannotArrange
        } else {
            IceForm(alignment: .leading, spacing: 20) {
                header
                layoutBars
                MenuBarPaletteView(manager: appState.paletteManager)
                NewMenuBarItemStatus(manager: appState.newItemManager)
            }
            .onAppear {
                // The three-section layout is part of this app's standard interface.
                appState.settingsManager.advancedSettingsManager.enableAlwaysHiddenSection = true
                Task { await appState.itemManager.refreshItems() }
            }
        }
    }

    @ViewBuilder
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Drag menu bar item icons between the sections below to arrange them as you want")
            Text("You can also arrange the menu bar items quickly by Command + dragging them in the menu bar")
                .foregroundStyle(.secondary)
        }
        .font(.system(size: 14))
    }

    @ViewBuilder
    private var layoutBars: some View {
        VStack(spacing: 25) {
            ForEach(MenuBarSection.Name.allCases, id: \.self) { section in
                layoutBar(for: section)
            }
        }
    }

    @ViewBuilder
    private var cannotArrange: some View {
        Text("Barextender cannot arrange menu bar items in automatically hidden menu bars")
            .font(.title3)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    @ViewBuilder
    private var missingScreenRecordingPermission: some View {
        VStack {
            Text("Menu bar layout requires screen recording permissions")
                .font(.title2)

            Button {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            } label: {
                Text("Go to Advanced Settings")
            }
            .buttonStyle(.link)
        }
    }

    @ViewBuilder
    private var missingAccessibilityPermission: some View {
        VStack {
            Text("Menu bar layout requires Accessibility permission")
                .font(.title2)

            Button {
                appState.navigationState.settingsNavigationIdentifier = .advanced
            } label: {
                Text("Go to Advanced Settings")
            }
            .buttonStyle(.link)
        }
    }

    @ViewBuilder
    private func layoutBar(for section: MenuBarSection.Name) -> some View {
        if
            let section = appState.menuBarManager.section(withName: section)
        {
            VStack(alignment: .leading, spacing: 4) {
                Text(sectionTitle(section.name))
                    .font(.system(size: 14))
                    .padding(.leading, 2)

                LayoutBar(section: section)
                    .environmentObject(appState.imageCache)
            }
        }
    }

    private func sectionTitle(_ name: MenuBarSection.Name) -> LocalizedStringKey {
        switch name {
        case .visible: "Shown menu bar items"
        case .hidden: "Hidden menu bar items"
        case .alwaysHidden: "Always Hidden menu bar items"
        }
    }
}

private struct NewMenuBarItemStatus: View {
    @ObservedObject var manager: MenuBarNewItemManager
    var body: some View {
        if let message = manager.errorMessage {
            Text(message).font(.callout).foregroundStyle(.orange)
        }
    }
}

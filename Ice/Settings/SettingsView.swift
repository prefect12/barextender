//
//  SettingsView.swift
//  Ice
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var navigationState: AppNavigationState

    private let sidebarWidth: CGFloat = 240
    private let sidebarItemHeight: CGFloat = 31
    private let sidebarItemFontSize: CGFloat = 13

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle(BarextenderLocalization.string(navigationState.settingsNavigationIdentifier.rawValue))
    }

    @ViewBuilder
    private var sidebar: some View {
        List(selection: $navigationState.settingsNavigationIdentifier) {
            Section {
                ForEach(SettingsNavigationIdentifier.allCases, id: \.self) { identifier in
                    sidebarItem(for: identifier)
                }
            } header: {
                Text("Barextender")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .collapsible(false)
        }
        .scrollDisabled(true)
        .removeSidebarToggle()
        .navigationSplitViewColumnWidth(min: sidebarWidth, ideal: sidebarWidth, max: sidebarWidth)
    }

    @ViewBuilder
    private var detailView: some View {
        Group {
            switch navigationState.settingsNavigationIdentifier {
            case .general:
                GeneralSettingsPane()
            case .menuBarLayout:
                MenuBarLayoutSettingsPane()
            case .menuBarAppearance:
                MenuBarAppearanceSettingsPane()
            case .advanced:
                AdvancedSettingsPane()
            case .about:
                AboutSettingsPane()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if appState.isLimitedMode {
                Label {
                    Text("Limited mode: grant Accessibility to discover and arrange menu bar items.")
                        .font(.callout)
                } icon: {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(.quaternary)
            }
        }
    }

    @ViewBuilder
    private func sidebarItem(for identifier: SettingsNavigationIdentifier) -> some View {
        Label {
            Text(identifier.localized)
                .font(.system(size: sidebarItemFontSize))
                .padding(.leading, 2)
        } icon: {
            icon(for: identifier).view
        }
        .frame(height: sidebarItemHeight)
    }

    private func icon(for identifier: SettingsNavigationIdentifier) -> IconResource {
        switch identifier {
        case .general: .systemSymbol("gearshape")
        case .menuBarLayout: .systemSymbol("rectangle.topthird.inset.filled")
        case .menuBarAppearance: .systemSymbol("swatchpalette")
        case .advanced: .systemSymbol("gearshape.2")
        case .about: .systemSymbol("info.circle")
        }
    }
}

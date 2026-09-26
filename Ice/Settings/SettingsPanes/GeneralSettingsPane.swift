//
//  GeneralSettingsPane.swift
//  Ice
//

import LaunchAtLogin
import SwiftUI

struct GeneralSettingsPane: View {
    @EnvironmentObject var appState: AppState
    @State private var isImportingCustomIceIcon = false
    @State private var isPresentingError = false
    @State private var presentedError: LocalizedErrorWrapper?
    @State private var isApplyingOffset = false
    @State private var isConfirmingSpacingApply = false
    @State private var tempItemSpacingOffset: CGFloat = 0 // Temporary state for the slider

    private var manager: GeneralSettingsManager {
        appState.settingsManager.generalSettingsManager
    }

    private var itemSpacingOffset: LocalizedStringKey {
        localizedOffsetString(for: manager.itemSpacingOffset)
    }

    private func localizedOffsetString(for offset: CGFloat) -> LocalizedStringKey {
        switch offset {
        case -16:
            return LocalizedStringKey("none")
        case 0:
            return LocalizedStringKey("default")
        case 16:
            return LocalizedStringKey("max")
        default:
            return LocalizedStringKey(offset.formatted())
        }
    }

    private var rehideIntervalKey: LocalizedStringKey {
        let formatted = manager.rehideInterval.formatted()
        if manager.rehideInterval == 1 {
            return LocalizedStringKey(formatted + " 秒")
        } else {
            return LocalizedStringKey(formatted + " 秒")
        }
    }

    private var hasSpacingSliderValueChanged: Bool {
        tempItemSpacingOffset != manager.itemSpacingOffset
    }

    private var isActualOffsetDifferentFromDefault: Bool {
        manager.itemSpacingOffset != 0
    }

    var body: some View {
        IceForm(alignment: .leading, spacing: 14) {
            IceSection {
                launchAtLogin
            }
            IceSection("Show hidden menu bar items when:") {
                showOnClick
                showOnScroll
                showOnHover
                hoverDelay
            }
            IceSection {
                autoRehideOptions
            }
            IceSection("Barextender Bar — show hidden items below the menu bar") {
                iceBarOptions
            }
            IceSection("Barextender menu bar item") {
                iceIconOptions
                Toggle("Show divider between shown and hidden sections", isOn: appState.settingsManager.advancedSettingsManager.bindings.showSectionDividers)
            }
            IceSection {
                spacingOptions
            }
            IceSection("Screens") {
                Toggle("Show all menu bar items when active screen is bigger than", isOn: manager.bindings.showAllOnWideScreen)
                VStack(alignment: .leading, spacing: 8) {
                    Text("↓ \(BarextenderLocalization.string(appState.menuBarManager.activeScreenName))")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))
                    HStack(spacing: 12) {
                        Slider(value: manager.bindings.showAllScreenWidthThreshold, in: 1_000...8_000, step: 100)
                            .accessibilityLabel(BarextenderLocalization.string("Screen width threshold"))
                        Text(BarextenderLocalization.format("%d pixels wide", Int(manager.showAllScreenWidthThreshold)))
                            .monospacedDigit().frame(width: 108, alignment: .trailing)
                    }
                    .disabled(!manager.showAllOnWideScreen)
                    Text(BarextenderLocalization.format("Current active screen: %d pixels wide", appState.menuBarManager.activeScreenPixelWidth))
                        .foregroundStyle(.secondary).font(.system(size: 11))
                }
            }
        }
        .alert(isPresented: $isPresentingError, error: presentedError) {
            Button("OK") {
                presentedError = nil
                isPresentingError = false
            }
        }
    }

    @ViewBuilder
    private var launchAtLogin: some View {
        LaunchAtLogin.Toggle(BarextenderLocalization.string("Launch at login"))
    }

    @ViewBuilder
    private func menuItem(for imageSet: ControlItemImageSet) -> some View {
        Label {
            Text(imageSet.name.localized)
        } icon: {
            if let nsImage = imageSet.hidden.nsImage(for: appState) {
                switch imageSet.name {
                case .custom:
                    Image(size: CGSize(width: 18, height: 18)) { context in
                        context.draw(
                            Image(nsImage: nsImage),
                            in: context.clipBoundingRect
                        )
                    }
                default:
                    Image(nsImage: nsImage)
                }
            }
        }
    }

    @ViewBuilder
    private var iceIconOptions: some View {
        Toggle("Show Barextender icon", isOn: manager.bindings.showIceIcon)
            .annotation {
                if !manager.showIceIcon {
                    Text("You can still access Barextender settings by right-clicking an empty area in the menu bar")
                }
            }
        if manager.showIceIcon {
            IceMenu("Barextender icon") {
                Picker("Barextender icon", selection: manager.bindings.iceIcon) {
                    ForEach(ControlItemImageSet.userSelectableIceIcons) { imageSet in
                        Button {
                            manager.iceIcon = imageSet
                        } label: {
                            menuItem(for: imageSet)
                        }
                        .tag(imageSet)
                    }
                    if let lastCustomIceIcon = manager.lastCustomIceIcon {
                        Button {
                            manager.iceIcon = lastCustomIceIcon
                        } label: {
                            menuItem(for: lastCustomIceIcon)
                        }
                        .tag(lastCustomIceIcon)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()

                Divider()

                Button("Choose image…") {
                    isImportingCustomIceIcon = true
                }
            } title: {
                menuItem(for: manager.iceIcon)
            }
            .fileImporter(
                isPresented: $isImportingCustomIceIcon,
                allowedContentTypes: [.image]
            ) { result in
                do {
                    let url = try result.get()
                    if url.startAccessingSecurityScopedResource() {
                        defer { url.stopAccessingSecurityScopedResource() }
                        let data = try Data(contentsOf: url)
                        manager.iceIcon = ControlItemImageSet(name: .custom, image: .data(data))
                    }
                } catch {
                    presentedError = LocalizedErrorWrapper(error)
                    isPresentingError = true
                }
            }

            if case .custom = manager.iceIcon.name {
                Toggle("Apply system theme to icon", isOn: manager.bindings.customIceIconIsTemplate)
                    .annotation("Display the icon as a monochrome image matching the system appearance")
            }
        }
    }

    @ViewBuilder
    private var iceBarOptions: some View {
        useIceBar
        if manager.useIceBar {
            Toggle("Only on screens with a notch", isOn: manager.bindings.useIceBarOnlyOnNotchedScreens)
        }
    }

    @ViewBuilder
    private var useIceBar: some View {
        Toggle("Show menu bar items in a bar below the menu bar", isOn: manager.bindings.useIceBar)
    }

    @ViewBuilder
    private var iceBarLocationPicker: some View {
        IcePicker("Location", selection: manager.bindings.iceBarLocation) {
            ForEach(IceBarLocation.allCases) { location in
                Text(location.localized).tag(location)
            }
        }
        .annotation {
            switch manager.iceBarLocation {
            case .dynamic:
                Text("The Barextender Bar's location changes based on context")
            case .mousePointer:
                Text("The Barextender Bar is centered below the mouse pointer")
            case .iceIcon:
                Text("The Barextender Bar is centered below the Barextender icon")
            }
        }
    }

    @ViewBuilder
    private var showOnClick: some View {
        Toggle("Click on empty menu bar space", isOn: manager.bindings.showOnClick)
    }

    @ViewBuilder
    private var showOnHover: some View {
        Toggle("Hover over empty menu bar space", isOn: manager.bindings.showOnHover)
    }

    @ViewBuilder
    private var showOnScroll: some View {
        Toggle("Swipe or scroll in menu bar", isOn: manager.bindings.showOnScroll)
    }

    private var hoverDelay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Delay before showing on hover")
            HStack(spacing: 12) {
                Slider(value: appState.settingsManager.advancedSettingsManager.bindings.showOnHoverDelay, in: 0...1, step: 0.1)
                    .accessibilityLabel(BarextenderLocalization.string("Delay before showing on hover"))
                Text(BarextenderLocalization.format("%.1f seconds", appState.settingsManager.advancedSettingsManager.showOnHoverDelay))
                    .monospacedDigit()
                    .frame(width: 62, alignment: .trailing)
            }
        }
    }

    @ViewBuilder
    private var spacingOptions: some View {
        IceLabeledContent("Menu bar item spacing") {
            HStack(spacing: 8) {
                Picker("Menu bar item spacing", selection: $tempItemSpacingOffset) {
                    Text("No Spacing").tag(CGFloat(-16))
                    Text("Small Spacing").tag(CGFloat(-8))
                    Text("Default Spacing").tag(CGFloat(0))
                    Text("Large Spacing").tag(CGFloat(8))
                    Text("Maximum Spacing").tag(CGFloat(16))
                }
                .labelsHidden()
                .frame(width: 180)
                .disabled(isApplyingOffset)
                if hasSpacingSliderValueChanged {
                    Button("Apply") { isConfirmingSpacingApply = true }
                        .disabled(isApplyingOffset)
                }
                if isApplyingOffset { ProgressView().controlSize(.small) }
            }
        }
        .onAppear { tempItemSpacingOffset = manager.itemSpacingOffset }
        .confirmationDialog("Apply menu bar item spacing?", isPresented: $isConfirmingSpacingApply, titleVisibility: .visible) {
            Button("Apply and restart menu bar apps") { applyOffset() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This changes spacing for all menu bar apps and restarts them. Apps with unsaved work will not be forced to quit.")
        }
    }

    @ViewBuilder
    private var rehideStrategyPicker: some View {
        IcePicker("Strategy", selection: manager.bindings.rehideStrategy) {
            ForEach(RehideStrategy.allCases) { strategy in
                Text(strategy.localized).tag(strategy)
            }
        }
        .annotation {
            switch manager.rehideStrategy {
            case .smart:
                Text("Menu bar items are rehidden using a smart algorithm")
            case .timed:
                Text("Menu bar items are rehidden after a fixed amount of time")
            case .focusedApp:
                Text("Menu bar items are rehidden when the focused app changes")
            }
        }
    }

    @ViewBuilder
    private var autoRehideOptions: some View {
        Toggle("Automatically rehide", isOn: manager.bindings.autoRehide)
    }

    /// Apply menu bar spacing offset.
    private func applyOffset() {
        isApplyingOffset = true
        manager.itemSpacingOffset = tempItemSpacingOffset
        Task {
            do {
                try await appState.spacingManager.applyOffset()
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
            isApplyingOffset = false
        }
    }

    /// Reset menu bar spacing offset to default.
    private func resetOffsetToDefault() {
        tempItemSpacingOffset = 0
        manager.itemSpacingOffset = tempItemSpacingOffset
        applyOffset()
    }
}

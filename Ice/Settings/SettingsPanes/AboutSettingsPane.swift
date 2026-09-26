//
//  AboutSettingsPane.swift
//  Barextender
//

import SwiftUI

struct AboutSettingsPane: View {
    @Environment(\.openURL) private var openURL

    private var acknowledgementsURL: URL {
        // swiftlint:disable:next force_unwrapping
        Bundle.main.url(forResource: "Acknowledgements", withExtension: "pdf")!
    }

    private var upstreamURL: URL {
        // swiftlint:disable:next force_unwrapping
        URL(string: "https://github.com/jordanbaird/Ice")!
    }

    var body: some View {
        VStack(spacing: 0) {
            mainForm
            Spacer(minLength: 20)
            bottomBar
        }
        .padding(30)
    }

    @ViewBuilder
    private var mainForm: some View {
        IceForm(padding: EdgeInsets(top: 5, leading: 30, bottom: 30, trailing: 30), spacing: 0) {
            appIdentitySection
                .layoutPriority(1)

            Spacer(minLength: 0)
                .frame(maxHeight: 20)

            licensingSection
                .layoutPriority(1)

            updatesSection
                .layoutPriority(1)
        }
        .scrollDisabled(true)
        .frame(maxHeight: 500)
        .background(.quinary, in: RoundedRectangle(cornerRadius: 20, style: .circular))
    }

    @ViewBuilder
    private var appIdentitySection: some View {
        IceSection(options: .plain) {
            HStack(spacing: 18) {
                if let nsImage = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 132)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Barextender")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text("Version \(Constants.versionString)")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)

                    Text(Constants.copyrightString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    @ViewBuilder
    private var licensingSection: some View {
        IceSection("Open-Source Credits") {
            Text("Barextender is based on Ice by Jordan Baird and is distributed under GPL-3.0.")
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("View Ice source project") {
                openURL(upstreamURL)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var updatesSection: some View {
        IceSection("Software Updates") {
            Label("Updates are not configured for this local build", systemImage: "info.circle")
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("A Barextender release feed must be configured before automatic updates can be enabled.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        HStack {
            Button("Quit Barextender") {
                NSApp.terminate(nil)
            }
            Spacer()
            Button("Acknowledgements") {
                NSWorkspace.shared.open(acknowledgementsURL)
            }
        }
        .padding(8)
        .buttonStyle(BottomBarButtonStyle())
        .background(.quinary, in: Capsule(style: .circular))
        .frame(height: 40)
    }
}

private struct BottomBarButtonStyle: ButtonStyle {
    @State private var isHovering = false

    private var borderShape: some InsettableShape {
        Capsule(style: .circular)
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background {
                borderShape
                    .fill(configuration.isPressed ? .tertiary : .quaternary)
                    .opacity(isHovering ? 1 : 0)
            }
            .contentShape([.focusEffect, .interaction], borderShape)
            .onHover { hovering in
                isHovering = hovering
            }
    }
}

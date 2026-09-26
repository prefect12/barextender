//
//  MenuBarActivation.swift
//  Barextender
//

import CoreGraphics

/// Shared action selection for mouse, keyboard and accessibility activation.
enum MenuBarActivation: Equatable {
    case toggleSection
    case toggleAlwaysHidden
    case contextMenu

    static func resolve(
        rightClick: Bool,
        controlModifier: Bool,
        optionModifier: Bool,
        canToggleAlwaysHidden: Bool
    ) -> Self {
        if rightClick || controlModifier {
            return .contextMenu
        }
        if optionModifier && canToggleAlwaysHidden {
            return .toggleAlwaysHidden
        }
        return .toggleSection
    }
}

/// Prevents an asynchronous toolbar request from reopening a closed or newer panel.
struct MenuBarPresentationRequest {
    private var generation: UInt64 = 0

    mutating func begin() -> UInt64 {
        generation &+= 1
        return generation
    }

    mutating func cancel() {
        generation &+= 1
    }

    func isCurrent(_ request: UInt64) -> Bool {
        request == generation
    }
}

enum MenuBarToolbarPolicy {
    static func shouldUseToolbar(enabled: Bool, onlyOnNotchedScreens: Bool, screenHasNotch: Bool) -> Bool {
        enabled && (!onlyOnNotchedScreens || screenHasNotch)
    }
}

enum MenuBarControlPlacement {
    static func needsRecovery(iconFrame: CGRect, menuBarFrames: [CGRect], notchFrames: [CGRect]) -> Bool {
        guard iconFrame.width > 0, iconFrame.height > 0, !menuBarFrames.isEmpty else {
            return false
        }
        let center = CGPoint(x: iconFrame.midX, y: iconFrame.midY)
        return !menuBarFrames.contains { $0.contains(center) } || notchFrames.contains { $0.contains(center) }
    }
}

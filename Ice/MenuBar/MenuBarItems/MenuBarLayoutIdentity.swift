//
//  MenuBarLayoutIdentity.swift
//  Barextender
//

import Foundation

enum MenuBarLayoutSection: String, Codable, CaseIterable, Hashable {
    case visible
    case hidden
    case alwaysHidden

    var displayName: String {
        switch self {
        case .visible: "Shown"
        case .hidden: "Hidden"
        case .alwaysHidden: "Always Hidden"
        }
    }
}

struct MenuBarItemKey: Codable, Hashable {
    var namespace: String
    var title: String

    var stableIdentifier: String {
        "\(namespace):\(title)"
    }
}

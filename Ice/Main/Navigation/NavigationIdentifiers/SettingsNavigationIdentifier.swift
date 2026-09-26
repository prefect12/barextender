//
//  SettingsNavigationIdentifier.swift
//  Ice
//

/// An identifier used for navigation in the settings interface.
enum SettingsNavigationIdentifier: String, NavigationIdentifier {
    case general = "General"
    case menuBarLayout = "Menu Bar Items"
    case menuBarAppearance = "Menu Bar Style"
    case advanced = "Advanced"
    case about = "About"
}

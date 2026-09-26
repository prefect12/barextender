import Cocoa
import Darwin

/// Read the actual active menu bar display, independent of this app's settings window.
/// SkyLight is already used by Ice; resolve this optional reader at runtime so an
/// unavailable symbol leaves the app usable with AppKit's main-screen fallback.
enum ActiveMenuBarDisplay {
    private typealias CopyIdentifier = @convention(c) (UInt32) -> Unmanaged<CFString>?
    private static let copyIdentifier: CopyIdentifier? = {
        guard let symbol = dlsym(UnsafeMutableRawPointer(bitPattern: -2), "SLSCopyActiveMenuBarDisplayIdentifier") else { return nil }
        return unsafeBitCast(symbol, to: CopyIdentifier.self)
    }()

    static var screen: NSScreen? {
        if let uuid = copyIdentifier?(UInt32(CGSMainConnectionID()))?.takeRetainedValue() {
            let identifier = uuid as String
            if let screen = NSScreen.screens.first(where: { screen in
                guard let displayUUID = CGDisplayCreateUUIDFromDisplayID(screen.displayID)?.takeRetainedValue() else { return false }
                return (CFUUIDCreateString(nil, displayUUID) as String) == identifier
            }) { return screen }
        }
        return NSScreen.main ?? NSScreen.screens.first
    }

    static func pixelWidth(of screen: NSScreen) -> Int {
        CGDisplayCopyDisplayMode(screen.displayID)?.pixelWidth ?? Int(CGDisplayPixelsWide(screen.displayID))
    }
}

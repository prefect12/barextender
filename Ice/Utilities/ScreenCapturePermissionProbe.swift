enum ScreenCapturePermissionProbe {
    static func isGranted(preflight: Bool, externalMenuBarItemTitles: [String?]) -> Bool {
        preflight || externalMenuBarItemTitles.contains { $0?.isEmpty == false }
    }
}

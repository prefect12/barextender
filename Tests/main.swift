import Foundation
import CoreGraphics

private func verifyScreenRules() {
    expect(!MenuBarScreenRule.shouldShowAll(enabled: false, pixelWidth: 7_000, threshold: 3_000), "disabled wide-screen rule must not reveal items")
    expect(MenuBarScreenRule.shouldShowAll(enabled: true, pixelWidth: 3_001, threshold: 3_000), "pixel width above the threshold must reveal items")
    expect(!MenuBarScreenRule.shouldShowAll(enabled: true, pixelWidth: 3_000, threshold: 3_000), "equal width is not bigger than the threshold")
    expect(!MenuBarScreenRule.shouldShowAll(enabled: true, pixelWidth: 2_999, threshold: 3_000), "width below the threshold must not reveal items")
    expect(!MenuBarScreenRule.shouldShowAll(enabled: true, pixelWidth: 0, threshold: 3_000), "missing display data must not reveal items")
    expect(!MenuBarScreenRule.shouldShowAll(enabled: true, pixelWidth: -1, threshold: 3_000), "invalid width must not reveal items")
    expect(MenuBarScreenRule.threshold(.nan) == 3_000, "NaN threshold must restore a valid default")
    expect(MenuBarScreenRule.threshold(.infinity) == 3_000, "infinite threshold must restore a valid default")
    expect(MenuBarScreenRule.threshold(900) == 1_000, "threshold must respect slider minimum")
    expect(MenuBarScreenRule.threshold(9_000) == 8_000, "threshold must respect slider maximum")
    print("PASS: 10 active-screen pixel threshold assertions")
}

private func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError("FAIL: \(message)")
    }
}

verifyScreenRules()

let mail = MenuBarItemKey(namespace: "com.example.mail", title: "Mail")
let calendar = MenuBarItemKey(namespace: "com.example.calendar", title: "Calendar")
let battery = MenuBarItemKey(namespace: "com.apple.controlcenter", title: "Battery")

expect(
    ScreenCapturePermissionProbe.isGranted(preflight: false, externalMenuBarItemTitles: [nil, "Wi-Fi"]),
    "an untitled first menu bar item should not hide permission evidence from later items"
)
expect(
    ScreenCapturePermissionProbe.isGranted(preflight: true, externalMenuBarItemTitles: [nil]),
    "Core Graphics preflight should report an explicit screen recording grant"
)
expect(
    !ScreenCapturePermissionProbe.isGranted(preflight: false, externalMenuBarItemTitles: [nil, ""]),
    "missing or empty external menu bar titles should use a negative preflight result"
)
print("PASS: 3 Screen Recording permission assertions")

expect(MenuBarActivation.resolve(rightClick: false, controlModifier: false, optionModifier: false, canToggleAlwaysHidden: true) == .toggleSection, "ordinary or accessibility activation must toggle the section")
expect(MenuBarActivation.resolve(rightClick: true, controlModifier: false, optionModifier: false, canToggleAlwaysHidden: true) == .contextMenu, "right-click must open the context menu")
expect(MenuBarActivation.resolve(rightClick: false, controlModifier: true, optionModifier: false, canToggleAlwaysHidden: true) == .contextMenu, "Control-click must open the context menu")
expect(MenuBarActivation.resolve(rightClick: false, controlModifier: false, optionModifier: true, canToggleAlwaysHidden: true) == .toggleAlwaysHidden, "Option-click must toggle always-hidden when enabled")
expect(MenuBarActivation.resolve(rightClick: false, controlModifier: false, optionModifier: true, canToggleAlwaysHidden: false) == .toggleSection, "disabled Option action must fall back to ordinary activation")
expect(MenuBarActivation.resolve(rightClick: false, controlModifier: true, optionModifier: true, canToggleAlwaysHidden: true) == .contextMenu, "Control must take precedence over Option")
expect(MenuBarActivation.resolve(rightClick: true, controlModifier: false, optionModifier: true, canToggleAlwaysHidden: true) == .contextMenu, "right-click must take precedence over Option")
expect(MenuBarActivation.resolve(rightClick: false, controlModifier: false, optionModifier: false, canToggleAlwaysHidden: false) == .toggleSection, "primary activation must work even when always-hidden toggling is disabled")
print("PASS: 8 menu bar activation assertions")

var presentation = MenuBarPresentationRequest()
let firstRequest = presentation.begin()
expect(presentation.isCurrent(firstRequest), "a new toolbar request must be current")
presentation.cancel()
expect(!presentation.isCurrent(firstRequest), "a closed toolbar must not reopen when image capture completes")
let secondRequest = presentation.begin()
let thirdRequest = presentation.begin()
expect(!presentation.isCurrent(secondRequest), "a newer toolbar request must replace an older request")
expect(presentation.isCurrent(thirdRequest), "only the newest toolbar request may present")
presentation.cancel()
expect(!presentation.isCurrent(thirdRequest), "closing a newer toolbar must cancel that request too")
print("PASS: 5 toolbar presentation assertions")

expect(!MenuBarToolbarPolicy.shouldUseToolbar(enabled: false, onlyOnNotchedScreens: false, screenHasNotch: false), "disabled toolbar must stay disabled on ordinary screens")
expect(!MenuBarToolbarPolicy.shouldUseToolbar(enabled: false, onlyOnNotchedScreens: false, screenHasNotch: true), "disabled toolbar must stay disabled on notched screens")
expect(MenuBarToolbarPolicy.shouldUseToolbar(enabled: true, onlyOnNotchedScreens: false, screenHasNotch: false), "all-screen toolbar must work on ordinary screens")
expect(MenuBarToolbarPolicy.shouldUseToolbar(enabled: true, onlyOnNotchedScreens: false, screenHasNotch: true), "all-screen toolbar must work on notched screens")
expect(!MenuBarToolbarPolicy.shouldUseToolbar(enabled: true, onlyOnNotchedScreens: true, screenHasNotch: false), "notch-only mode must use the top menu bar on ordinary screens")
expect(MenuBarToolbarPolicy.shouldUseToolbar(enabled: true, onlyOnNotchedScreens: true, screenHasNotch: true), "notch-only mode must use the toolbar on notched screens")
print("PASS: 6 toolbar screen policy assertions")

let primaryMenuBar = CGRect(x: 0, y: 944, width: 1512, height: 38)
let secondaryMenuBar = CGRect(x: 1512, y: 944, width: 1512, height: 38)
expect(MenuBarControlPlacement.needsRecovery(iconFrame: CGRect(x: -17, y: 945, width: 33, height: 37), menuBarFrames: [primaryMenuBar], notchFrames: []), "the observed offscreen status icon must be recovered")
expect(!MenuBarControlPlacement.needsRecovery(iconFrame: CGRect(x: 1200, y: 945, width: 33, height: 37), menuBarFrames: [primaryMenuBar], notchFrames: []), "a visible icon must keep its user-selected position")
expect(!MenuBarControlPlacement.needsRecovery(iconFrame: CGRect(x: 1600, y: 945, width: 33, height: 37), menuBarFrames: [primaryMenuBar, secondaryMenuBar], notchFrames: []), "an icon on another display must keep its position")
expect(MenuBarControlPlacement.needsRecovery(iconFrame: CGRect(x: 730, y: 945, width: 33, height: 37), menuBarFrames: [primaryMenuBar], notchFrames: [CGRect(x: 680, y: 944, width: 152, height: 38)]), "an icon inside the notch must be recovered")
expect(!MenuBarControlPlacement.needsRecovery(iconFrame: .zero, menuBarFrames: [primaryMenuBar], notchFrames: []), "an unlaid-out status window must not trigger recovery")
expect(!MenuBarControlPlacement.needsRecovery(iconFrame: CGRect(x: -17, y: 945, width: 33, height: 37), menuBarFrames: [], notchFrames: []), "missing screen geometry must not trigger recovery")
print("PASS: 6 status icon placement assertions")

// The purple marker changes both the section and the physical insertion anchor.
var insertion = NewMenuBarItemPlacement()
expect(insertion.section == .hidden, "new items should enter Hidden by default")
expect(insertion.insertionIndex(in: [mail, calendar]) == 0, "default marker belongs at the start")
insertion.move(to: .visible, before: calendar)
expect(insertion.section == .visible, "dragging the marker must change its section")
expect(insertion.insertionIndex(in: [mail, calendar]) == 1, "marker must stay before the chosen anchor")
expect(insertion.insertionIndex(in: [mail]) == 0, "missing anchors must fall back to the section start")
insertion.move(to: .alwaysHidden, before: nil)
expect(insertion.insertionIndex(in: [mail, calendar]) == 2, "dropping at the end must persist the end position")
expect(insertion.insertionIndex(in: []) == 0, "empty sections must accept the marker")
let restoredInsertion = try JSONDecoder().decode(NewMenuBarItemPlacement.self, from: JSONEncoder().encode(insertion))
expect(restoredInsertion == insertion, "section and end position must survive restart")
insertion.move(to: .hidden, before: calendar)
let restoredAnchor = try JSONDecoder().decode(NewMenuBarItemPlacement.self, from: JSONEncoder().encode(insertion))
expect(restoredAnchor.beforeItem == calendar && !restoredAnchor.atEnd, "a saved anchor must survive restart")
var ledger = MenuBarItemLedger()
expect(!ledger.seedIfNeeded(with: []), "an empty startup cache must not initialize the baseline")
expect(ledger.seedIfNeeded(with: [mail, calendar]), "first valid snapshot should preserve all existing items")
expect(ledger.unseen(in: [mail, calendar]).isEmpty, "baseline items must not be rearranged")
expect(!ledger.seedIfNeeded(with: [battery]), "subsequent snapshots must not silently absorb new items")
expect(ledger.unseen(in: [mail, battery, battery]) == [battery], "new identities must be deduplicated")
expect(ledger.unseen(in: [battery]) == [battery], "failed moves must remain eligible for retry")
ledger.acknowledge(battery)
expect(ledger.unseen(in: [battery, calendar]).isEmpty, "successful moves and returning apps must not be moved again")
let restoredLedger = try JSONDecoder().decode(MenuBarItemLedger.self, from: JSONEncoder().encode(ledger))
expect(restoredLedger == ledger, "known identities must survive restart")
expect(restoredLedger.unseen(in: [mail, calendar, battery]).isEmpty, "restart must not reinterpret existing apps as new")
print("PASS: 18 new-item insertion and persistence assertions")

var spacer = MenuBarPaletteItem(kind: .spacer, name: "空隙", width: 32)
expect(spacer.statusWidth == 32, "spacers should retain their chosen width")
spacer.width = -3
expect(spacer.statusWidth == 8, "spacer widths must have a nonzero lower bound")
spacer.width = 1000
expect(spacer.statusWidth == 160, "spacer width must be bounded")
spacer.width = .nan
expect(spacer.statusWidth == 20, "invalid widths should fall back to a safe default")
spacer.width = 32
let restoredSpacer = try JSONDecoder().decode(MenuBarPaletteItem.self, from: JSONEncoder().encode(spacer))
expect(restoredSpacer == spacer, "spacer identity and width must survive restart")
var group = MenuBarPaletteItem(kind: .group, name: "工具", members: [mail, calendar])
group.origins = [.init(item: mail, section: .visible, beforeItem: battery), .init(item: calendar, section: .hidden, beforeItem: nil)]
let restoredGroup = try JSONDecoder().decode(MenuBarPaletteItem.self, from: JSONEncoder().encode(group))
expect(restoredGroup == group, "groups must preserve member order and restoration destinations")
expect(group.statusAutosaveName != spacer.statusAutosaveName, "each palette item needs a unique native identity")
expect(group.statusAutosaveName.hasPrefix("BX-group-"), "native group identities must be identifiable by the item cache")
print("PASS: 8 spacer and group persistence assertions")

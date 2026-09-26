//
//  LayoutBarItemView.swift
//  Ice
//

import Cocoa
import Combine

// MARK: - LayoutBarItemView

/// A view that displays an image in a menu bar layout view.
final class LayoutBarItemView: NSView {
    private weak var appState: AppState?

    private var cancellables = Set<AnyCancellable>()

    /// The item that the view represents.
    let item: MenuBarItem

    /// Temporary information that the item view retains when it is moved outside
    /// of a layout view.
    ///
    /// When the item view is dragged outside of a layout view, this property is set
    /// to hold the layout view's container view, as well as the index of the item
    /// view in relation to the container's other items. Upon being inserted into a
    /// new layout view, these values are removed. If the item is dropped outside of
    /// a layout view, these values are used to reinsert the item view in its original
    /// layout view.
    var oldContainerInfo: (container: LayoutBarContainer, index: Int)?

    /// A Boolean value that indicates whether the item view is currently inside a container.
    var hasContainer = false

    /// The image displayed inside the view.
    private var image: NSImage? {
        didSet {
            if item.info == .newItems, let image {
                setFrameSize(image.size)
            } else if
                let image,
                let screen = appState?.imageCache.screen
            {
                let size = CGSize(
                    width: image.size.width / screen.backingScaleFactor,
                    height: image.size.height / screen.backingScaleFactor
                )
                setFrameSize(size)
            } else {
                setFrameSize(.zero)
            }
            needsDisplay = true
        }
    }

    /// A Boolean value that indicates whether the item view is a dragging placeholder.
    ///
    /// If this value is `true`, the item view does not draw its image.
    var isDraggingPlaceholder = false {
        didSet {
            needsDisplay = true
        }
    }

    /// A Boolean value that indicates whether the view is enabled.
    var isEnabled = true {
        didSet {
            needsDisplay = true
        }
    }

    /// Creates a view that displays the given menu bar item.
    init(appState: AppState, item: MenuBarItem) {
        self.item = item
        self.appState = appState

        // set the frame to the full item frame size; the image will be centered when displayed
        super.init(frame: CGRect(origin: .zero, size: item.info.isSpecial ? .zero : item.frame.size))
        unregisterDraggedTypes()

        self.toolTip = item.displayName
        self.isEnabled = item.isMovable
        setAccessibilityElement(true)
        setAccessibilityRole(.layoutItem)
        setAccessibilityIdentifier("BarextenderLayoutItem-\(item.info.description)")
        if item.info == .newItems {
            let label = BarextenderLocalization.string("New menu bar items appear here")
            toolTip = BarextenderLocalization.string("Drag this marker to choose where new menu bar items appear.")
            setAccessibilityLabel(label)
            setAccessibilityHelp(toolTip)
            image = Self.insertionMarkerImage(label: label)
            // Initializer assignments do not invoke property observers.
            // Never inherit the borrowed delimiter's 5000-point native width.
            setFrameSize(image?.size ?? .zero)
        } else {
            let name = appState.paletteManager.configuration(for: item.info)?.name ?? item.displayName
            setAccessibilityLabel(name)
            toolTip = name
            configureCancellables()
        }
    }

    private static func insertionMarkerImage(label: String) -> NSImage {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14), .foregroundColor: NSColor.white,
        ]
        let text = label as NSString
        let size = CGSize(width: ceil(text.size(withAttributes: attributes).width) + 14, height: 25)
        return NSImage(size: size, flipped: false) { rect in
            NSColor(srgbRed: 0.72, green: 0.29, blue: 0.91, alpha: 1).setFill()
            NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5).fill()
            text.draw(at: CGPoint(x: 7, y: 4), withAttributes: attributes)
            return true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func menu(for event: NSEvent) -> NSMenu? {
        guard item.info == .newItems else { return super.menu(for: event) }
        let menu = NSMenu(title: BarextenderLocalization.string("New menu bar item position"))
        for (index, section) in MenuBarSection.Name.allCases.enumerated() {
            let parent = NSMenuItem(title: section.displayString, action: nil, keyEquivalent: "")
            let submenu = NSMenu(title: section.displayString)
            for (offset, title) in ["At the start of this section", "At the end of this section"].enumerated() {
                let choice = NSMenuItem(title: BarextenderLocalization.string(title), action: #selector(chooseInsertionPosition), keyEquivalent: "")
                choice.target = self
                choice.tag = index * 2 + offset
                submenu.addItem(choice)
            }
            parent.submenu = submenu
            menu.addItem(parent)
        }
        return menu
    }

    @objc private func chooseInsertionPosition(_ sender: NSMenuItem) {
        guard let appState, MenuBarSection.Name.allCases.indices.contains(sender.tag / 2) else { return }
        let section = MenuBarSection.Name.allCases[sender.tag / 2]
        let first = sender.tag % 2 == 0 ? appState.itemManager.itemCache.managedItems(for: section).first : nil
        appState.newItemManager.setPlacement(in: section, before: first)
    }

    private func configureCancellables() {
        var c = Set<AnyCancellable>()

        if let appState {
            appState.paletteManager.$items
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    guard let self else { return }
                    let name = appState.paletteManager.configuration(for: item.info)?.name ?? item.displayName
                    setAccessibilityLabel(name)
                    toolTip = name
                    needsDisplay = true
                }
                .store(in: &c)
            appState.imageCache.$images
                .sink { [weak self] images in
                    guard
                        let self,
                        let cgImage = images[item.info]
                    else {
                        return
                    }
                    image = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
                }
                .store(in: &c)
        }

        cancellables = c
    }

    /// Provides an alert to display when the item view is disabled.
    func provideAlertForDisabledItem() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = BarextenderLocalization.string("Menu bar item is not movable.")
        alert.informativeText = BarextenderLocalization.format("macOS prohibits %@ from being moved.", item.displayName)
        return alert
    }

    /// Provides an alert to display when a menu bar item is unresponsive.
    func provideAlertForUnresponsiveItem() -> NSAlert {
        let alert = provideAlertForDisabledItem()
        alert.informativeText = BarextenderLocalization.format(
            "%@ is unresponsive. Until it is restarted, it cannot be moved. Movement of other menu bar items may also be affected until this is resolved.",
            item.displayName
        )
        return alert
    }

    override func draw(_ dirtyRect: NSRect) {
        if !isDraggingPlaceholder {
            image?.draw(
                in: bounds,
                from: .zero,
                operation: .sourceOver,
                fraction: isEnabled ? 1.0 : 0.67
            )
            if let configuration = appState?.paletteManager.configuration(for: item.info), configuration.kind == .spacer {
                NSColor.secondaryLabelColor.setStroke()
                let outline = NSBezierPath(roundedRect: bounds.insetBy(dx: 2, dy: 4), xRadius: 3, yRadius: 3)
                outline.setLineDash([2, 2], count: 2, phase: 0)
                outline.stroke()
            }
            if !item.info.isSpecial, Bridging.responsivity(for: item.ownerPID) == .unresponsive {
                let warningImage = NSImage.warning
                let width: CGFloat = 15
                let scale = width / warningImage.size.width
                let size = CGSize(
                    width: width,
                    height: warningImage.size.height * scale
                )
                warningImage.draw(
                    in: CGRect(
                        x: bounds.maxX - size.width,
                        y: bounds.minY,
                        width: size.width,
                        height: size.height
                    )
                )
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        // These layout items have no primary click action. Start tracking at
        // mouse-down so a fast drag can enter another section before mouse-up.
        startLayoutDrag(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard !isDraggingPlaceholder else { return }
        startLayoutDrag(with: event)
    }

    private func startLayoutDrag(with event: NSEvent) {
        Logger.layoutItem.info("Starting layout drag; insertion marker: \(self.item.info == .newItems)")

        guard isEnabled else {
            let alert = provideAlertForDisabledItem()
            alert.runModal()
            return
        }

        guard Bridging.responsivity(for: item.ownerPID) != .unresponsive else {
            let alert = provideAlertForUnresponsiveItem()
            alert.runModal()
            return
        }

        let pasteboardItem = NSPasteboardItem()
        // contents of the pasteboard item don't matter here, as all needed information
        // is available directly from the dragging session; what matters is that the type
        // is set to `layoutBarItem`, as that is what the layout bar registers for
        pasteboardItem.setData(Data(), forType: .layoutBarItem)

        let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
        draggingItem.setDraggingFrame(bounds, contents: image)

        beginDraggingSession(with: [draggingItem], event: event, source: self)
    }
}

// MARK: LayoutBarItemView: NSDraggingSource
extension LayoutBarItemView: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        // make sure the container doesn't update its arranged views and that items
        // aren't arranged during a dragging session
        if let container = superview as? LayoutBarContainer {
            if let index = container.arrangedViews.firstIndex(of: self) {
                oldContainerInfo = (container, index)
            }
            container.canSetArrangedViews = false
        }

        // prevent the dragging image from animating back to its original location
        session.animatesToStartingPositionsOnCancelOrFail = false

        // async to prevent the view from disappearing before the dragging image appears
        DispatchQueue.main.async {
            self.isDraggingPlaceholder = true
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        defer {
            // always remove container info at the end of a session
            oldContainerInfo?.container.canSetArrangedViews = true
            oldContainerInfo = nil
        }

        // since the session's `animatesToStartingPositionsOnCancelOrFail` property was
        // set to false when the session began (above), there is no delay between the user
        // releasing the dragging item and this method being called; thus, `isDraggingPlaceholder`
        // only needs to be updated here; if we ever decide we want animation, it may also
        // need to be updated inside `performDragOperation(_:)` on `LayoutBarPaddingView`
        isDraggingPlaceholder = false

        // if the drop occurs outside of a container, reinsert the view into its original
        // container at its original index
        if !hasContainer {
            guard let (container, index) = oldContainerInfo else {
                return
            }
            container.shouldAnimateNextLayoutPass = false
            container.arrangedViews.insert(self, at: index)
        }
    }
}

extension LayoutBarItemView: NSAccessibilityLayoutItem { }

private extension Logger {
    static let layoutItem = Logger(category: "LayoutBarItem")
}

// MARK: Layout Bar Item Pasteboard Type
extension NSPasteboard.PasteboardType {
    static let layoutBarItem = Self("\(Constants.bundleIdentifier).layout-bar-item")
}

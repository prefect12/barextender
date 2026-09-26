//
//  LayoutBarPaddingView.swift
//  Ice
//

import Cocoa
import Combine

/// A Cocoa view that manages the menu bar layout interface.
final class LayoutBarPaddingView: NSView {
    private let container: LayoutBarContainer

    /// The section whose items are represented.
    var section: MenuBarSection {
        container.section
    }

    /// The amount of space between each arranged view.
    var spacing: CGFloat {
        get { container.spacing }
        set { container.spacing = newValue }
    }

    /// The layout view's arranged views.
    ///
    /// The views are laid out from left to right in the order that they
    /// appear in the array. The ``spacing`` property determines the amount
    /// of space between each view.
    var arrangedViews: [LayoutBarItemView] {
        get { container.arrangedViews }
        set { container.arrangedViews = newValue }
    }

    /// Creates a layout bar view with the given app state, section, and spacing.
    ///
    /// - Parameters:
    ///   - appState: The shared app state instance.
    ///   - section: The section whose items are represented.
    ///   - spacing: The amount of space between each arranged view.
    init(appState: AppState, section: MenuBarSection, spacing: CGFloat) {
        self.container = LayoutBarContainer(appState: appState, section: section, spacing: spacing)

        super.init(frame: .zero)
        addSubview(self.container)

        self.translatesAutoresizingMaskIntoConstraints = false
        var constraints = [
            // center the container along the y axis
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
        ]
        if section.name == .visible {
            constraints += [
                trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: 7.5),
                leadingAnchor.constraint(lessThanOrEqualTo: container.leadingAnchor, constant: -7.5),
            ]
        } else {
            constraints += [
                leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: -7.5),
                trailingAnchor.constraint(greaterThanOrEqualTo: container.trailingAnchor, constant: 7.5),
            ]
        }
        NSLayoutConstraint.activate(constraints)

        registerForDraggedTypes([.layoutBarItem])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        container.updateArrangedViewsForDrag(with: sender, phase: .entered)
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let sender {
            container.updateArrangedViewsForDrag(with: sender, phase: .exited)
        }
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        container.updateArrangedViewsForDrag(with: sender, phase: .updated)
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        container.updateArrangedViewsForDrag(with: sender, phase: .ended)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        defer {
            DispatchQueue.main.async {
                self.container.canSetArrangedViews = true
            }
        }

        guard let draggingSource = sender.draggingSource as? LayoutBarItemView else {
            return false
        }

        if let index = arrangedViews.firstIndex(of: draggingSource) {
            let nextItem = arrangedViews.dropFirst(index + 1).first { !$0.item.info.isSpecial }?.item
            let previousItem = arrangedViews.prefix(index).last { !$0.item.info.isSpecial }?.item
            if let markerIndex = arrangedViews.firstIndex(where: { $0.item.info == .newItems }) {
                let afterMarker = arrangedViews.dropFirst(markerIndex + 1).first { !$0.item.info.isSpecial }?.item
                container.appState?.newItemManager.setPlacement(in: section.name, before: afterMarker)
            }
            if draggingSource.item.info == .newItems {
                // The marker updates a rule; no physical menu bar item is dragged.
                return true
            }
            if let nextItem {
                move(item: draggingSource.item, to: .leftOfItem(nextItem))
            } else if let previousItem {
                move(item: draggingSource.item, to: .rightOfItem(previousItem))
            } else {
                // dragging source is the only view in the layout bar, so we
                // need to find a target item
                let items = MenuBarItem.getMenuBarItems(onScreenOnly: false, activeSpaceOnly: true)
                let targetItem: MenuBarItem? = switch section.name {
                case .visible: nil // visible section always has more than 1 item
                case .hidden: items.first { $0.info == .hiddenControlItem }
                case .alwaysHidden: items.first { $0.info == .alwaysHiddenControlItem }
                }
                if let targetItem {
                    move(item: draggingSource.item, to: .leftOfItem(targetItem))
                } else {
                    Logger.layoutBar.error("No target item for layout bar drag")
                }
            }
        }

        return true
    }

    private func move(item: MenuBarItem, to destination: MenuBarItemManager.MoveDestination) {
        guard let appState = container.appState else {
            return
        }
        Task {
            try await Task.sleep(for: .milliseconds(25))
            do {
                try await appState.itemManager.slowMove(item: item, to: destination)
                appState.newItemManager.acknowledgeManualPlacement(of: item)
                appState.itemManager.removeTempShownItemFromCache(with: item.info)
                await appState.itemManager.refreshItems()
            } catch {
                Logger.layoutBar.error("Error moving menu bar item: \(error)")
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }
}

// MARK: - Logger
private extension Logger {
    static let layoutBar = Logger(category: "LayoutBar")
}

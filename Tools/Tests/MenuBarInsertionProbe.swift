import Cocoa

@MainActor
final class InsertionProbe: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var label: NSTextField!
    private var items = [NSStatusItem]()
    private let session = UUID().uuidString

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 360, height: 160),
                          styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "Barextender 新图标测试"
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.spacing = 16
        label = NSTextField(labelWithString: "尚未创建测试图标")
        stack.addArrangedSubview(label)
        stack.addArrangedSubview(NSButton(title: "添加一个新菜单栏图标", target: self, action: #selector(addItem)))
        stack.addArrangedSubview(NSButton(title: "清理测试图标并退出", target: self, action: #selector(quit)))
        stack.frame = NSRect(x: 20, y: 20, width: 320, height: 120)
        window.contentView?.addSubview(stack)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func addItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.autosaveName = "InsertionProbe-\(session)-\(items.count + 1)"
        item.button?.title = "BXT\(items.count + 1)"
        item.button?.toolTip = "Barextender 新项目插入验收图标"
        items.append(item)
        label.stringValue = "已创建 \(items.count) 个测试图标"
    }

    @objc private func quit() {
        items.forEach { NSStatusBar.system.removeStatusItem($0) }
        items.removeAll()
        NSApp.terminate(nil)
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = InsertionProbe()
    app.delegate = delegate
    app.run()
}

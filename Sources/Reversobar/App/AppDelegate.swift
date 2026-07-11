import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let popover = NSPopover()
    private var eventMonitor: Any?
    private var hotKey: HotKeyManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setUpMainMenu()
        setUpStatusItem()
        setUpPopover()
        installOutsideClickMonitor()
        installGlobalHotKey()
        observeCloseRequests()
        observeLanguageChanges()
    }

    // MARK: - Setup

    /// A menu-bar-only (LSUIElement) app has no main menu, so the standard text-editing key
    /// equivalents (⌘A, ⌘C, ⌘V, ⌘X, ⌘Z) never reach the field editor. Installing an Edit menu
    /// — hidden, but live — wires them to the first responder so the search field behaves normally.
    private func setUpMainMenu() {
        let mainMenu = NSMenu()

        // App menu (provides ⌘Q).
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit \(AppInfo.name)",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        // Edit menu — standard responder-chain editing actions.
        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApp.mainMenu = mainMenu
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.action = #selector(togglePopover(_:))
        button.target = self
        updateStatusTitle()
    }

    /// Renders the current source → target pair (flags + arrow) in the menu bar.
    private func updateStatusTitle() {
        guard let button = statusItem.button else { return }
        let defaults = UserDefaults.standard
        let source = Language.byCode(defaults.string(forKey: AppInfo.Defaults.sourceLang) ?? "") ?? .english
        let target = Language.byCode(defaults.string(forKey: AppInfo.Defaults.targetLang) ?? "") ?? .russian

        let title = NSMutableAttributedString()
        if let flag = flagAttachment(source.flag) { title.append(flag) }
        title.append(NSAttributedString(string: "  ›  ", attributes: [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: 11, weight: .bold)
        ]))
        if let flag = flagAttachment(target.flag) { title.append(flag) }

        button.image = nil
        button.attributedTitle = title
        button.toolTip = "\(AppInfo.name): \(source.name) → \(target.name)"
    }

    /// A small, vertically-centred flag image as an attributed-string attachment.
    private func flagAttachment(_ code: String) -> NSAttributedString? {
        guard let image = Flags.sized(code, width: 18) else { return nil }
        let attachment = NSTextAttachment()
        attachment.image = image
        attachment.bounds = CGRect(x: 0, y: -3, width: image.size.width, height: image.size.height)
        return NSAttributedString(attachment: attachment)
    }

    private func setUpPopover() {
        popover.contentSize = Theme.popoverSize
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: ContentView())
    }

    /// Dismiss the popover when the user clicks in another app.
    private func installOutsideClickMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self, self.popover.isShown else { return }
            self.closePopover()
        }
    }

    /// ⌥Space toggles the popover from anywhere.
    private func installGlobalHotKey() {
        hotKey = HotKeyManager { [weak self] in
            Task { @MainActor in self?.togglePopover(nil) }
        }
    }

    /// Lets the SwiftUI view request a close (Escape key).
    private func observeCloseRequests() {
        NotificationCenter.default.addObserver(
            forName: .requestClose, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.closePopover() }
        }
    }

    /// Refreshes the menu-bar title when the user changes languages in the popover.
    private func observeLanguageChanges() {
        NotificationCenter.default.addObserver(
            forName: .languagePairChanged, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.updateStatusTitle() }
        }
    }

    // MARK: - Popover control

    @objc private func togglePopover(_ sender: Any?) {
        popover.isShown ? closePopover() : showPopover()
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        // Bring app forward so the text field becomes first responder and accepts keystrokes.
        NSApp.activate(ignoringOtherApps: true)
        popover.contentViewController?.view.window?.makeKey()
        NotificationCenter.default.post(name: .popoverDidOpen, object: nil)
    }

    private func closePopover() {
        popover.performClose(nil)
    }
}

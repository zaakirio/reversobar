import AppKit
import SwiftUI

@MainActor
func runApp() {
    // Debug: open the real ContentView in a borderless window for live screenshotting.
    // Used by `scripts/preview.sh`; never reached in a normal launch.
    if CommandLine.arguments.contains("--window") {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        if CommandLine.arguments.contains("--dark") { app.appearance = NSAppearance(named: .darkAqua) }
        let win = NSWindow(contentRect: NSRect(origin: .zero, size: Theme.popoverSize),
                           styleMask: [.borderless], backing: .buffered, defer: false)
        win.contentView = NSHostingView(rootView: ContentView())
        win.isOpaque = false
        win.backgroundColor = .clear
        if let screen = NSScreen.main {
            win.setFrameTopLeftPoint(NSPoint(x: 24, y: screen.frame.maxY - 24))
        }
        win.makeKeyAndOrderFront(nil)
        app.activate(ignoringOtherApps: true)
        app.run()
        return
    }

    // Menu-bar (accessory) application entry point.
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
}

runApp()

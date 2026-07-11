import Foundation

/// Static app identity used across the UI, persistence, and packaging.
enum AppInfo {
    static let name = "Reversobar"
    static let bundleID = "com.zaakir.reversobar"

    /// UserDefaults keys, namespaced to avoid collisions.
    enum Defaults {
        static let sourceLang = "reversobar.sourceLang"
        static let targetLang = "reversobar.targetLang"
    }
}

extension Notification.Name {
    /// Posted by the AppDelegate when the popover opens, so the UI can focus the search field.
    static let popoverDidOpen = Notification.Name("reversobar.popoverDidOpen")
    /// Posted by the UI (Escape) to ask the AppDelegate to close the popover.
    static let requestClose = Notification.Name("reversobar.requestClose")
    /// Posted when the source/target pair changes, so the status item can refresh.
    static let languagePairChanged = Notification.Name("reversobar.languagePairChanged")
}

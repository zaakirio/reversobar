import SwiftUI
import AppKit

/// Centralised layout and styling constants, plus reusable view modifiers, so the look stays
/// consistent and tunable from one place.
enum Theme {
    /// Popover content size.
    static let popoverSize = CGSize(width: 440, height: 560)

    enum Radius {
        static let card: CGFloat = 13
        static let field: CGFloat = 11
        static let dropdown: CGFloat = 12
        static let row: CGFloat = 11
    }

    enum Anim {
        static let snappy = Animation.snappy(duration: 0.18)
        static let toast = Animation.spring(duration: 0.28)
    }
}

// MARK: - Reusable modifiers

extension View {
    /// Shows the pointing-hand cursor while hovering, signalling a clickable surface.
    func pointingHand() -> some View {
        onHover { inside in
            if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
        }
    }

    /// The tinted capsule used by header pills and toggles.
    func pillBackground(active: Bool = false) -> some View {
        background(.tint.opacity(active ? 0.24 : 0.14), in: Capsule())
            .overlay(Capsule().stroke(.tint.opacity(0.2)))
    }

    /// A subtle rounded surface used by result rows.
    func rowBackground(hovering: Bool, radius: CGFloat = Theme.Radius.row) -> some View {
        background(.quaternary.opacity(hovering ? 0.55 : 0.32),
                   in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

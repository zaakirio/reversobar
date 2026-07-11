import SwiftUI

/// The bottom hint bar showing keyboard shortcuts.
struct FooterBar: View {
    var body: some View {
        HStack(spacing: 12) {
            HintItem(key: "↩", label: "copy")
            HintItem(key: "esc", label: "close")
            Spacer()
            HStack(spacing: 4) {
                KeyCap("⌥"); KeyCap("space")
                Text("anywhere").font(.system(size: 10)).foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.black.opacity(0.04))
        .overlay(Divider().opacity(0.5), alignment: .top)
    }
}

struct HintItem: View {
    let key: String
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            KeyCap(key)
            Text(label).font(.system(size: 10)).foregroundStyle(.tertiary)
        }
    }
}

struct KeyCap: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 5)
            .padding(.vertical, 1.5)
            .background(.quaternary.opacity(0.7), in: RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(.quaternary, lineWidth: 0.5))
    }
}

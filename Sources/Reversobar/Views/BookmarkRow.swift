import SwiftUI

/// A saved phrasebook entry: source and target (each with its flag), transliteration, and actions.
struct BookmarkRow: View {
    let bookmark: Bookmark
    let onCopy: (String) -> Void
    let onRemove: () -> Void
    @State private var hover = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    FlagImage(code: bookmark.sourceLanguage.flag, width: 16)
                    Text(bookmark.source)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                HStack(spacing: 6) {
                    FlagImage(code: bookmark.targetLanguage.flag, width: 16)
                    Text(bookmark.translation)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }
                if let t = bookmark.transliteration, !t.isEmpty {
                    Text(t).font(.system(size: 11)).foregroundStyle(.tertiary).padding(.leading, 22)
                }
            }
            Spacer(minLength: 4)
            VStack(spacing: 10) {
                SpeakerButton(text: bookmark.translation, language: bookmark.targetLanguage)
                Button(action: { onCopy(bookmark.translation) }) {
                    Image(systemName: "doc.on.doc").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).pointingHand().help("Copy translation")
                Button(action: onRemove) {
                    Image(systemName: "star.fill").foregroundStyle(.yellow)
                }
                .buttonStyle(.plain).pointingHand().help("Remove bookmark")
            }
            .font(.system(size: 13))
        }
        .padding(11)
        .rowBackground(hovering: hover)
        .onHover { hover = $0 }
    }
}

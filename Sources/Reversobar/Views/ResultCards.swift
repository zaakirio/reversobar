import SwiftUI

/// The prominent primary translation, click-to-copy with bookmark / audio / copy controls.
struct PrimaryCard: View {
    let text: String
    let language: Language
    var isBookmarked: Bool = false
    var onBookmark: () -> Void = {}
    let onCopy: (String) -> Void
    @State private var hovering = false
    @State private var flashing = false

    var body: some View {
        Button(action: flashCopy) {
            HStack(alignment: .top, spacing: 10) {
                Text(text)
                    .font(.system(size: 23, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                VStack(spacing: 10) {
                    BookmarkButton(isOn: isBookmarked, action: onBookmark)
                    SpeakerButton(text: text, language: language)
                    Image(systemName: flashing ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(flashing ? Color.accentColor : .secondary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .font(.system(size: 14))
            }
            .padding(15)
            .background(.tint.opacity(hovering ? 0.16 : 0.10), in: RoundedRectangle(cornerRadius: Theme.Radius.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card).stroke(.tint.opacity(0.18)))
        }
        .buttonStyle(.plain)
        .pointingHand()
        .onHover { hovering = $0 }
        .help("Click to copy")
    }

    private func flashCopy() {
        onCopy(text)
        withAnimation(Theme.Anim.snappy) { flashing = true }
        Task {
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(Theme.Anim.snappy) { flashing = false }
        }
    }
}

/// A secondary "context" translation with part of speech, frequency, transliteration and examples.
struct AlternativeRow: View {
    let alternative: Alternative
    let targetLanguage: Language
    var isBookmarked: Bool = false
    var onBookmark: () -> Void = {}
    let onCopy: (String) -> Void
    @State private var expanded = false
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Button(action: { onCopy(alternative.translation) }) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(alternative.translation)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.primary)
                        if let pos = alternative.partOfSpeech, !pos.isEmpty {
                            Text(pos)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(.quaternary, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .pointingHand()
                .help("Click to copy")

                if let freq = alternative.frequency {
                    FrequencyBadge(frequency: freq)
                }
                BookmarkButton(isOn: isBookmarked, action: onBookmark)
                SpeakerButton(text: alternative.translation, language: targetLanguage)
            }

            if let translit = alternative.transliteration, !translit.isEmpty {
                Text(translit)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            if !alternative.examples.isEmpty {
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { expanded.toggle() } }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9, weight: .semibold))
                            .rotationEffect(.degrees(expanded ? 90 : 0))
                        Text("\(alternative.examples.count) example\(alternative.examples.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .pointingHand()

                if expanded {
                    VStack(alignment: .leading, spacing: 7) {
                        ForEach(alternative.examples) { ex in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(ex.source).font(.system(size: 11)).foregroundStyle(.secondary)
                                Text(ex.target).font(.system(size: 11)).foregroundStyle(.primary)
                            }
                            .padding(.leading, 6)
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 1).fill(.tint.opacity(0.4)).frame(width: 2)
                            }
                        }
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(11)
        .rowBackground(hovering: hovering)
        .onHover { hovering = $0 }
    }
}

/// Three ascending bars indicating how common a context translation is.
struct FrequencyBadge: View {
    let frequency: Int

    private var level: Int {
        switch frequency {
        case 100...: return 3
        case 20..<100: return 2
        default: return 1
        }
    }

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i < level ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(width: 3, height: 7 + CGFloat(i) * 2.5)
            }
        }
        .help("Frequency: \(frequency)")
    }
}

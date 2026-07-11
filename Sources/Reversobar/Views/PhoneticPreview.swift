import SwiftUI

/// Live Latin → native-script preview with a per-phoneme breakdown, shown above the results
/// when phonetic input is active.
struct PhoneticPreview: View {
    let text: String
    let phonemes: [Phoneme]
    let language: Language
    let scheme: PhoneticScheme
    let onCopy: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if text.isEmpty {
                Text(scheme.hint)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text(text)
                        .font(.system(size: 23, weight: .semibold))
                        .textSelection(.enabled)
                    Spacer()
                    Button(action: { onCopy(text) }) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .pointingHand()
                    .help("Copy the \(language.name) text")
                    SpeakerButton(text: text, language: language)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(phonemes) { PhonemeChip(phoneme: $0) }
                    }
                    .padding(.bottom, 2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(.tint.opacity(0.07))
    }
}

/// A single Latin → native mapping chip; multi-letter chunks are highlighted in the accent tint.
struct PhonemeChip: View {
    let phoneme: Phoneme

    var body: some View {
        VStack(spacing: 1) {
            Text(phoneme.native)
                .font(.system(size: 13, weight: .semibold))
            Text(phoneme.latin)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(
            phoneme.isDigraph ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.quaternary.opacity(0.6)),
            in: RoundedRectangle(cornerRadius: 7)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(phoneme.isDigraph ? AnyShapeStyle(.tint.opacity(0.35)) : AnyShapeStyle(.clear))
        )
    }
}

import SwiftUI

/// Plays the pronunciation of a phrase, animating while audio is playing.
struct SpeakerButton: View {
    let text: String
    let language: Language
    @ObservedObject private var audio = AudioPlayer.shared

    private var isPlaying: Bool {
        audio.isPlaying(text, language: language)
    }

    var body: some View {
        Button(action: { AudioPlayer.shared.play(text, language: language) }) {
            Image(systemName: isPlaying ? "speaker.wave.2.fill" : "speaker.wave.2")
                .foregroundStyle(isPlaying ? Color.accentColor : .secondary)
                .symbolEffect(.variableColor, isActive: isPlaying)
        }
        .buttonStyle(.plain)
        .pointingHand()
        .help("Play pronunciation")
        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
    }
}

/// Toggles whether a translation is saved to the phrasebook.
struct BookmarkButton: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isOn ? "star.fill" : "star")
                .foregroundStyle(isOn ? Color.yellow : .secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .pointingHand()
        .help(isOn ? "Remove bookmark" : "Bookmark this translation")
    }
}

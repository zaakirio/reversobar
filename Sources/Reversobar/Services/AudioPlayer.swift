import Foundation
import AVFoundation

/// Plays Reverso MP3 pronunciation streams, caching by phrase so repeats are instant.
@MainActor
final class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()

    @Published private var playingKey: String?

    private var player: AVAudioPlayer?
    private var cache: [String: Data] = [:]
    private let client = ReversoClient()

    private func key(_ text: String, _ language: Language) -> String {
        "\(language.code):\(text)"
    }

    func isPlaying(_ text: String, language: Language) -> Bool {
        playingKey == key(text, language)
    }

    func play(_ text: String, language: Language) {
        let cacheKey = key(text, language)
        playingKey = cacheKey

        if let data = cache[cacheKey] {
            start(data, key: cacheKey)
            return
        }

        Task {
            do {
                let data = try await client.fetchAudio(for: text, language: language)
                cache[cacheKey] = data
                // Ignore if the user already requested a different clip in the meantime.
                guard playingKey == cacheKey else { return }
                start(data, key: cacheKey)
            } catch {
                if playingKey == cacheKey { playingKey = nil }
            }
        }
    }

    private func start(_ data: Data, key: String) {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            self.player = player
            player.play()
        } catch {
            playingKey = nil
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playingKey = nil
        }
    }
}

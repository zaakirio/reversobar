import Foundation
import AVFoundation

/// Plays Reverso MP3 pronunciation streams, caching by phrase so repeats are instant.
@MainActor
final class AudioPlayer: NSObject, ObservableObject {
    static let shared = AudioPlayer()

    @Published private var playingKey: String?

    private var player: AVAudioPlayer?
    /// Key of the clip loaded into `player` — may lag `playingKey` while a fetch is in flight.
    private var currentClipKey: String?
    private var cache: [String: Data] = [:]
    private var cacheOrder: [String] = []
    private let cacheCapacity = 50   // the app is long-lived; don't hold MP3 data forever
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
                store(data, for: cacheKey)
                // Ignore if the user already requested a different clip in the meantime.
                guard playingKey == cacheKey else { return }
                start(data, key: cacheKey)
            } catch {
                if playingKey == cacheKey { playingKey = nil }
            }
        }
    }

    private func store(_ data: Data, for key: String) {
        if cache[key] == nil {
            cacheOrder.append(key)
            if cacheOrder.count > cacheCapacity {
                cache.removeValue(forKey: cacheOrder.removeFirst())
            }
        }
        cache[key] = data
    }

    private func start(_ data: Data, key: String) {
        do {
            let player = try AVAudioPlayer(data: data)
            player.delegate = self
            self.player = player
            currentClipKey = key
            player.play()
        } catch {
            playingKey = nil
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let finished = ObjectIdentifier(player)
        Task { @MainActor in
            // Only clear state for the clip that actually finished: a stale finish must not
            // cancel a newer request that is still fetching (playingKey already reassigned).
            guard let current = self.player, ObjectIdentifier(current) == finished,
                  self.playingKey == self.currentClipKey else { return }
            self.playingKey = nil
        }
    }
}

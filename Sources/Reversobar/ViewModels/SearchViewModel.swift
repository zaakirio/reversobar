import Foundation
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    // Input
    @Published var query: String = "" { didSet { onQueryChange() } }
    @Published var sourceLang: Language { didSet { onConfigChange() } }
    @Published var targetLang: Language { didSet { onConfigChange() } }
    @Published var phonetic: Bool = false { didSet { onConfigChange() } }

    // Derived input
    @Published var phoneticPreview: String = ""
    @Published var phonemes: [Phoneme] = []

    // Output
    @Published var output: TranslationOutput?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let client = ReversoClient()
    private var searchTask: Task<Void, Never>?
    private let debounce: Duration = .milliseconds(220)

    init() {
        let defaults = UserDefaults.standard
        sourceLang = Language.byCode(defaults.string(forKey: AppInfo.Defaults.sourceLang) ?? "") ?? .english
        targetLang = Language.byCode(defaults.string(forKey: AppInfo.Defaults.targetLang) ?? "") ?? .russian
    }

    /// Phonetic input applies when the source language has a Latin → native-script scheme.
    var canPhonetic: Bool { sourceLang.phoneticScheme != nil }

    /// The actual source text sent to the API (transliterated when phonetic input is on).
    var effectiveSource: String {
        (phonetic && canPhonetic) ? phoneticPreview : query
    }

    var effectiveFrom: Language { sourceLang }
    var effectiveTo: Language { targetLang }

    func setSource(_ lang: Language) {
        if lang == targetLang { targetLang = sourceLang }   // keep the two sides distinct
        sourceLang = lang
        if lang.phoneticScheme == nil { phonetic = false }
    }

    func setTarget(_ lang: Language) {
        if lang == sourceLang { sourceLang = targetLang }
        targetLang = lang
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(sourceLang.code, forKey: AppInfo.Defaults.sourceLang)
        defaults.set(targetLang.code, forKey: AppInfo.Defaults.targetLang)
        NotificationCenter.default.post(name: .languagePairChanged, object: nil)
    }

    private func onConfigChange() {
        persist()
        recomputePhonetics()
        scheduleSearch()
    }

    private func onQueryChange() {
        recomputePhonetics()
        scheduleSearch()
    }

    private func recomputePhonetics() {
        guard phonetic, let scheme = sourceLang.phoneticScheme else {
            phoneticPreview = ""
            phonemes = []
            return
        }
        let result = Transliterator.convert(query, scheme: scheme)
        phoneticPreview = result.text
        phonemes = result.phonemes
    }

    private func scheduleSearch() {
        searchTask?.cancel()
        let text = effectiveSource.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else {
            output = nil
            errorMessage = nil
            isLoading = false
            return
        }

        let from = effectiveFrom
        let to = effectiveTo

        // Instant path: a cached result skips the debounce and the network entirely.
        if let cached = TranslationCache.shared.get(text, from: from, to: to) {
            apply(cached)
            return
        }

        isLoading = true
        errorMessage = nil

        searchTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(for: self.debounce)
                try Task.checkCancellation()
                let response = try await self.client.translate(text, from: from, to: to)
                try Task.checkCancellation()
                let out = Self.output(from: response)
                // Never cache an empty result: a transient bad body would otherwise pin
                // "No translation found." to this query forever via the instant cache path.
                if !out.isEmpty {
                    TranslationCache.shared.set(out, input: text, from: from, to: to)
                }
                self.apply(out)
            } catch is CancellationError {
                // Superseded by a newer keystroke; leave state to the newer task.
            } catch {
                // URLSession surfaces mid-flight cancellation as URLError(.cancelled), not
                // CancellationError — without this guard a superseded request would stomp
                // the newer search's state with a spurious connection error.
                guard !Task.isCancelled else { return }
                self.isLoading = false
                self.errorMessage = Self.message(for: error)
            }
        }
    }

    private static func message(for error: Error) -> String {
        switch error {
        case ReversoError.badStatus(let code):
            return "Reverso returned an error (HTTP \(code)). Try again in a moment."
        case is DecodingError:
            return "Reverso sent an unexpected response."
        default:
            return "Couldn’t reach Reverso. Check your connection."
        }
    }

    private func apply(_ output: TranslationOutput) {
        isLoading = false
        self.output = output
        errorMessage = output.isEmpty ? "No translation found." : nil
    }

    /// Transforms a raw Reverso response into the view-facing output (pure, so it is cacheable).
    private static func output(from response: TranslationResponse) -> TranslationOutput {
        let primary = (response.translation ?? []).joined(separator: " ")
        let alternatives: [Alternative] = (response.contextResults?.results ?? []).map { result in
            let sources = result.sourceExamples ?? []
            let targets = result.targetExamples ?? []
            let examples = zip(sources, targets).prefix(4).map { src, tgt in
                Example(source: strip(src), target: strip(tgt))
            }
            return Alternative(
                translation: result.translation,
                transliteration: result.transliteration,
                frequency: result.frequency,
                partOfSpeech: result.partOfSpeech,
                examples: Array(examples)
            )
        }
        return TranslationOutput(primary: primary, correctedText: response.correctedText, alternatives: alternatives)
    }

    /// Removes the `<em>` highlight markup Reverso wraps around matched terms in examples.
    private static func strip(_ html: String) -> String {
        html
            .replacingOccurrences(of: "<em>", with: "")
            .replacingOccurrences(of: "</em>", with: "")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func swap() {
        let oldSource = sourceLang
        sourceLang = targetLang
        targetLang = oldSource
        if sourceLang.phoneticScheme == nil { phonetic = false }
    }

    func clear() {
        query = ""
        output = nil
        errorMessage = nil
    }
}

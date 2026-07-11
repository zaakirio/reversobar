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
    @Published var cyrillicPreview: String = ""
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

    /// Phonetic Latin→Cyrillic input only applies when the source language uses Cyrillic.
    var canPhonetic: Bool { sourceLang.isCyrillic }

    /// The actual source text sent to the API (transliterated Cyrillic when phonetic input is on).
    var effectiveSource: String {
        (phonetic && canPhonetic) ? cyrillicPreview : query
    }

    var effectiveFrom: Language { sourceLang }
    var effectiveTo: Language { targetLang }

    func setSource(_ lang: Language) {
        if lang == targetLang { targetLang = sourceLang }   // keep the two sides distinct
        sourceLang = lang
        if !lang.isCyrillic { phonetic = false }
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
        guard phonetic && canPhonetic else {
            cyrillicPreview = ""
            phonemes = []
            return
        }
        let result = Transliterator.convert(query)
        cyrillicPreview = result.text
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
                TranslationCache.shared.set(out, input: text, from: from, to: to)
                self.apply(out)
            } catch is CancellationError {
                // Superseded by a newer keystroke; leave state to the newer task.
            } catch {
                self.isLoading = false
                self.errorMessage = "Couldn’t reach Reverso. Check your connection."
            }
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
        if !sourceLang.isCyrillic { phonetic = false }
    }

    func clear() {
        query = ""
        output = nil
        errorMessage = nil
    }
}

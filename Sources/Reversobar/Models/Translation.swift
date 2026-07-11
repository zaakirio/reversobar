import Foundation

// MARK: - Reverso API response

/// The subset of Reverso's translation response that the app consumes.
struct TranslationResponse: Decodable {
    let from: String?
    let to: String?
    let translation: [String]?
    let correctedText: String?
    let contextResults: ContextResults?

    struct ContextResults: Decodable {
        let results: [ContextResult]?
    }

    struct ContextResult: Decodable {
        let translation: String
        let transliteration: String?
        let frequency: Int?
        let partOfSpeech: String?
        let sourceExamples: [String]?
        let targetExamples: [String]?
    }
}

// MARK: - View-facing result models

/// A fully-prepared translation result ready for display. `Codable` so it can be cached to disk.
struct TranslationOutput: Equatable, Codable {
    /// Primary one-line translation joined from the `translation` array.
    let primary: String
    let correctedText: String?
    let alternatives: [Alternative]

    /// Whether the result carries nothing to show.
    var isEmpty: Bool { primary.isEmpty && alternatives.isEmpty }
}

struct Alternative: Identifiable, Equatable, Codable {
    var id = UUID()
    let translation: String
    let transliteration: String?
    let frequency: Int?
    let partOfSpeech: String?
    let examples: [Example]
}

struct Example: Identifiable, Equatable, Codable {
    var id = UUID()
    let source: String
    let target: String
}
